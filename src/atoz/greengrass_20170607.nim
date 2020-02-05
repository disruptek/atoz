
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRoleToGroup_613250 = ref object of OpenApiRestCall_612642
proc url_AssociateRoleToGroup_613252(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateRoleToGroup_613251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613253 = path.getOrDefault("GroupId")
  valid_613253 = validateParameter(valid_613253, JString, required = true,
                                 default = nil)
  if valid_613253 != nil:
    section.add "GroupId", valid_613253
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
  var valid_613254 = header.getOrDefault("X-Amz-Signature")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Signature", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Content-Sha256", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Date")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Date", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Credential")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Credential", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Security-Token")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Security-Token", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Algorithm")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Algorithm", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-SignedHeaders", valid_613260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613262: Call_AssociateRoleToGroup_613250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_613262.validator(path, query, header, formData, body)
  let scheme = call_613262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613262.url(scheme.get, call_613262.host, call_613262.base,
                         call_613262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613262, url, valid)

proc call*(call_613263: Call_AssociateRoleToGroup_613250; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_613264 = newJObject()
  var body_613265 = newJObject()
  add(path_613264, "GroupId", newJString(GroupId))
  if body != nil:
    body_613265 = body
  result = call_613263.call(path_613264, nil, nil, nil, body_613265)

var associateRoleToGroup* = Call_AssociateRoleToGroup_613250(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_613251, base: "/",
    url: url_AssociateRoleToGroup_613252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_612980 = ref object of OpenApiRestCall_612642
proc url_GetAssociatedRole_612982(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAssociatedRole_612981(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves the role associated with a particular group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613108 = path.getOrDefault("GroupId")
  valid_613108 = validateParameter(valid_613108, JString, required = true,
                                 default = nil)
  if valid_613108 != nil:
    section.add "GroupId", valid_613108
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
  var valid_613109 = header.getOrDefault("X-Amz-Signature")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Signature", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Content-Sha256", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Date")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Date", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Credential")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Credential", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Security-Token")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Security-Token", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Algorithm")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Algorithm", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-SignedHeaders", valid_613115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613138: Call_GetAssociatedRole_612980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_613138.validator(path, query, header, formData, body)
  let scheme = call_613138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613138.url(scheme.get, call_613138.host, call_613138.base,
                         call_613138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613138, url, valid)

proc call*(call_613209: Call_GetAssociatedRole_612980; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_613210 = newJObject()
  add(path_613210, "GroupId", newJString(GroupId))
  result = call_613209.call(path_613210, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_612980(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_612981, base: "/",
    url: url_GetAssociatedRole_612982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_613266 = ref object of OpenApiRestCall_612642
proc url_DisassociateRoleFromGroup_613268(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateRoleFromGroup_613267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the role from a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613269 = path.getOrDefault("GroupId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "GroupId", valid_613269
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
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_DisassociateRoleFromGroup_613266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_DisassociateRoleFromGroup_613266; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_613279 = newJObject()
  add(path_613279, "GroupId", newJString(GroupId))
  result = call_613278.call(path_613279, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_613266(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_613267, base: "/",
    url: url_DisassociateRoleFromGroup_613268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_613292 = ref object of OpenApiRestCall_612642
proc url_AssociateServiceRoleToAccount_613294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceRoleToAccount_613293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
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
  var valid_613295 = header.getOrDefault("X-Amz-Signature")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Signature", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Content-Sha256", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Date")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Date", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Credential")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Credential", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Security-Token")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Security-Token", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Algorithm")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Algorithm", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-SignedHeaders", valid_613301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613303: Call_AssociateServiceRoleToAccount_613292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_613303.validator(path, query, header, formData, body)
  let scheme = call_613303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613303.url(scheme.get, call_613303.host, call_613303.base,
                         call_613303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613303, url, valid)

proc call*(call_613304: Call_AssociateServiceRoleToAccount_613292; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_613305 = newJObject()
  if body != nil:
    body_613305 = body
  result = call_613304.call(nil, nil, nil, nil, body_613305)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_613292(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_613293, base: "/",
    url: url_AssociateServiceRoleToAccount_613294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_613280 = ref object of OpenApiRestCall_612642
proc url_GetServiceRoleForAccount_613282(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceRoleForAccount_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the service role that is attached to your account.
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
  var valid_613283 = header.getOrDefault("X-Amz-Signature")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Signature", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Content-Sha256", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Date")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Date", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Credential")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Credential", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Security-Token")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Security-Token", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Algorithm")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Algorithm", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-SignedHeaders", valid_613289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613290: Call_GetServiceRoleForAccount_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_613290.validator(path, query, header, formData, body)
  let scheme = call_613290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613290.url(scheme.get, call_613290.host, call_613290.base,
                         call_613290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613290, url, valid)

proc call*(call_613291: Call_GetServiceRoleForAccount_613280): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_613291.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_613280(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_613281, base: "/",
    url: url_GetServiceRoleForAccount_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_613306 = ref object of OpenApiRestCall_612642
proc url_DisassociateServiceRoleFromAccount_613308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_613307(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
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
  var valid_613309 = header.getOrDefault("X-Amz-Signature")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Signature", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Content-Sha256", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Date")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Date", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Credential")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Credential", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Security-Token")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Security-Token", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Algorithm")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Algorithm", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-SignedHeaders", valid_613315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613316: Call_DisassociateServiceRoleFromAccount_613306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_613316.validator(path, query, header, formData, body)
  let scheme = call_613316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613316.url(scheme.get, call_613316.host, call_613316.base,
                         call_613316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613316, url, valid)

proc call*(call_613317: Call_DisassociateServiceRoleFromAccount_613306): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_613317.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_613306(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_613307, base: "/",
    url: url_DisassociateServiceRoleFromAccount_613308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_613333 = ref object of OpenApiRestCall_612642
proc url_CreateConnectorDefinition_613335(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnectorDefinition_613334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613336 = header.getOrDefault("X-Amz-Signature")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Signature", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Content-Sha256", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Date")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Date", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Credential")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Credential", valid_613339
  var valid_613340 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amzn-Client-Token", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613345: Call_CreateConnectorDefinition_613333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_613345.validator(path, query, header, formData, body)
  let scheme = call_613345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613345.url(scheme.get, call_613345.host, call_613345.base,
                         call_613345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613345, url, valid)

proc call*(call_613346: Call_CreateConnectorDefinition_613333; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_613347 = newJObject()
  if body != nil:
    body_613347 = body
  result = call_613346.call(nil, nil, nil, nil, body_613347)

var createConnectorDefinition* = Call_CreateConnectorDefinition_613333(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_613334, base: "/",
    url: url_CreateConnectorDefinition_613335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_613318 = ref object of OpenApiRestCall_612642
proc url_ListConnectorDefinitions_613320(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnectorDefinitions_613319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of connector definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613321 = query.getOrDefault("MaxResults")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "MaxResults", valid_613321
  var valid_613322 = query.getOrDefault("NextToken")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "NextToken", valid_613322
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
  var valid_613323 = header.getOrDefault("X-Amz-Signature")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Signature", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Content-Sha256", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Date")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Date", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Credential")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Credential", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Security-Token")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Security-Token", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Algorithm")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Algorithm", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-SignedHeaders", valid_613329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_ListConnectorDefinitions_613318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_ListConnectorDefinitions_613318;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613332 = newJObject()
  add(query_613332, "MaxResults", newJString(MaxResults))
  add(query_613332, "NextToken", newJString(NextToken))
  result = call_613331.call(nil, query_613332, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_613318(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_613319, base: "/",
    url: url_ListConnectorDefinitions_613320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_613365 = ref object of OpenApiRestCall_612642
proc url_CreateConnectorDefinitionVersion_613367(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConnectorDefinitionVersion_613366(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_613368 = path.getOrDefault("ConnectorDefinitionId")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = nil)
  if valid_613368 != nil:
    section.add "ConnectorDefinitionId", valid_613368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613369 = header.getOrDefault("X-Amz-Signature")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Signature", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Content-Sha256", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Date")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Date", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Credential")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Credential", valid_613372
  var valid_613373 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amzn-Client-Token", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613378: Call_CreateConnectorDefinitionVersion_613365;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_613378.validator(path, query, header, formData, body)
  let scheme = call_613378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613378.url(scheme.get, call_613378.host, call_613378.base,
                         call_613378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613378, url, valid)

proc call*(call_613379: Call_CreateConnectorDefinitionVersion_613365;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_613380 = newJObject()
  var body_613381 = newJObject()
  add(path_613380, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_613381 = body
  result = call_613379.call(path_613380, nil, nil, nil, body_613381)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_613365(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_613366, base: "/",
    url: url_CreateConnectorDefinitionVersion_613367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_613348 = ref object of OpenApiRestCall_612642
proc url_ListConnectorDefinitionVersions_613350(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConnectorDefinitionVersions_613349(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_613351 = path.getOrDefault("ConnectorDefinitionId")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "ConnectorDefinitionId", valid_613351
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613352 = query.getOrDefault("MaxResults")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "MaxResults", valid_613352
  var valid_613353 = query.getOrDefault("NextToken")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "NextToken", valid_613353
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
  var valid_613354 = header.getOrDefault("X-Amz-Signature")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Signature", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Content-Sha256", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Date")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Date", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Credential")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Credential", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Security-Token")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Security-Token", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Algorithm")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Algorithm", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-SignedHeaders", valid_613360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613361: Call_ListConnectorDefinitionVersions_613348;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_613361.validator(path, query, header, formData, body)
  let scheme = call_613361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613361.url(scheme.get, call_613361.host, call_613361.base,
                         call_613361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613361, url, valid)

proc call*(call_613362: Call_ListConnectorDefinitionVersions_613348;
          ConnectorDefinitionId: string; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listConnectorDefinitionVersions
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_613363 = newJObject()
  var query_613364 = newJObject()
  add(query_613364, "MaxResults", newJString(MaxResults))
  add(query_613364, "NextToken", newJString(NextToken))
  add(path_613363, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_613362.call(path_613363, query_613364, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_613348(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_613349, base: "/",
    url: url_ListConnectorDefinitionVersions_613350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_613397 = ref object of OpenApiRestCall_612642
proc url_CreateCoreDefinition_613399(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCoreDefinition_613398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613400 = header.getOrDefault("X-Amz-Signature")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Signature", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Content-Sha256", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Date")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Date", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Credential")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Credential", valid_613403
  var valid_613404 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amzn-Client-Token", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Security-Token")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Security-Token", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Algorithm")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Algorithm", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-SignedHeaders", valid_613407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613409: Call_CreateCoreDefinition_613397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_613409.validator(path, query, header, formData, body)
  let scheme = call_613409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613409.url(scheme.get, call_613409.host, call_613409.base,
                         call_613409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613409, url, valid)

proc call*(call_613410: Call_CreateCoreDefinition_613397; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_613411 = newJObject()
  if body != nil:
    body_613411 = body
  result = call_613410.call(nil, nil, nil, nil, body_613411)

var createCoreDefinition* = Call_CreateCoreDefinition_613397(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_613398, base: "/",
    url: url_CreateCoreDefinition_613399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_613382 = ref object of OpenApiRestCall_612642
proc url_ListCoreDefinitions_613384(protocol: Scheme; host: string; base: string;
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

proc validate_ListCoreDefinitions_613383(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves a list of core definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613385 = query.getOrDefault("MaxResults")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "MaxResults", valid_613385
  var valid_613386 = query.getOrDefault("NextToken")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "NextToken", valid_613386
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613394: Call_ListCoreDefinitions_613382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_613394.validator(path, query, header, formData, body)
  let scheme = call_613394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613394.url(scheme.get, call_613394.host, call_613394.base,
                         call_613394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613394, url, valid)

proc call*(call_613395: Call_ListCoreDefinitions_613382; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613396 = newJObject()
  add(query_613396, "MaxResults", newJString(MaxResults))
  add(query_613396, "NextToken", newJString(NextToken))
  result = call_613395.call(nil, query_613396, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_613382(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_613383, base: "/",
    url: url_ListCoreDefinitions_613384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_613429 = ref object of OpenApiRestCall_612642
proc url_CreateCoreDefinitionVersion_613431(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCoreDefinitionVersion_613430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613432 = path.getOrDefault("CoreDefinitionId")
  valid_613432 = validateParameter(valid_613432, JString, required = true,
                                 default = nil)
  if valid_613432 != nil:
    section.add "CoreDefinitionId", valid_613432
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amzn-Client-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateCoreDefinitionVersion_613429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateCoreDefinitionVersion_613429;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_613444 = newJObject()
  var body_613445 = newJObject()
  add(path_613444, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_613445 = body
  result = call_613443.call(path_613444, nil, nil, nil, body_613445)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_613429(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_613430, base: "/",
    url: url_CreateCoreDefinitionVersion_613431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_613412 = ref object of OpenApiRestCall_612642
proc url_ListCoreDefinitionVersions_613414(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListCoreDefinitionVersions_613413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613415 = path.getOrDefault("CoreDefinitionId")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "CoreDefinitionId", valid_613415
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613416 = query.getOrDefault("MaxResults")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "MaxResults", valid_613416
  var valid_613417 = query.getOrDefault("NextToken")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "NextToken", valid_613417
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
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613425: Call_ListCoreDefinitionVersions_613412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_613425.validator(path, query, header, formData, body)
  let scheme = call_613425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613425.url(scheme.get, call_613425.host, call_613425.base,
                         call_613425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613425, url, valid)

proc call*(call_613426: Call_ListCoreDefinitionVersions_613412;
          CoreDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_613427 = newJObject()
  var query_613428 = newJObject()
  add(query_613428, "MaxResults", newJString(MaxResults))
  add(query_613428, "NextToken", newJString(NextToken))
  add(path_613427, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_613426.call(path_613427, query_613428, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_613412(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_613413, base: "/",
    url: url_ListCoreDefinitionVersions_613414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_613463 = ref object of OpenApiRestCall_612642
proc url_CreateDeployment_613465(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_613464(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613466 = path.getOrDefault("GroupId")
  valid_613466 = validateParameter(valid_613466, JString, required = true,
                                 default = nil)
  if valid_613466 != nil:
    section.add "GroupId", valid_613466
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613467 = header.getOrDefault("X-Amz-Signature")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Signature", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Content-Sha256", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Date")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Date", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Credential")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Credential", valid_613470
  var valid_613471 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amzn-Client-Token", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Security-Token")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Security-Token", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Algorithm")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Algorithm", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-SignedHeaders", valid_613474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_CreateDeployment_613463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_CreateDeployment_613463; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_613478 = newJObject()
  var body_613479 = newJObject()
  add(path_613478, "GroupId", newJString(GroupId))
  if body != nil:
    body_613479 = body
  result = call_613477.call(path_613478, nil, nil, nil, body_613479)

var createDeployment* = Call_CreateDeployment_613463(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_613464, base: "/",
    url: url_CreateDeployment_613465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_613446 = ref object of OpenApiRestCall_612642
proc url_ListDeployments_613448(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeployments_613447(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a history of deployments for the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613449 = path.getOrDefault("GroupId")
  valid_613449 = validateParameter(valid_613449, JString, required = true,
                                 default = nil)
  if valid_613449 != nil:
    section.add "GroupId", valid_613449
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613450 = query.getOrDefault("MaxResults")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "MaxResults", valid_613450
  var valid_613451 = query.getOrDefault("NextToken")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "NextToken", valid_613451
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
  var valid_613452 = header.getOrDefault("X-Amz-Signature")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Signature", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Content-Sha256", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Date")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Date", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Credential")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Credential", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Security-Token")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Security-Token", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Algorithm")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Algorithm", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-SignedHeaders", valid_613458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613459: Call_ListDeployments_613446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_613459.validator(path, query, header, formData, body)
  let scheme = call_613459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613459.url(scheme.get, call_613459.host, call_613459.base,
                         call_613459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613459, url, valid)

proc call*(call_613460: Call_ListDeployments_613446; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_613461 = newJObject()
  var query_613462 = newJObject()
  add(path_613461, "GroupId", newJString(GroupId))
  add(query_613462, "MaxResults", newJString(MaxResults))
  add(query_613462, "NextToken", newJString(NextToken))
  result = call_613460.call(path_613461, query_613462, nil, nil, nil)

var listDeployments* = Call_ListDeployments_613446(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_613447, base: "/", url: url_ListDeployments_613448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_613495 = ref object of OpenApiRestCall_612642
proc url_CreateDeviceDefinition_613497(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeviceDefinition_613496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613498 = header.getOrDefault("X-Amz-Signature")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Signature", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Content-Sha256", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Date")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Date", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Credential")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Credential", valid_613501
  var valid_613502 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amzn-Client-Token", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Security-Token")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Security-Token", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Algorithm")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Algorithm", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-SignedHeaders", valid_613505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613507: Call_CreateDeviceDefinition_613495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_613507.validator(path, query, header, formData, body)
  let scheme = call_613507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613507.url(scheme.get, call_613507.host, call_613507.base,
                         call_613507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613507, url, valid)

proc call*(call_613508: Call_CreateDeviceDefinition_613495; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_613509 = newJObject()
  if body != nil:
    body_613509 = body
  result = call_613508.call(nil, nil, nil, nil, body_613509)

var createDeviceDefinition* = Call_CreateDeviceDefinition_613495(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_613496, base: "/",
    url: url_CreateDeviceDefinition_613497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_613480 = ref object of OpenApiRestCall_612642
proc url_ListDeviceDefinitions_613482(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceDefinitions_613481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of device definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613483 = query.getOrDefault("MaxResults")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "MaxResults", valid_613483
  var valid_613484 = query.getOrDefault("NextToken")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "NextToken", valid_613484
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
  var valid_613485 = header.getOrDefault("X-Amz-Signature")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Signature", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Content-Sha256", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Date")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Date", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Credential")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Credential", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Security-Token")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Security-Token", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Algorithm")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Algorithm", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-SignedHeaders", valid_613491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613492: Call_ListDeviceDefinitions_613480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_613492.validator(path, query, header, formData, body)
  let scheme = call_613492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613492.url(scheme.get, call_613492.host, call_613492.base,
                         call_613492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613492, url, valid)

proc call*(call_613493: Call_ListDeviceDefinitions_613480; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613494 = newJObject()
  add(query_613494, "MaxResults", newJString(MaxResults))
  add(query_613494, "NextToken", newJString(NextToken))
  result = call_613493.call(nil, query_613494, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_613480(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_613481, base: "/",
    url: url_ListDeviceDefinitions_613482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_613527 = ref object of OpenApiRestCall_612642
proc url_CreateDeviceDefinitionVersion_613529(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeviceDefinitionVersion_613528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613530 = path.getOrDefault("DeviceDefinitionId")
  valid_613530 = validateParameter(valid_613530, JString, required = true,
                                 default = nil)
  if valid_613530 != nil:
    section.add "DeviceDefinitionId", valid_613530
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613531 = header.getOrDefault("X-Amz-Signature")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Signature", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Content-Sha256", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Date")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Date", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Credential")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Credential", valid_613534
  var valid_613535 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amzn-Client-Token", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Security-Token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Security-Token", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Algorithm")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Algorithm", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-SignedHeaders", valid_613538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613540: Call_CreateDeviceDefinitionVersion_613527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_613540.validator(path, query, header, formData, body)
  let scheme = call_613540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613540.url(scheme.get, call_613540.host, call_613540.base,
                         call_613540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613540, url, valid)

proc call*(call_613541: Call_CreateDeviceDefinitionVersion_613527;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_613542 = newJObject()
  var body_613543 = newJObject()
  add(path_613542, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_613543 = body
  result = call_613541.call(path_613542, nil, nil, nil, body_613543)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_613527(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_613528, base: "/",
    url: url_CreateDeviceDefinitionVersion_613529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_613510 = ref object of OpenApiRestCall_612642
proc url_ListDeviceDefinitionVersions_613512(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeviceDefinitionVersions_613511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613513 = path.getOrDefault("DeviceDefinitionId")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = nil)
  if valid_613513 != nil:
    section.add "DeviceDefinitionId", valid_613513
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613514 = query.getOrDefault("MaxResults")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "MaxResults", valid_613514
  var valid_613515 = query.getOrDefault("NextToken")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "NextToken", valid_613515
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
  var valid_613516 = header.getOrDefault("X-Amz-Signature")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Signature", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Content-Sha256", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Date")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Date", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Credential")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Credential", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Security-Token")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Security-Token", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Algorithm")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Algorithm", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-SignedHeaders", valid_613522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613523: Call_ListDeviceDefinitionVersions_613510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_613523.validator(path, query, header, formData, body)
  let scheme = call_613523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613523.url(scheme.get, call_613523.host, call_613523.base,
                         call_613523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613523, url, valid)

proc call*(call_613524: Call_ListDeviceDefinitionVersions_613510;
          DeviceDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_613525 = newJObject()
  var query_613526 = newJObject()
  add(path_613525, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_613526, "MaxResults", newJString(MaxResults))
  add(query_613526, "NextToken", newJString(NextToken))
  result = call_613524.call(path_613525, query_613526, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_613510(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_613511, base: "/",
    url: url_ListDeviceDefinitionVersions_613512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_613559 = ref object of OpenApiRestCall_612642
proc url_CreateFunctionDefinition_613561(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunctionDefinition_613560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613562 = header.getOrDefault("X-Amz-Signature")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Signature", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Content-Sha256", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Date")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Date", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Credential")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Credential", valid_613565
  var valid_613566 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amzn-Client-Token", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Security-Token")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Security-Token", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Algorithm")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Algorithm", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-SignedHeaders", valid_613569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613571: Call_CreateFunctionDefinition_613559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_613571.validator(path, query, header, formData, body)
  let scheme = call_613571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613571.url(scheme.get, call_613571.host, call_613571.base,
                         call_613571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613571, url, valid)

proc call*(call_613572: Call_CreateFunctionDefinition_613559; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_613573 = newJObject()
  if body != nil:
    body_613573 = body
  result = call_613572.call(nil, nil, nil, nil, body_613573)

var createFunctionDefinition* = Call_CreateFunctionDefinition_613559(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_613560, base: "/",
    url: url_CreateFunctionDefinition_613561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_613544 = ref object of OpenApiRestCall_612642
proc url_ListFunctionDefinitions_613546(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctionDefinitions_613545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of Lambda function definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613547 = query.getOrDefault("MaxResults")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "MaxResults", valid_613547
  var valid_613548 = query.getOrDefault("NextToken")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "NextToken", valid_613548
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
  var valid_613549 = header.getOrDefault("X-Amz-Signature")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Signature", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Content-Sha256", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Date")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Date", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Credential")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Credential", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Security-Token")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Security-Token", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Algorithm")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Algorithm", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-SignedHeaders", valid_613555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613556: Call_ListFunctionDefinitions_613544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_613556.validator(path, query, header, formData, body)
  let scheme = call_613556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613556.url(scheme.get, call_613556.host, call_613556.base,
                         call_613556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613556, url, valid)

proc call*(call_613557: Call_ListFunctionDefinitions_613544;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613558 = newJObject()
  add(query_613558, "MaxResults", newJString(MaxResults))
  add(query_613558, "NextToken", newJString(NextToken))
  result = call_613557.call(nil, query_613558, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_613544(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_613545, base: "/",
    url: url_ListFunctionDefinitions_613546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_613591 = ref object of OpenApiRestCall_612642
proc url_CreateFunctionDefinitionVersion_613593(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunctionDefinitionVersion_613592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_613594 = path.getOrDefault("FunctionDefinitionId")
  valid_613594 = validateParameter(valid_613594, JString, required = true,
                                 default = nil)
  if valid_613594 != nil:
    section.add "FunctionDefinitionId", valid_613594
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613595 = header.getOrDefault("X-Amz-Signature")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Signature", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Content-Sha256", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Date")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Date", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Credential")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Credential", valid_613598
  var valid_613599 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amzn-Client-Token", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Security-Token")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Security-Token", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Algorithm")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Algorithm", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-SignedHeaders", valid_613602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613604: Call_CreateFunctionDefinitionVersion_613591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_613604.validator(path, query, header, formData, body)
  let scheme = call_613604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613604.url(scheme.get, call_613604.host, call_613604.base,
                         call_613604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613604, url, valid)

proc call*(call_613605: Call_CreateFunctionDefinitionVersion_613591;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_613606 = newJObject()
  var body_613607 = newJObject()
  add(path_613606, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_613607 = body
  result = call_613605.call(path_613606, nil, nil, nil, body_613607)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_613591(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_613592, base: "/",
    url: url_CreateFunctionDefinitionVersion_613593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_613574 = ref object of OpenApiRestCall_612642
proc url_ListFunctionDefinitionVersions_613576(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionDefinitionVersions_613575(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the versions of a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_613577 = path.getOrDefault("FunctionDefinitionId")
  valid_613577 = validateParameter(valid_613577, JString, required = true,
                                 default = nil)
  if valid_613577 != nil:
    section.add "FunctionDefinitionId", valid_613577
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613578 = query.getOrDefault("MaxResults")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "MaxResults", valid_613578
  var valid_613579 = query.getOrDefault("NextToken")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "NextToken", valid_613579
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
  var valid_613580 = header.getOrDefault("X-Amz-Signature")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Signature", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Content-Sha256", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Date")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Date", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Credential")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Credential", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Security-Token")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Security-Token", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Algorithm")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Algorithm", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-SignedHeaders", valid_613586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613587: Call_ListFunctionDefinitionVersions_613574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_613587.validator(path, query, header, formData, body)
  let scheme = call_613587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613587.url(scheme.get, call_613587.host, call_613587.base,
                         call_613587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613587, url, valid)

proc call*(call_613588: Call_ListFunctionDefinitionVersions_613574;
          FunctionDefinitionId: string; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listFunctionDefinitionVersions
  ## Lists the versions of a Lambda function definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_613589 = newJObject()
  var query_613590 = newJObject()
  add(query_613590, "MaxResults", newJString(MaxResults))
  add(query_613590, "NextToken", newJString(NextToken))
  add(path_613589, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_613588.call(path_613589, query_613590, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_613574(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_613575, base: "/",
    url: url_ListFunctionDefinitionVersions_613576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_613623 = ref object of OpenApiRestCall_612642
proc url_CreateGroup_613625(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_613624(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613626 = header.getOrDefault("X-Amz-Signature")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Signature", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Content-Sha256", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Date")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Date", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Credential")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Credential", valid_613629
  var valid_613630 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amzn-Client-Token", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Security-Token")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Security-Token", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Algorithm")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Algorithm", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-SignedHeaders", valid_613633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613635: Call_CreateGroup_613623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_613635.validator(path, query, header, formData, body)
  let scheme = call_613635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613635.url(scheme.get, call_613635.host, call_613635.base,
                         call_613635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613635, url, valid)

proc call*(call_613636: Call_CreateGroup_613623; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_613637 = newJObject()
  if body != nil:
    body_613637 = body
  result = call_613636.call(nil, nil, nil, nil, body_613637)

var createGroup* = Call_CreateGroup_613623(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_613624,
                                        base: "/", url: url_CreateGroup_613625,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_613608 = ref object of OpenApiRestCall_612642
proc url_ListGroups_613610(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_613609(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613611 = query.getOrDefault("MaxResults")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "MaxResults", valid_613611
  var valid_613612 = query.getOrDefault("NextToken")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "NextToken", valid_613612
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
  var valid_613613 = header.getOrDefault("X-Amz-Signature")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Signature", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Content-Sha256", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Date")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Date", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Credential")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Credential", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Security-Token")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Security-Token", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Algorithm")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Algorithm", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-SignedHeaders", valid_613619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613620: Call_ListGroups_613608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_613620.validator(path, query, header, formData, body)
  let scheme = call_613620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613620.url(scheme.get, call_613620.host, call_613620.base,
                         call_613620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613620, url, valid)

proc call*(call_613621: Call_ListGroups_613608; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613622 = newJObject()
  add(query_613622, "MaxResults", newJString(MaxResults))
  add(query_613622, "NextToken", newJString(NextToken))
  result = call_613621.call(nil, query_613622, nil, nil, nil)

var listGroups* = Call_ListGroups_613608(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_613609,
                                      base: "/", url: url_ListGroups_613610,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_613652 = ref object of OpenApiRestCall_612642
proc url_CreateGroupCertificateAuthority_613654(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupCertificateAuthority_613653(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613655 = path.getOrDefault("GroupId")
  valid_613655 = validateParameter(valid_613655, JString, required = true,
                                 default = nil)
  if valid_613655 != nil:
    section.add "GroupId", valid_613655
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613656 = header.getOrDefault("X-Amz-Signature")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Signature", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Content-Sha256", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Date")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Date", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Credential")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Credential", valid_613659
  var valid_613660 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amzn-Client-Token", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Security-Token")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Security-Token", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Algorithm")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Algorithm", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-SignedHeaders", valid_613663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613664: Call_CreateGroupCertificateAuthority_613652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_613664.validator(path, query, header, formData, body)
  let scheme = call_613664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613664.url(scheme.get, call_613664.host, call_613664.base,
                         call_613664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613664, url, valid)

proc call*(call_613665: Call_CreateGroupCertificateAuthority_613652;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_613666 = newJObject()
  add(path_613666, "GroupId", newJString(GroupId))
  result = call_613665.call(path_613666, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_613652(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_613653, base: "/",
    url: url_CreateGroupCertificateAuthority_613654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_613638 = ref object of OpenApiRestCall_612642
proc url_ListGroupCertificateAuthorities_613640(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupCertificateAuthorities_613639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current CAs for a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613641 = path.getOrDefault("GroupId")
  valid_613641 = validateParameter(valid_613641, JString, required = true,
                                 default = nil)
  if valid_613641 != nil:
    section.add "GroupId", valid_613641
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
  var valid_613642 = header.getOrDefault("X-Amz-Signature")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Signature", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Content-Sha256", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Date")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Date", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Credential")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Credential", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Security-Token")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Security-Token", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Algorithm")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Algorithm", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-SignedHeaders", valid_613648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613649: Call_ListGroupCertificateAuthorities_613638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_613649.validator(path, query, header, formData, body)
  let scheme = call_613649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613649.url(scheme.get, call_613649.host, call_613649.base,
                         call_613649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613649, url, valid)

proc call*(call_613650: Call_ListGroupCertificateAuthorities_613638;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_613651 = newJObject()
  add(path_613651, "GroupId", newJString(GroupId))
  result = call_613650.call(path_613651, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_613638(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_613639, base: "/",
    url: url_ListGroupCertificateAuthorities_613640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_613684 = ref object of OpenApiRestCall_612642
proc url_CreateGroupVersion_613686(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupVersion_613685(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a version of a group which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613687 = path.getOrDefault("GroupId")
  valid_613687 = validateParameter(valid_613687, JString, required = true,
                                 default = nil)
  if valid_613687 != nil:
    section.add "GroupId", valid_613687
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613688 = header.getOrDefault("X-Amz-Signature")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Signature", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Content-Sha256", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Date")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Date", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Credential")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Credential", valid_613691
  var valid_613692 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amzn-Client-Token", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_CreateGroupVersion_613684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_CreateGroupVersion_613684; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_613699 = newJObject()
  var body_613700 = newJObject()
  add(path_613699, "GroupId", newJString(GroupId))
  if body != nil:
    body_613700 = body
  result = call_613698.call(path_613699, nil, nil, nil, body_613700)

var createGroupVersion* = Call_CreateGroupVersion_613684(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_613685, base: "/",
    url: url_CreateGroupVersion_613686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_613667 = ref object of OpenApiRestCall_612642
proc url_ListGroupVersions_613669(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupVersions_613668(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the versions of a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_613670 = path.getOrDefault("GroupId")
  valid_613670 = validateParameter(valid_613670, JString, required = true,
                                 default = nil)
  if valid_613670 != nil:
    section.add "GroupId", valid_613670
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613671 = query.getOrDefault("MaxResults")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "MaxResults", valid_613671
  var valid_613672 = query.getOrDefault("NextToken")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "NextToken", valid_613672
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
  var valid_613673 = header.getOrDefault("X-Amz-Signature")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Signature", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Content-Sha256", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Date")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Date", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Credential")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Credential", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Security-Token")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Security-Token", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Algorithm")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Algorithm", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-SignedHeaders", valid_613679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613680: Call_ListGroupVersions_613667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_613680.validator(path, query, header, formData, body)
  let scheme = call_613680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613680.url(scheme.get, call_613680.host, call_613680.base,
                         call_613680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613680, url, valid)

proc call*(call_613681: Call_ListGroupVersions_613667; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_613682 = newJObject()
  var query_613683 = newJObject()
  add(path_613682, "GroupId", newJString(GroupId))
  add(query_613683, "MaxResults", newJString(MaxResults))
  add(query_613683, "NextToken", newJString(NextToken))
  result = call_613681.call(path_613682, query_613683, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_613667(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_613668, base: "/",
    url: url_ListGroupVersions_613669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_613716 = ref object of OpenApiRestCall_612642
proc url_CreateLoggerDefinition_613718(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLoggerDefinition_613717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amzn-Client-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Security-Token")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Security-Token", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Algorithm")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Algorithm", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-SignedHeaders", valid_613726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613728: Call_CreateLoggerDefinition_613716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_613728.validator(path, query, header, formData, body)
  let scheme = call_613728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613728.url(scheme.get, call_613728.host, call_613728.base,
                         call_613728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613728, url, valid)

proc call*(call_613729: Call_CreateLoggerDefinition_613716; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_613730 = newJObject()
  if body != nil:
    body_613730 = body
  result = call_613729.call(nil, nil, nil, nil, body_613730)

var createLoggerDefinition* = Call_CreateLoggerDefinition_613716(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_613717, base: "/",
    url: url_CreateLoggerDefinition_613718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_613701 = ref object of OpenApiRestCall_612642
proc url_ListLoggerDefinitions_613703(protocol: Scheme; host: string; base: string;
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

proc validate_ListLoggerDefinitions_613702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of logger definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613704 = query.getOrDefault("MaxResults")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "MaxResults", valid_613704
  var valid_613705 = query.getOrDefault("NextToken")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "NextToken", valid_613705
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
  var valid_613706 = header.getOrDefault("X-Amz-Signature")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Signature", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Content-Sha256", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Date")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Date", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Credential")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Credential", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613713: Call_ListLoggerDefinitions_613701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_613713.validator(path, query, header, formData, body)
  let scheme = call_613713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613713.url(scheme.get, call_613713.host, call_613713.base,
                         call_613713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613713, url, valid)

proc call*(call_613714: Call_ListLoggerDefinitions_613701; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613715 = newJObject()
  add(query_613715, "MaxResults", newJString(MaxResults))
  add(query_613715, "NextToken", newJString(NextToken))
  result = call_613714.call(nil, query_613715, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_613701(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_613702, base: "/",
    url: url_ListLoggerDefinitions_613703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_613748 = ref object of OpenApiRestCall_612642
proc url_CreateLoggerDefinitionVersion_613750(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLoggerDefinitionVersion_613749(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613751 = path.getOrDefault("LoggerDefinitionId")
  valid_613751 = validateParameter(valid_613751, JString, required = true,
                                 default = nil)
  if valid_613751 != nil:
    section.add "LoggerDefinitionId", valid_613751
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613752 = header.getOrDefault("X-Amz-Signature")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Signature", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Content-Sha256", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Date")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Date", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Credential")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Credential", valid_613755
  var valid_613756 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amzn-Client-Token", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Security-Token")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Security-Token", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Algorithm")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Algorithm", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-SignedHeaders", valid_613759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613761: Call_CreateLoggerDefinitionVersion_613748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_613761.validator(path, query, header, formData, body)
  let scheme = call_613761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613761.url(scheme.get, call_613761.host, call_613761.base,
                         call_613761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613761, url, valid)

proc call*(call_613762: Call_CreateLoggerDefinitionVersion_613748;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_613763 = newJObject()
  var body_613764 = newJObject()
  add(path_613763, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_613764 = body
  result = call_613762.call(path_613763, nil, nil, nil, body_613764)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_613748(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_613749, base: "/",
    url: url_CreateLoggerDefinitionVersion_613750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_613731 = ref object of OpenApiRestCall_612642
proc url_ListLoggerDefinitionVersions_613733(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLoggerDefinitionVersions_613732(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613734 = path.getOrDefault("LoggerDefinitionId")
  valid_613734 = validateParameter(valid_613734, JString, required = true,
                                 default = nil)
  if valid_613734 != nil:
    section.add "LoggerDefinitionId", valid_613734
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613735 = query.getOrDefault("MaxResults")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "MaxResults", valid_613735
  var valid_613736 = query.getOrDefault("NextToken")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "NextToken", valid_613736
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
  var valid_613737 = header.getOrDefault("X-Amz-Signature")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Signature", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Content-Sha256", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Date")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Date", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Credential")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Credential", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Security-Token")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Security-Token", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Algorithm")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Algorithm", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-SignedHeaders", valid_613743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613744: Call_ListLoggerDefinitionVersions_613731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_613744.validator(path, query, header, formData, body)
  let scheme = call_613744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613744.url(scheme.get, call_613744.host, call_613744.base,
                         call_613744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613744, url, valid)

proc call*(call_613745: Call_ListLoggerDefinitionVersions_613731;
          LoggerDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_613746 = newJObject()
  var query_613747 = newJObject()
  add(query_613747, "MaxResults", newJString(MaxResults))
  add(query_613747, "NextToken", newJString(NextToken))
  add(path_613746, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_613745.call(path_613746, query_613747, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_613731(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_613732, base: "/",
    url: url_ListLoggerDefinitionVersions_613733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_613780 = ref object of OpenApiRestCall_612642
proc url_CreateResourceDefinition_613782(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDefinition_613781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613783 = header.getOrDefault("X-Amz-Signature")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Signature", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Content-Sha256", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Date")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Date", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Credential")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Credential", valid_613786
  var valid_613787 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amzn-Client-Token", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Security-Token")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Security-Token", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Algorithm")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Algorithm", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-SignedHeaders", valid_613790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613792: Call_CreateResourceDefinition_613780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_613792.validator(path, query, header, formData, body)
  let scheme = call_613792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613792.url(scheme.get, call_613792.host, call_613792.base,
                         call_613792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613792, url, valid)

proc call*(call_613793: Call_CreateResourceDefinition_613780; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_613794 = newJObject()
  if body != nil:
    body_613794 = body
  result = call_613793.call(nil, nil, nil, nil, body_613794)

var createResourceDefinition* = Call_CreateResourceDefinition_613780(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_613781, base: "/",
    url: url_CreateResourceDefinition_613782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_613765 = ref object of OpenApiRestCall_612642
proc url_ListResourceDefinitions_613767(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDefinitions_613766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of resource definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613768 = query.getOrDefault("MaxResults")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "MaxResults", valid_613768
  var valid_613769 = query.getOrDefault("NextToken")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "NextToken", valid_613769
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
  var valid_613770 = header.getOrDefault("X-Amz-Signature")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Signature", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Content-Sha256", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Date")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Date", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Credential")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Credential", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Security-Token")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Security-Token", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Algorithm")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Algorithm", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-SignedHeaders", valid_613776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613777: Call_ListResourceDefinitions_613765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_613777.validator(path, query, header, formData, body)
  let scheme = call_613777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613777.url(scheme.get, call_613777.host, call_613777.base,
                         call_613777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613777, url, valid)

proc call*(call_613778: Call_ListResourceDefinitions_613765;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613779 = newJObject()
  add(query_613779, "MaxResults", newJString(MaxResults))
  add(query_613779, "NextToken", newJString(NextToken))
  result = call_613778.call(nil, query_613779, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_613765(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_613766, base: "/",
    url: url_ListResourceDefinitions_613767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_613812 = ref object of OpenApiRestCall_612642
proc url_CreateResourceDefinitionVersion_613814(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResourceDefinitionVersion_613813(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_613815 = path.getOrDefault("ResourceDefinitionId")
  valid_613815 = validateParameter(valid_613815, JString, required = true,
                                 default = nil)
  if valid_613815 != nil:
    section.add "ResourceDefinitionId", valid_613815
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613816 = header.getOrDefault("X-Amz-Signature")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Signature", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Content-Sha256", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Date")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Date", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Credential")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Credential", valid_613819
  var valid_613820 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amzn-Client-Token", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Security-Token")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Security-Token", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Algorithm")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Algorithm", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-SignedHeaders", valid_613823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613825: Call_CreateResourceDefinitionVersion_613812;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_613825.validator(path, query, header, formData, body)
  let scheme = call_613825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613825.url(scheme.get, call_613825.host, call_613825.base,
                         call_613825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613825, url, valid)

proc call*(call_613826: Call_CreateResourceDefinitionVersion_613812;
          body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_613827 = newJObject()
  var body_613828 = newJObject()
  if body != nil:
    body_613828 = body
  add(path_613827, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_613826.call(path_613827, nil, nil, nil, body_613828)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_613812(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_613813, base: "/",
    url: url_CreateResourceDefinitionVersion_613814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_613795 = ref object of OpenApiRestCall_612642
proc url_ListResourceDefinitionVersions_613797(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceDefinitionVersions_613796(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the versions of a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_613798 = path.getOrDefault("ResourceDefinitionId")
  valid_613798 = validateParameter(valid_613798, JString, required = true,
                                 default = nil)
  if valid_613798 != nil:
    section.add "ResourceDefinitionId", valid_613798
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613799 = query.getOrDefault("MaxResults")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "MaxResults", valid_613799
  var valid_613800 = query.getOrDefault("NextToken")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "NextToken", valid_613800
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
  var valid_613801 = header.getOrDefault("X-Amz-Signature")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Signature", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Content-Sha256", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Date")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Date", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Credential")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Credential", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Security-Token")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Security-Token", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Algorithm")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Algorithm", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-SignedHeaders", valid_613807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613808: Call_ListResourceDefinitionVersions_613795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_613808.validator(path, query, header, formData, body)
  let scheme = call_613808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613808.url(scheme.get, call_613808.host, call_613808.base,
                         call_613808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613808, url, valid)

proc call*(call_613809: Call_ListResourceDefinitionVersions_613795;
          ResourceDefinitionId: string; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listResourceDefinitionVersions
  ## Lists the versions of a resource definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_613810 = newJObject()
  var query_613811 = newJObject()
  add(query_613811, "MaxResults", newJString(MaxResults))
  add(query_613811, "NextToken", newJString(NextToken))
  add(path_613810, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_613809.call(path_613810, query_613811, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_613795(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_613796, base: "/",
    url: url_ListResourceDefinitionVersions_613797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_613829 = ref object of OpenApiRestCall_612642
proc url_CreateSoftwareUpdateJob_613831(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSoftwareUpdateJob_613830(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613832 = header.getOrDefault("X-Amz-Signature")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Signature", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Content-Sha256", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Date")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Date", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Credential")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Credential", valid_613835
  var valid_613836 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amzn-Client-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Security-Token")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Security-Token", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Algorithm")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Algorithm", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-SignedHeaders", valid_613839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613841: Call_CreateSoftwareUpdateJob_613829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_613841.validator(path, query, header, formData, body)
  let scheme = call_613841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613841.url(scheme.get, call_613841.host, call_613841.base,
                         call_613841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613841, url, valid)

proc call*(call_613842: Call_CreateSoftwareUpdateJob_613829; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_613843 = newJObject()
  if body != nil:
    body_613843 = body
  result = call_613842.call(nil, nil, nil, nil, body_613843)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_613829(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_613830, base: "/",
    url: url_CreateSoftwareUpdateJob_613831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_613859 = ref object of OpenApiRestCall_612642
proc url_CreateSubscriptionDefinition_613861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubscriptionDefinition_613860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613862 = header.getOrDefault("X-Amz-Signature")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Signature", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Content-Sha256", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Date")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Date", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Credential")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Credential", valid_613865
  var valid_613866 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amzn-Client-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Security-Token")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Security-Token", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Algorithm")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Algorithm", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-SignedHeaders", valid_613869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_CreateSubscriptionDefinition_613859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_CreateSubscriptionDefinition_613859; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_613873 = newJObject()
  if body != nil:
    body_613873 = body
  result = call_613872.call(nil, nil, nil, nil, body_613873)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_613859(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_613860, base: "/",
    url: url_CreateSubscriptionDefinition_613861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_613844 = ref object of OpenApiRestCall_612642
proc url_ListSubscriptionDefinitions_613846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscriptionDefinitions_613845(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of subscription definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613847 = query.getOrDefault("MaxResults")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "MaxResults", valid_613847
  var valid_613848 = query.getOrDefault("NextToken")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "NextToken", valid_613848
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
  var valid_613849 = header.getOrDefault("X-Amz-Signature")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Signature", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Content-Sha256", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Date")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Date", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Credential")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Credential", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Security-Token")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Security-Token", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Algorithm")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Algorithm", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-SignedHeaders", valid_613855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613856: Call_ListSubscriptionDefinitions_613844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_613856.validator(path, query, header, formData, body)
  let scheme = call_613856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613856.url(scheme.get, call_613856.host, call_613856.base,
                         call_613856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613856, url, valid)

proc call*(call_613857: Call_ListSubscriptionDefinitions_613844;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_613858 = newJObject()
  add(query_613858, "MaxResults", newJString(MaxResults))
  add(query_613858, "NextToken", newJString(NextToken))
  result = call_613857.call(nil, query_613858, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_613844(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_613845, base: "/",
    url: url_ListSubscriptionDefinitions_613846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_613891 = ref object of OpenApiRestCall_612642
proc url_CreateSubscriptionDefinitionVersion_613893(protocol: Scheme; host: string;
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
               (kind: VariableSegment, value: "SubscriptionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSubscriptionDefinitionVersion_613892(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_613894 = path.getOrDefault("SubscriptionDefinitionId")
  valid_613894 = validateParameter(valid_613894, JString, required = true,
                                 default = nil)
  if valid_613894 != nil:
    section.add "SubscriptionDefinitionId", valid_613894
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613895 = header.getOrDefault("X-Amz-Signature")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Signature", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Content-Sha256", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Date")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Date", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Credential")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Credential", valid_613898
  var valid_613899 = header.getOrDefault("X-Amzn-Client-Token")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amzn-Client-Token", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Security-Token")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Security-Token", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Algorithm")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Algorithm", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-SignedHeaders", valid_613902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613904: Call_CreateSubscriptionDefinitionVersion_613891;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_613904.validator(path, query, header, formData, body)
  let scheme = call_613904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613904.url(scheme.get, call_613904.host, call_613904.base,
                         call_613904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613904, url, valid)

proc call*(call_613905: Call_CreateSubscriptionDefinitionVersion_613891;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_613906 = newJObject()
  var body_613907 = newJObject()
  add(path_613906, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_613907 = body
  result = call_613905.call(path_613906, nil, nil, nil, body_613907)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_613891(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_613892, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_613893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_613874 = ref object of OpenApiRestCall_612642
proc url_ListSubscriptionDefinitionVersions_613876(protocol: Scheme; host: string;
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
               (kind: VariableSegment, value: "SubscriptionDefinitionId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSubscriptionDefinitionVersions_613875(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the versions of a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_613877 = path.getOrDefault("SubscriptionDefinitionId")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = nil)
  if valid_613877 != nil:
    section.add "SubscriptionDefinitionId", valid_613877
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_613878 = query.getOrDefault("MaxResults")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "MaxResults", valid_613878
  var valid_613879 = query.getOrDefault("NextToken")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "NextToken", valid_613879
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
  var valid_613880 = header.getOrDefault("X-Amz-Signature")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Signature", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Content-Sha256", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Date")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Date", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Credential")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Credential", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Security-Token")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Security-Token", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Algorithm")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Algorithm", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-SignedHeaders", valid_613886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_ListSubscriptionDefinitionVersions_613874;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_ListSubscriptionDefinitionVersions_613874;
          SubscriptionDefinitionId: string; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitionVersions
  ## Lists the versions of a subscription definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_613889 = newJObject()
  var query_613890 = newJObject()
  add(query_613890, "MaxResults", newJString(MaxResults))
  add(query_613890, "NextToken", newJString(NextToken))
  add(path_613889, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_613888.call(path_613889, query_613890, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_613874(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_613875, base: "/",
    url: url_ListSubscriptionDefinitionVersions_613876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_613922 = ref object of OpenApiRestCall_612642
proc url_UpdateConnectorDefinition_613924(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConnectorDefinition_613923(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_613925 = path.getOrDefault("ConnectorDefinitionId")
  valid_613925 = validateParameter(valid_613925, JString, required = true,
                                 default = nil)
  if valid_613925 != nil:
    section.add "ConnectorDefinitionId", valid_613925
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
  var valid_613926 = header.getOrDefault("X-Amz-Signature")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Signature", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Content-Sha256", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Date")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Date", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Credential")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Credential", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Security-Token")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Security-Token", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Algorithm")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Algorithm", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-SignedHeaders", valid_613932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613934: Call_UpdateConnectorDefinition_613922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_613934.validator(path, query, header, formData, body)
  let scheme = call_613934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613934.url(scheme.get, call_613934.host, call_613934.base,
                         call_613934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613934, url, valid)

proc call*(call_613935: Call_UpdateConnectorDefinition_613922;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_613936 = newJObject()
  var body_613937 = newJObject()
  add(path_613936, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_613937 = body
  result = call_613935.call(path_613936, nil, nil, nil, body_613937)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_613922(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_613923, base: "/",
    url: url_UpdateConnectorDefinition_613924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_613908 = ref object of OpenApiRestCall_612642
proc url_GetConnectorDefinition_613910(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinition_613909(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_613911 = path.getOrDefault("ConnectorDefinitionId")
  valid_613911 = validateParameter(valid_613911, JString, required = true,
                                 default = nil)
  if valid_613911 != nil:
    section.add "ConnectorDefinitionId", valid_613911
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
  var valid_613912 = header.getOrDefault("X-Amz-Signature")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Signature", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Content-Sha256", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Date")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Date", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Credential")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Credential", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Security-Token")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Security-Token", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Algorithm")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Algorithm", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-SignedHeaders", valid_613918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613919: Call_GetConnectorDefinition_613908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_613919.validator(path, query, header, formData, body)
  let scheme = call_613919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613919.url(scheme.get, call_613919.host, call_613919.base,
                         call_613919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613919, url, valid)

proc call*(call_613920: Call_GetConnectorDefinition_613908;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_613921 = newJObject()
  add(path_613921, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_613920.call(path_613921, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_613908(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_613909, base: "/",
    url: url_GetConnectorDefinition_613910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_613938 = ref object of OpenApiRestCall_612642
proc url_DeleteConnectorDefinition_613940(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConnectorDefinition_613939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a connector definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConnectorDefinitionId: JString (required)
  ##                        : The ID of the connector definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConnectorDefinitionId` field"
  var valid_613941 = path.getOrDefault("ConnectorDefinitionId")
  valid_613941 = validateParameter(valid_613941, JString, required = true,
                                 default = nil)
  if valid_613941 != nil:
    section.add "ConnectorDefinitionId", valid_613941
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
  var valid_613942 = header.getOrDefault("X-Amz-Signature")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Signature", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Content-Sha256", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Date")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Date", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Credential")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Credential", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Security-Token")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Security-Token", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Algorithm")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Algorithm", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-SignedHeaders", valid_613948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613949: Call_DeleteConnectorDefinition_613938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_613949.validator(path, query, header, formData, body)
  let scheme = call_613949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613949.url(scheme.get, call_613949.host, call_613949.base,
                         call_613949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613949, url, valid)

proc call*(call_613950: Call_DeleteConnectorDefinition_613938;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_613951 = newJObject()
  add(path_613951, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_613950.call(path_613951, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_613938(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_613939, base: "/",
    url: url_DeleteConnectorDefinition_613940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_613966 = ref object of OpenApiRestCall_612642
proc url_UpdateCoreDefinition_613968(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCoreDefinition_613967(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613969 = path.getOrDefault("CoreDefinitionId")
  valid_613969 = validateParameter(valid_613969, JString, required = true,
                                 default = nil)
  if valid_613969 != nil:
    section.add "CoreDefinitionId", valid_613969
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
  var valid_613970 = header.getOrDefault("X-Amz-Signature")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Signature", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Content-Sha256", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Date")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Date", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-Credential")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Credential", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Security-Token")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Security-Token", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Algorithm")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Algorithm", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-SignedHeaders", valid_613976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613978: Call_UpdateCoreDefinition_613966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_613978.validator(path, query, header, formData, body)
  let scheme = call_613978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613978.url(scheme.get, call_613978.host, call_613978.base,
                         call_613978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613978, url, valid)

proc call*(call_613979: Call_UpdateCoreDefinition_613966; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_613980 = newJObject()
  var body_613981 = newJObject()
  add(path_613980, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_613981 = body
  result = call_613979.call(path_613980, nil, nil, nil, body_613981)

var updateCoreDefinition* = Call_UpdateCoreDefinition_613966(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_613967, base: "/",
    url: url_UpdateCoreDefinition_613968, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_613952 = ref object of OpenApiRestCall_612642
proc url_GetCoreDefinition_613954(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCoreDefinition_613953(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_613955 = path.getOrDefault("CoreDefinitionId")
  valid_613955 = validateParameter(valid_613955, JString, required = true,
                                 default = nil)
  if valid_613955 != nil:
    section.add "CoreDefinitionId", valid_613955
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
  var valid_613956 = header.getOrDefault("X-Amz-Signature")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Signature", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Content-Sha256", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Date")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Date", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Credential")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Credential", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Security-Token")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Security-Token", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Algorithm")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Algorithm", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-SignedHeaders", valid_613962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613963: Call_GetCoreDefinition_613952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_613963.validator(path, query, header, formData, body)
  let scheme = call_613963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613963.url(scheme.get, call_613963.host, call_613963.base,
                         call_613963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613963, url, valid)

proc call*(call_613964: Call_GetCoreDefinition_613952; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_613965 = newJObject()
  add(path_613965, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_613964.call(path_613965, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_613952(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_613953, base: "/",
    url: url_GetCoreDefinition_613954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_613982 = ref object of OpenApiRestCall_612642
proc url_DeleteCoreDefinition_613984(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCoreDefinition_613983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613985 = path.getOrDefault("CoreDefinitionId")
  valid_613985 = validateParameter(valid_613985, JString, required = true,
                                 default = nil)
  if valid_613985 != nil:
    section.add "CoreDefinitionId", valid_613985
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
  var valid_613986 = header.getOrDefault("X-Amz-Signature")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Signature", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Content-Sha256", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Date")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Date", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Credential")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Credential", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Security-Token")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Security-Token", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Algorithm")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Algorithm", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-SignedHeaders", valid_613992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613993: Call_DeleteCoreDefinition_613982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_613993.validator(path, query, header, formData, body)
  let scheme = call_613993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613993.url(scheme.get, call_613993.host, call_613993.base,
                         call_613993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613993, url, valid)

proc call*(call_613994: Call_DeleteCoreDefinition_613982; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_613995 = newJObject()
  add(path_613995, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_613994.call(path_613995, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_613982(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_613983, base: "/",
    url: url_DeleteCoreDefinition_613984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_614010 = ref object of OpenApiRestCall_612642
proc url_UpdateDeviceDefinition_614012(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeviceDefinition_614011(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614013 = path.getOrDefault("DeviceDefinitionId")
  valid_614013 = validateParameter(valid_614013, JString, required = true,
                                 default = nil)
  if valid_614013 != nil:
    section.add "DeviceDefinitionId", valid_614013
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
  var valid_614014 = header.getOrDefault("X-Amz-Signature")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Signature", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Content-Sha256", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Date")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Date", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Credential")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Credential", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Security-Token")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Security-Token", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Algorithm")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Algorithm", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-SignedHeaders", valid_614020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614022: Call_UpdateDeviceDefinition_614010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_614022.validator(path, query, header, formData, body)
  let scheme = call_614022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614022.url(scheme.get, call_614022.host, call_614022.base,
                         call_614022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614022, url, valid)

proc call*(call_614023: Call_UpdateDeviceDefinition_614010;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_614024 = newJObject()
  var body_614025 = newJObject()
  add(path_614024, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_614025 = body
  result = call_614023.call(path_614024, nil, nil, nil, body_614025)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_614010(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_614011, base: "/",
    url: url_UpdateDeviceDefinition_614012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_613996 = ref object of OpenApiRestCall_612642
proc url_GetDeviceDefinition_613998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceDefinition_613997(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_613999 = path.getOrDefault("DeviceDefinitionId")
  valid_613999 = validateParameter(valid_613999, JString, required = true,
                                 default = nil)
  if valid_613999 != nil:
    section.add "DeviceDefinitionId", valid_613999
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
  var valid_614000 = header.getOrDefault("X-Amz-Signature")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Signature", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Content-Sha256", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Date")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Date", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-Credential")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Credential", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Security-Token")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Security-Token", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Algorithm")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Algorithm", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-SignedHeaders", valid_614006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614007: Call_GetDeviceDefinition_613996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_614007.validator(path, query, header, formData, body)
  let scheme = call_614007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614007.url(scheme.get, call_614007.host, call_614007.base,
                         call_614007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614007, url, valid)

proc call*(call_614008: Call_GetDeviceDefinition_613996; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_614009 = newJObject()
  add(path_614009, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_614008.call(path_614009, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_613996(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_613997, base: "/",
    url: url_GetDeviceDefinition_613998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_614026 = ref object of OpenApiRestCall_612642
proc url_DeleteDeviceDefinition_614028(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeviceDefinition_614027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614029 = path.getOrDefault("DeviceDefinitionId")
  valid_614029 = validateParameter(valid_614029, JString, required = true,
                                 default = nil)
  if valid_614029 != nil:
    section.add "DeviceDefinitionId", valid_614029
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
  var valid_614030 = header.getOrDefault("X-Amz-Signature")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Signature", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Content-Sha256", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Date")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Date", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Credential")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Credential", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Security-Token")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Security-Token", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Algorithm")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Algorithm", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-SignedHeaders", valid_614036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614037: Call_DeleteDeviceDefinition_614026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_614037.validator(path, query, header, formData, body)
  let scheme = call_614037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614037.url(scheme.get, call_614037.host, call_614037.base,
                         call_614037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614037, url, valid)

proc call*(call_614038: Call_DeleteDeviceDefinition_614026;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_614039 = newJObject()
  add(path_614039, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_614038.call(path_614039, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_614026(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_614027, base: "/",
    url: url_DeleteDeviceDefinition_614028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_614054 = ref object of OpenApiRestCall_612642
proc url_UpdateFunctionDefinition_614056(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionDefinition_614055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_614057 = path.getOrDefault("FunctionDefinitionId")
  valid_614057 = validateParameter(valid_614057, JString, required = true,
                                 default = nil)
  if valid_614057 != nil:
    section.add "FunctionDefinitionId", valid_614057
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
  var valid_614058 = header.getOrDefault("X-Amz-Signature")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Signature", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Content-Sha256", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Date")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Date", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Credential")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Credential", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-Security-Token")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Security-Token", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Algorithm")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Algorithm", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-SignedHeaders", valid_614064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614066: Call_UpdateFunctionDefinition_614054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_614066.validator(path, query, header, formData, body)
  let scheme = call_614066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614066.url(scheme.get, call_614066.host, call_614066.base,
                         call_614066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614066, url, valid)

proc call*(call_614067: Call_UpdateFunctionDefinition_614054;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_614068 = newJObject()
  var body_614069 = newJObject()
  add(path_614068, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_614069 = body
  result = call_614067.call(path_614068, nil, nil, nil, body_614069)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_614054(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_614055, base: "/",
    url: url_UpdateFunctionDefinition_614056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_614040 = ref object of OpenApiRestCall_612642
proc url_GetFunctionDefinition_614042(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinition_614041(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_614043 = path.getOrDefault("FunctionDefinitionId")
  valid_614043 = validateParameter(valid_614043, JString, required = true,
                                 default = nil)
  if valid_614043 != nil:
    section.add "FunctionDefinitionId", valid_614043
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
  var valid_614044 = header.getOrDefault("X-Amz-Signature")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Signature", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Content-Sha256", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Date")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Date", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Credential")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Credential", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Security-Token")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Security-Token", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Algorithm")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Algorithm", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-SignedHeaders", valid_614050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614051: Call_GetFunctionDefinition_614040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_614051.validator(path, query, header, formData, body)
  let scheme = call_614051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614051.url(scheme.get, call_614051.host, call_614051.base,
                         call_614051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614051, url, valid)

proc call*(call_614052: Call_GetFunctionDefinition_614040;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_614053 = newJObject()
  add(path_614053, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_614052.call(path_614053, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_614040(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_614041, base: "/",
    url: url_GetFunctionDefinition_614042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_614070 = ref object of OpenApiRestCall_612642
proc url_DeleteFunctionDefinition_614072(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionDefinition_614071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Lambda function definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionDefinitionId: JString (required)
  ##                       : The ID of the Lambda function definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FunctionDefinitionId` field"
  var valid_614073 = path.getOrDefault("FunctionDefinitionId")
  valid_614073 = validateParameter(valid_614073, JString, required = true,
                                 default = nil)
  if valid_614073 != nil:
    section.add "FunctionDefinitionId", valid_614073
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
  var valid_614074 = header.getOrDefault("X-Amz-Signature")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Signature", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Content-Sha256", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Date")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Date", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Credential")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Credential", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Security-Token")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Security-Token", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Algorithm")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Algorithm", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-SignedHeaders", valid_614080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614081: Call_DeleteFunctionDefinition_614070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_614081.validator(path, query, header, formData, body)
  let scheme = call_614081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614081.url(scheme.get, call_614081.host, call_614081.base,
                         call_614081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614081, url, valid)

proc call*(call_614082: Call_DeleteFunctionDefinition_614070;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_614083 = newJObject()
  add(path_614083, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_614082.call(path_614083, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_614070(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_614071, base: "/",
    url: url_DeleteFunctionDefinition_614072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_614098 = ref object of OpenApiRestCall_612642
proc url_UpdateGroup_614100(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_614099(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614101 = path.getOrDefault("GroupId")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = nil)
  if valid_614101 != nil:
    section.add "GroupId", valid_614101
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
  var valid_614102 = header.getOrDefault("X-Amz-Signature")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Signature", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Content-Sha256", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Date")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Date", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Credential")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Credential", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Security-Token")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Security-Token", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Algorithm")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Algorithm", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-SignedHeaders", valid_614108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614110: Call_UpdateGroup_614098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_614110.validator(path, query, header, formData, body)
  let scheme = call_614110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614110.url(scheme.get, call_614110.host, call_614110.base,
                         call_614110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614110, url, valid)

proc call*(call_614111: Call_UpdateGroup_614098; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_614112 = newJObject()
  var body_614113 = newJObject()
  add(path_614112, "GroupId", newJString(GroupId))
  if body != nil:
    body_614113 = body
  result = call_614111.call(path_614112, nil, nil, nil, body_614113)

var updateGroup* = Call_UpdateGroup_614098(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_614099,
                                        base: "/", url: url_UpdateGroup_614100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_614084 = ref object of OpenApiRestCall_612642
proc url_GetGroup_614086(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroup_614085(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614087 = path.getOrDefault("GroupId")
  valid_614087 = validateParameter(valid_614087, JString, required = true,
                                 default = nil)
  if valid_614087 != nil:
    section.add "GroupId", valid_614087
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
  var valid_614088 = header.getOrDefault("X-Amz-Signature")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Signature", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Content-Sha256", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Date")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Date", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Credential")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Credential", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Security-Token")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Security-Token", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Algorithm")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Algorithm", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-SignedHeaders", valid_614094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614095: Call_GetGroup_614084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_614095.validator(path, query, header, formData, body)
  let scheme = call_614095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614095.url(scheme.get, call_614095.host, call_614095.base,
                         call_614095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614095, url, valid)

proc call*(call_614096: Call_GetGroup_614084; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_614097 = newJObject()
  add(path_614097, "GroupId", newJString(GroupId))
  result = call_614096.call(path_614097, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_614084(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_614085, base: "/",
                                  url: url_GetGroup_614086,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_614114 = ref object of OpenApiRestCall_612642
proc url_DeleteGroup_614116(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_614115(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614117 = path.getOrDefault("GroupId")
  valid_614117 = validateParameter(valid_614117, JString, required = true,
                                 default = nil)
  if valid_614117 != nil:
    section.add "GroupId", valid_614117
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
  var valid_614118 = header.getOrDefault("X-Amz-Signature")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-Signature", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Content-Sha256", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-Date")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Date", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Credential")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Credential", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Security-Token")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Security-Token", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Algorithm")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Algorithm", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-SignedHeaders", valid_614124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614125: Call_DeleteGroup_614114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_614125.validator(path, query, header, formData, body)
  let scheme = call_614125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614125.url(scheme.get, call_614125.host, call_614125.base,
                         call_614125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614125, url, valid)

proc call*(call_614126: Call_DeleteGroup_614114; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_614127 = newJObject()
  add(path_614127, "GroupId", newJString(GroupId))
  result = call_614126.call(path_614127, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_614114(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_614115,
                                        base: "/", url: url_DeleteGroup_614116,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_614142 = ref object of OpenApiRestCall_612642
proc url_UpdateLoggerDefinition_614144(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLoggerDefinition_614143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614145 = path.getOrDefault("LoggerDefinitionId")
  valid_614145 = validateParameter(valid_614145, JString, required = true,
                                 default = nil)
  if valid_614145 != nil:
    section.add "LoggerDefinitionId", valid_614145
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
  var valid_614146 = header.getOrDefault("X-Amz-Signature")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Signature", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Content-Sha256", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Date")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Date", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Credential")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Credential", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Security-Token")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Security-Token", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Algorithm")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Algorithm", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-SignedHeaders", valid_614152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614154: Call_UpdateLoggerDefinition_614142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_614154.validator(path, query, header, formData, body)
  let scheme = call_614154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614154.url(scheme.get, call_614154.host, call_614154.base,
                         call_614154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614154, url, valid)

proc call*(call_614155: Call_UpdateLoggerDefinition_614142;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_614156 = newJObject()
  var body_614157 = newJObject()
  add(path_614156, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_614157 = body
  result = call_614155.call(path_614156, nil, nil, nil, body_614157)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_614142(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_614143, base: "/",
    url: url_UpdateLoggerDefinition_614144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_614128 = ref object of OpenApiRestCall_612642
proc url_GetLoggerDefinition_614130(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLoggerDefinition_614129(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_614131 = path.getOrDefault("LoggerDefinitionId")
  valid_614131 = validateParameter(valid_614131, JString, required = true,
                                 default = nil)
  if valid_614131 != nil:
    section.add "LoggerDefinitionId", valid_614131
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
  var valid_614132 = header.getOrDefault("X-Amz-Signature")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Signature", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Content-Sha256", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Date")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Date", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Credential")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Credential", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Security-Token")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Security-Token", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-Algorithm")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Algorithm", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-SignedHeaders", valid_614138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614139: Call_GetLoggerDefinition_614128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_614139.validator(path, query, header, formData, body)
  let scheme = call_614139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614139.url(scheme.get, call_614139.host, call_614139.base,
                         call_614139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614139, url, valid)

proc call*(call_614140: Call_GetLoggerDefinition_614128; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_614141 = newJObject()
  add(path_614141, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_614140.call(path_614141, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_614128(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_614129, base: "/",
    url: url_GetLoggerDefinition_614130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_614158 = ref object of OpenApiRestCall_612642
proc url_DeleteLoggerDefinition_614160(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLoggerDefinition_614159(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614161 = path.getOrDefault("LoggerDefinitionId")
  valid_614161 = validateParameter(valid_614161, JString, required = true,
                                 default = nil)
  if valid_614161 != nil:
    section.add "LoggerDefinitionId", valid_614161
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
  var valid_614162 = header.getOrDefault("X-Amz-Signature")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Signature", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Content-Sha256", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Date")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Date", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Credential")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Credential", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Security-Token")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Security-Token", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Algorithm")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Algorithm", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-SignedHeaders", valid_614168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614169: Call_DeleteLoggerDefinition_614158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_614169.validator(path, query, header, formData, body)
  let scheme = call_614169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614169.url(scheme.get, call_614169.host, call_614169.base,
                         call_614169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614169, url, valid)

proc call*(call_614170: Call_DeleteLoggerDefinition_614158;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_614171 = newJObject()
  add(path_614171, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_614170.call(path_614171, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_614158(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_614159, base: "/",
    url: url_DeleteLoggerDefinition_614160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_614186 = ref object of OpenApiRestCall_612642
proc url_UpdateResourceDefinition_614188(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResourceDefinition_614187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_614189 = path.getOrDefault("ResourceDefinitionId")
  valid_614189 = validateParameter(valid_614189, JString, required = true,
                                 default = nil)
  if valid_614189 != nil:
    section.add "ResourceDefinitionId", valid_614189
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
  var valid_614190 = header.getOrDefault("X-Amz-Signature")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Signature", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-Content-Sha256", valid_614191
  var valid_614192 = header.getOrDefault("X-Amz-Date")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "X-Amz-Date", valid_614192
  var valid_614193 = header.getOrDefault("X-Amz-Credential")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Credential", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Security-Token")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Security-Token", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Algorithm")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Algorithm", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-SignedHeaders", valid_614196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614198: Call_UpdateResourceDefinition_614186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_614198.validator(path, query, header, formData, body)
  let scheme = call_614198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614198.url(scheme.get, call_614198.host, call_614198.base,
                         call_614198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614198, url, valid)

proc call*(call_614199: Call_UpdateResourceDefinition_614186; body: JsonNode;
          ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_614200 = newJObject()
  var body_614201 = newJObject()
  if body != nil:
    body_614201 = body
  add(path_614200, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_614199.call(path_614200, nil, nil, nil, body_614201)

var updateResourceDefinition* = Call_UpdateResourceDefinition_614186(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_614187, base: "/",
    url: url_UpdateResourceDefinition_614188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_614172 = ref object of OpenApiRestCall_612642
proc url_GetResourceDefinition_614174(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinition_614173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_614175 = path.getOrDefault("ResourceDefinitionId")
  valid_614175 = validateParameter(valid_614175, JString, required = true,
                                 default = nil)
  if valid_614175 != nil:
    section.add "ResourceDefinitionId", valid_614175
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
  var valid_614176 = header.getOrDefault("X-Amz-Signature")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Signature", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Content-Sha256", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Date")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Date", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Credential")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Credential", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Security-Token")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Security-Token", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Algorithm")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Algorithm", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-SignedHeaders", valid_614182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614183: Call_GetResourceDefinition_614172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_614183.validator(path, query, header, formData, body)
  let scheme = call_614183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614183.url(scheme.get, call_614183.host, call_614183.base,
                         call_614183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614183, url, valid)

proc call*(call_614184: Call_GetResourceDefinition_614172;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_614185 = newJObject()
  add(path_614185, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_614184.call(path_614185, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_614172(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_614173, base: "/",
    url: url_GetResourceDefinition_614174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_614202 = ref object of OpenApiRestCall_612642
proc url_DeleteResourceDefinition_614204(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResourceDefinition_614203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a resource definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceDefinitionId: JString (required)
  ##                       : The ID of the resource definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ResourceDefinitionId` field"
  var valid_614205 = path.getOrDefault("ResourceDefinitionId")
  valid_614205 = validateParameter(valid_614205, JString, required = true,
                                 default = nil)
  if valid_614205 != nil:
    section.add "ResourceDefinitionId", valid_614205
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
  var valid_614206 = header.getOrDefault("X-Amz-Signature")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-Signature", valid_614206
  var valid_614207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Content-Sha256", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Date")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Date", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Credential")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Credential", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Security-Token")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Security-Token", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Algorithm")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Algorithm", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-SignedHeaders", valid_614212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614213: Call_DeleteResourceDefinition_614202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_614213.validator(path, query, header, formData, body)
  let scheme = call_614213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614213.url(scheme.get, call_614213.host, call_614213.base,
                         call_614213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614213, url, valid)

proc call*(call_614214: Call_DeleteResourceDefinition_614202;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_614215 = newJObject()
  add(path_614215, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_614214.call(path_614215, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_614202(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_614203, base: "/",
    url: url_DeleteResourceDefinition_614204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_614230 = ref object of OpenApiRestCall_612642
proc url_UpdateSubscriptionDefinition_614232(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSubscriptionDefinition_614231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_614233 = path.getOrDefault("SubscriptionDefinitionId")
  valid_614233 = validateParameter(valid_614233, JString, required = true,
                                 default = nil)
  if valid_614233 != nil:
    section.add "SubscriptionDefinitionId", valid_614233
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
  var valid_614234 = header.getOrDefault("X-Amz-Signature")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Signature", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-Content-Sha256", valid_614235
  var valid_614236 = header.getOrDefault("X-Amz-Date")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Date", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-Credential")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Credential", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Security-Token")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Security-Token", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Algorithm")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Algorithm", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-SignedHeaders", valid_614240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614242: Call_UpdateSubscriptionDefinition_614230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_614242.validator(path, query, header, formData, body)
  let scheme = call_614242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614242.url(scheme.get, call_614242.host, call_614242.base,
                         call_614242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614242, url, valid)

proc call*(call_614243: Call_UpdateSubscriptionDefinition_614230;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_614244 = newJObject()
  var body_614245 = newJObject()
  add(path_614244, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_614245 = body
  result = call_614243.call(path_614244, nil, nil, nil, body_614245)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_614230(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_614231, base: "/",
    url: url_UpdateSubscriptionDefinition_614232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_614216 = ref object of OpenApiRestCall_612642
proc url_GetSubscriptionDefinition_614218(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSubscriptionDefinition_614217(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_614219 = path.getOrDefault("SubscriptionDefinitionId")
  valid_614219 = validateParameter(valid_614219, JString, required = true,
                                 default = nil)
  if valid_614219 != nil:
    section.add "SubscriptionDefinitionId", valid_614219
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
  var valid_614220 = header.getOrDefault("X-Amz-Signature")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Signature", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Content-Sha256", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Date")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Date", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Credential")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Credential", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Security-Token")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Security-Token", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-Algorithm")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Algorithm", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-SignedHeaders", valid_614226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614227: Call_GetSubscriptionDefinition_614216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_614227.validator(path, query, header, formData, body)
  let scheme = call_614227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614227.url(scheme.get, call_614227.host, call_614227.base,
                         call_614227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614227, url, valid)

proc call*(call_614228: Call_GetSubscriptionDefinition_614216;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_614229 = newJObject()
  add(path_614229, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_614228.call(path_614229, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_614216(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_614217, base: "/",
    url: url_GetSubscriptionDefinition_614218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_614246 = ref object of OpenApiRestCall_612642
proc url_DeleteSubscriptionDefinition_614248(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSubscriptionDefinition_614247(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a subscription definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionId` field"
  var valid_614249 = path.getOrDefault("SubscriptionDefinitionId")
  valid_614249 = validateParameter(valid_614249, JString, required = true,
                                 default = nil)
  if valid_614249 != nil:
    section.add "SubscriptionDefinitionId", valid_614249
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
  var valid_614250 = header.getOrDefault("X-Amz-Signature")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-Signature", valid_614250
  var valid_614251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Content-Sha256", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Date")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Date", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Credential")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Credential", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Security-Token")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Security-Token", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Algorithm")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Algorithm", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-SignedHeaders", valid_614256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614257: Call_DeleteSubscriptionDefinition_614246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_614257.validator(path, query, header, formData, body)
  let scheme = call_614257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614257.url(scheme.get, call_614257.host, call_614257.base,
                         call_614257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614257, url, valid)

proc call*(call_614258: Call_DeleteSubscriptionDefinition_614246;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_614259 = newJObject()
  add(path_614259, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_614258.call(path_614259, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_614246(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_614247, base: "/",
    url: url_DeleteSubscriptionDefinition_614248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_614260 = ref object of OpenApiRestCall_612642
proc url_GetBulkDeploymentStatus_614262(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkDeploymentStatus_614261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614263 = path.getOrDefault("BulkDeploymentId")
  valid_614263 = validateParameter(valid_614263, JString, required = true,
                                 default = nil)
  if valid_614263 != nil:
    section.add "BulkDeploymentId", valid_614263
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
  var valid_614264 = header.getOrDefault("X-Amz-Signature")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Signature", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Content-Sha256", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-Date")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Date", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Credential")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Credential", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Security-Token")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Security-Token", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Algorithm")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Algorithm", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-SignedHeaders", valid_614270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614271: Call_GetBulkDeploymentStatus_614260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_614271.validator(path, query, header, formData, body)
  let scheme = call_614271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614271.url(scheme.get, call_614271.host, call_614271.base,
                         call_614271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614271, url, valid)

proc call*(call_614272: Call_GetBulkDeploymentStatus_614260;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_614273 = newJObject()
  add(path_614273, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_614272.call(path_614273, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_614260(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_614261, base: "/",
    url: url_GetBulkDeploymentStatus_614262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_614288 = ref object of OpenApiRestCall_612642
proc url_UpdateConnectivityInfo_614290(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConnectivityInfo_614289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ThingName: JString (required)
  ##            : The thing name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ThingName` field"
  var valid_614291 = path.getOrDefault("ThingName")
  valid_614291 = validateParameter(valid_614291, JString, required = true,
                                 default = nil)
  if valid_614291 != nil:
    section.add "ThingName", valid_614291
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
  var valid_614292 = header.getOrDefault("X-Amz-Signature")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Signature", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Content-Sha256", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Date")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Date", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Credential")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Credential", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-Security-Token")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Security-Token", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Algorithm")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Algorithm", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-SignedHeaders", valid_614298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614300: Call_UpdateConnectivityInfo_614288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_614300.validator(path, query, header, formData, body)
  let scheme = call_614300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614300.url(scheme.get, call_614300.host, call_614300.base,
                         call_614300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614300, url, valid)

proc call*(call_614301: Call_UpdateConnectivityInfo_614288; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_614302 = newJObject()
  var body_614303 = newJObject()
  add(path_614302, "ThingName", newJString(ThingName))
  if body != nil:
    body_614303 = body
  result = call_614301.call(path_614302, nil, nil, nil, body_614303)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_614288(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_614289, base: "/",
    url: url_UpdateConnectivityInfo_614290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_614274 = ref object of OpenApiRestCall_612642
proc url_GetConnectivityInfo_614276(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectivityInfo_614275(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the connectivity information for a core.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ThingName: JString (required)
  ##            : The thing name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ThingName` field"
  var valid_614277 = path.getOrDefault("ThingName")
  valid_614277 = validateParameter(valid_614277, JString, required = true,
                                 default = nil)
  if valid_614277 != nil:
    section.add "ThingName", valid_614277
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
  var valid_614278 = header.getOrDefault("X-Amz-Signature")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-Signature", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Content-Sha256", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-Date")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-Date", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-Credential")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Credential", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Security-Token")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Security-Token", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Algorithm")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Algorithm", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-SignedHeaders", valid_614284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614285: Call_GetConnectivityInfo_614274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_614285.validator(path, query, header, formData, body)
  let scheme = call_614285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614285.url(scheme.get, call_614285.host, call_614285.base,
                         call_614285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614285, url, valid)

proc call*(call_614286: Call_GetConnectivityInfo_614274; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_614287 = newJObject()
  add(path_614287, "ThingName", newJString(ThingName))
  result = call_614286.call(path_614287, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_614274(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_614275, base: "/",
    url: url_GetConnectivityInfo_614276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_614304 = ref object of OpenApiRestCall_612642
proc url_GetConnectorDefinitionVersion_614306(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinitionVersion_614305(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614307 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_614307 = validateParameter(valid_614307, JString, required = true,
                                 default = nil)
  if valid_614307 != nil:
    section.add "ConnectorDefinitionVersionId", valid_614307
  var valid_614308 = path.getOrDefault("ConnectorDefinitionId")
  valid_614308 = validateParameter(valid_614308, JString, required = true,
                                 default = nil)
  if valid_614308 != nil:
    section.add "ConnectorDefinitionId", valid_614308
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614309 = query.getOrDefault("NextToken")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "NextToken", valid_614309
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
  var valid_614310 = header.getOrDefault("X-Amz-Signature")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Signature", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Content-Sha256", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Date")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Date", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Credential")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Credential", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Security-Token")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Security-Token", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Algorithm")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Algorithm", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-SignedHeaders", valid_614316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614317: Call_GetConnectorDefinitionVersion_614304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_614317.validator(path, query, header, formData, body)
  let scheme = call_614317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614317.url(scheme.get, call_614317.host, call_614317.base,
                         call_614317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614317, url, valid)

proc call*(call_614318: Call_GetConnectorDefinitionVersion_614304;
          ConnectorDefinitionVersionId: string; ConnectorDefinitionId: string;
          NextToken: string = ""): Recallable =
  ## getConnectorDefinitionVersion
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ##   ConnectorDefinitionVersionId: string (required)
  ##                               : The ID of the connector definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListConnectorDefinitionVersions'' requests. If the version is the last one that was associated with a connector definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_614319 = newJObject()
  var query_614320 = newJObject()
  add(path_614319, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_614320, "NextToken", newJString(NextToken))
  add(path_614319, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_614318.call(path_614319, query_614320, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_614304(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_614305, base: "/",
    url: url_GetConnectorDefinitionVersion_614306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_614321 = ref object of OpenApiRestCall_612642
proc url_GetCoreDefinitionVersion_614323(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCoreDefinitionVersion_614322(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a core definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CoreDefinitionVersionId: JString (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: JString (required)
  ##                   : The ID of the core definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `CoreDefinitionVersionId` field"
  var valid_614324 = path.getOrDefault("CoreDefinitionVersionId")
  valid_614324 = validateParameter(valid_614324, JString, required = true,
                                 default = nil)
  if valid_614324 != nil:
    section.add "CoreDefinitionVersionId", valid_614324
  var valid_614325 = path.getOrDefault("CoreDefinitionId")
  valid_614325 = validateParameter(valid_614325, JString, required = true,
                                 default = nil)
  if valid_614325 != nil:
    section.add "CoreDefinitionId", valid_614325
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
  var valid_614326 = header.getOrDefault("X-Amz-Signature")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "X-Amz-Signature", valid_614326
  var valid_614327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "X-Amz-Content-Sha256", valid_614327
  var valid_614328 = header.getOrDefault("X-Amz-Date")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "X-Amz-Date", valid_614328
  var valid_614329 = header.getOrDefault("X-Amz-Credential")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Credential", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Security-Token")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Security-Token", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Algorithm")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Algorithm", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-SignedHeaders", valid_614332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614333: Call_GetCoreDefinitionVersion_614321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_614333.validator(path, query, header, formData, body)
  let scheme = call_614333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614333.url(scheme.get, call_614333.host, call_614333.base,
                         call_614333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614333, url, valid)

proc call*(call_614334: Call_GetCoreDefinitionVersion_614321;
          CoreDefinitionVersionId: string; CoreDefinitionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_614335 = newJObject()
  add(path_614335, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  add(path_614335, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_614334.call(path_614335, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_614321(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_614322, base: "/",
    url: url_GetCoreDefinitionVersion_614323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_614336 = ref object of OpenApiRestCall_612642
proc url_GetDeploymentStatus_614338(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeploymentStatus_614337(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_614339 = path.getOrDefault("GroupId")
  valid_614339 = validateParameter(valid_614339, JString, required = true,
                                 default = nil)
  if valid_614339 != nil:
    section.add "GroupId", valid_614339
  var valid_614340 = path.getOrDefault("DeploymentId")
  valid_614340 = validateParameter(valid_614340, JString, required = true,
                                 default = nil)
  if valid_614340 != nil:
    section.add "DeploymentId", valid_614340
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
  var valid_614341 = header.getOrDefault("X-Amz-Signature")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-Signature", valid_614341
  var valid_614342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614342 = validateParameter(valid_614342, JString, required = false,
                                 default = nil)
  if valid_614342 != nil:
    section.add "X-Amz-Content-Sha256", valid_614342
  var valid_614343 = header.getOrDefault("X-Amz-Date")
  valid_614343 = validateParameter(valid_614343, JString, required = false,
                                 default = nil)
  if valid_614343 != nil:
    section.add "X-Amz-Date", valid_614343
  var valid_614344 = header.getOrDefault("X-Amz-Credential")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Credential", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-Security-Token")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-Security-Token", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Algorithm")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Algorithm", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-SignedHeaders", valid_614347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614348: Call_GetDeploymentStatus_614336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_614348.validator(path, query, header, formData, body)
  let scheme = call_614348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614348.url(scheme.get, call_614348.host, call_614348.base,
                         call_614348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614348, url, valid)

proc call*(call_614349: Call_GetDeploymentStatus_614336; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_614350 = newJObject()
  add(path_614350, "GroupId", newJString(GroupId))
  add(path_614350, "DeploymentId", newJString(DeploymentId))
  result = call_614349.call(path_614350, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_614336(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_614337, base: "/",
    url: url_GetDeploymentStatus_614338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_614351 = ref object of OpenApiRestCall_612642
proc url_GetDeviceDefinitionVersion_614353(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeviceDefinitionVersion_614352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614354 = path.getOrDefault("DeviceDefinitionId")
  valid_614354 = validateParameter(valid_614354, JString, required = true,
                                 default = nil)
  if valid_614354 != nil:
    section.add "DeviceDefinitionId", valid_614354
  var valid_614355 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_614355 = validateParameter(valid_614355, JString, required = true,
                                 default = nil)
  if valid_614355 != nil:
    section.add "DeviceDefinitionVersionId", valid_614355
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614356 = query.getOrDefault("NextToken")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "NextToken", valid_614356
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
  var valid_614357 = header.getOrDefault("X-Amz-Signature")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Signature", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-Content-Sha256", valid_614358
  var valid_614359 = header.getOrDefault("X-Amz-Date")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "X-Amz-Date", valid_614359
  var valid_614360 = header.getOrDefault("X-Amz-Credential")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "X-Amz-Credential", valid_614360
  var valid_614361 = header.getOrDefault("X-Amz-Security-Token")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "X-Amz-Security-Token", valid_614361
  var valid_614362 = header.getOrDefault("X-Amz-Algorithm")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Algorithm", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-SignedHeaders", valid_614363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614364: Call_GetDeviceDefinitionVersion_614351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_614364.validator(path, query, header, formData, body)
  let scheme = call_614364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614364.url(scheme.get, call_614364.host, call_614364.base,
                         call_614364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614364, url, valid)

proc call*(call_614365: Call_GetDeviceDefinitionVersion_614351;
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
  var path_614366 = newJObject()
  var query_614367 = newJObject()
  add(path_614366, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_614367, "NextToken", newJString(NextToken))
  add(path_614366, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_614365.call(path_614366, query_614367, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_614351(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_614352, base: "/",
    url: url_GetDeviceDefinitionVersion_614353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_614368 = ref object of OpenApiRestCall_612642
proc url_GetFunctionDefinitionVersion_614370(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinitionVersion_614369(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614371 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_614371 = validateParameter(valid_614371, JString, required = true,
                                 default = nil)
  if valid_614371 != nil:
    section.add "FunctionDefinitionVersionId", valid_614371
  var valid_614372 = path.getOrDefault("FunctionDefinitionId")
  valid_614372 = validateParameter(valid_614372, JString, required = true,
                                 default = nil)
  if valid_614372 != nil:
    section.add "FunctionDefinitionId", valid_614372
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614373 = query.getOrDefault("NextToken")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "NextToken", valid_614373
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
  var valid_614374 = header.getOrDefault("X-Amz-Signature")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Signature", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-Content-Sha256", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-Date")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-Date", valid_614376
  var valid_614377 = header.getOrDefault("X-Amz-Credential")
  valid_614377 = validateParameter(valid_614377, JString, required = false,
                                 default = nil)
  if valid_614377 != nil:
    section.add "X-Amz-Credential", valid_614377
  var valid_614378 = header.getOrDefault("X-Amz-Security-Token")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "X-Amz-Security-Token", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Algorithm")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Algorithm", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-SignedHeaders", valid_614380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614381: Call_GetFunctionDefinitionVersion_614368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_614381.validator(path, query, header, formData, body)
  let scheme = call_614381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614381.url(scheme.get, call_614381.host, call_614381.base,
                         call_614381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614381, url, valid)

proc call*(call_614382: Call_GetFunctionDefinitionVersion_614368;
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
  var path_614383 = newJObject()
  var query_614384 = newJObject()
  add(path_614383, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_614384, "NextToken", newJString(NextToken))
  add(path_614383, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_614382.call(path_614383, query_614384, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_614368(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_614369, base: "/",
    url: url_GetFunctionDefinitionVersion_614370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_614385 = ref object of OpenApiRestCall_612642
proc url_GetGroupCertificateAuthority_614387(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupCertificateAuthority_614386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614388 = path.getOrDefault("GroupId")
  valid_614388 = validateParameter(valid_614388, JString, required = true,
                                 default = nil)
  if valid_614388 != nil:
    section.add "GroupId", valid_614388
  var valid_614389 = path.getOrDefault("CertificateAuthorityId")
  valid_614389 = validateParameter(valid_614389, JString, required = true,
                                 default = nil)
  if valid_614389 != nil:
    section.add "CertificateAuthorityId", valid_614389
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
  var valid_614390 = header.getOrDefault("X-Amz-Signature")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Signature", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Content-Sha256", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-Date")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-Date", valid_614392
  var valid_614393 = header.getOrDefault("X-Amz-Credential")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Credential", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Security-Token")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Security-Token", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Algorithm")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Algorithm", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-SignedHeaders", valid_614396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614397: Call_GetGroupCertificateAuthority_614385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_614397.validator(path, query, header, formData, body)
  let scheme = call_614397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614397.url(scheme.get, call_614397.host, call_614397.base,
                         call_614397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614397, url, valid)

proc call*(call_614398: Call_GetGroupCertificateAuthority_614385; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_614399 = newJObject()
  add(path_614399, "GroupId", newJString(GroupId))
  add(path_614399, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_614398.call(path_614399, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_614385(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_614386, base: "/",
    url: url_GetGroupCertificateAuthority_614387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_614414 = ref object of OpenApiRestCall_612642
proc url_UpdateGroupCertificateConfiguration_614416(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroupCertificateConfiguration_614415(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the Certificate expiry time for a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614417 = path.getOrDefault("GroupId")
  valid_614417 = validateParameter(valid_614417, JString, required = true,
                                 default = nil)
  if valid_614417 != nil:
    section.add "GroupId", valid_614417
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
  var valid_614418 = header.getOrDefault("X-Amz-Signature")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Signature", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Content-Sha256", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Date")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Date", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Credential")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Credential", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Security-Token")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Security-Token", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Algorithm")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Algorithm", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-SignedHeaders", valid_614424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614426: Call_UpdateGroupCertificateConfiguration_614414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_614426.validator(path, query, header, formData, body)
  let scheme = call_614426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614426.url(scheme.get, call_614426.host, call_614426.base,
                         call_614426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614426, url, valid)

proc call*(call_614427: Call_UpdateGroupCertificateConfiguration_614414;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_614428 = newJObject()
  var body_614429 = newJObject()
  add(path_614428, "GroupId", newJString(GroupId))
  if body != nil:
    body_614429 = body
  result = call_614427.call(path_614428, nil, nil, nil, body_614429)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_614414(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_614415, base: "/",
    url: url_UpdateGroupCertificateConfiguration_614416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_614400 = ref object of OpenApiRestCall_612642
proc url_GetGroupCertificateConfiguration_614402(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupCertificateConfiguration_614401(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614403 = path.getOrDefault("GroupId")
  valid_614403 = validateParameter(valid_614403, JString, required = true,
                                 default = nil)
  if valid_614403 != nil:
    section.add "GroupId", valid_614403
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
  var valid_614404 = header.getOrDefault("X-Amz-Signature")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Signature", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Content-Sha256", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Date")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Date", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Credential")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Credential", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Security-Token")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Security-Token", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Algorithm")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Algorithm", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-SignedHeaders", valid_614410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614411: Call_GetGroupCertificateConfiguration_614400;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_614411.validator(path, query, header, formData, body)
  let scheme = call_614411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614411.url(scheme.get, call_614411.host, call_614411.base,
                         call_614411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614411, url, valid)

proc call*(call_614412: Call_GetGroupCertificateConfiguration_614400;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_614413 = newJObject()
  add(path_614413, "GroupId", newJString(GroupId))
  result = call_614412.call(path_614413, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_614400(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_614401, base: "/",
    url: url_GetGroupCertificateConfiguration_614402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_614430 = ref object of OpenApiRestCall_612642
proc url_GetGroupVersion_614432(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGroupVersion_614431(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_614433 = path.getOrDefault("GroupVersionId")
  valid_614433 = validateParameter(valid_614433, JString, required = true,
                                 default = nil)
  if valid_614433 != nil:
    section.add "GroupVersionId", valid_614433
  var valid_614434 = path.getOrDefault("GroupId")
  valid_614434 = validateParameter(valid_614434, JString, required = true,
                                 default = nil)
  if valid_614434 != nil:
    section.add "GroupId", valid_614434
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
  var valid_614435 = header.getOrDefault("X-Amz-Signature")
  valid_614435 = validateParameter(valid_614435, JString, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "X-Amz-Signature", valid_614435
  var valid_614436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "X-Amz-Content-Sha256", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-Date")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Date", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Credential")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Credential", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Security-Token")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Security-Token", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Algorithm")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Algorithm", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-SignedHeaders", valid_614441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614442: Call_GetGroupVersion_614430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_614442.validator(path, query, header, formData, body)
  let scheme = call_614442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614442.url(scheme.get, call_614442.host, call_614442.base,
                         call_614442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614442, url, valid)

proc call*(call_614443: Call_GetGroupVersion_614430; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_614444 = newJObject()
  add(path_614444, "GroupVersionId", newJString(GroupVersionId))
  add(path_614444, "GroupId", newJString(GroupId))
  result = call_614443.call(path_614444, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_614430(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_614431, base: "/", url: url_GetGroupVersion_614432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_614445 = ref object of OpenApiRestCall_612642
proc url_GetLoggerDefinitionVersion_614447(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLoggerDefinitionVersion_614446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614448 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_614448 = validateParameter(valid_614448, JString, required = true,
                                 default = nil)
  if valid_614448 != nil:
    section.add "LoggerDefinitionVersionId", valid_614448
  var valid_614449 = path.getOrDefault("LoggerDefinitionId")
  valid_614449 = validateParameter(valid_614449, JString, required = true,
                                 default = nil)
  if valid_614449 != nil:
    section.add "LoggerDefinitionId", valid_614449
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614450 = query.getOrDefault("NextToken")
  valid_614450 = validateParameter(valid_614450, JString, required = false,
                                 default = nil)
  if valid_614450 != nil:
    section.add "NextToken", valid_614450
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
  var valid_614451 = header.getOrDefault("X-Amz-Signature")
  valid_614451 = validateParameter(valid_614451, JString, required = false,
                                 default = nil)
  if valid_614451 != nil:
    section.add "X-Amz-Signature", valid_614451
  var valid_614452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Content-Sha256", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Date")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Date", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Credential")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Credential", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Security-Token")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Security-Token", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Algorithm")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Algorithm", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-SignedHeaders", valid_614457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614458: Call_GetLoggerDefinitionVersion_614445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_614458.validator(path, query, header, formData, body)
  let scheme = call_614458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614458.url(scheme.get, call_614458.host, call_614458.base,
                         call_614458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614458, url, valid)

proc call*(call_614459: Call_GetLoggerDefinitionVersion_614445;
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
  var path_614460 = newJObject()
  var query_614461 = newJObject()
  add(path_614460, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_614461, "NextToken", newJString(NextToken))
  add(path_614460, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_614459.call(path_614460, query_614461, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_614445(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_614446, base: "/",
    url: url_GetLoggerDefinitionVersion_614447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_614462 = ref object of OpenApiRestCall_612642
proc url_GetResourceDefinitionVersion_614464(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinitionVersion_614463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614465 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_614465 = validateParameter(valid_614465, JString, required = true,
                                 default = nil)
  if valid_614465 != nil:
    section.add "ResourceDefinitionVersionId", valid_614465
  var valid_614466 = path.getOrDefault("ResourceDefinitionId")
  valid_614466 = validateParameter(valid_614466, JString, required = true,
                                 default = nil)
  if valid_614466 != nil:
    section.add "ResourceDefinitionId", valid_614466
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
  var valid_614467 = header.getOrDefault("X-Amz-Signature")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "X-Amz-Signature", valid_614467
  var valid_614468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614468 = validateParameter(valid_614468, JString, required = false,
                                 default = nil)
  if valid_614468 != nil:
    section.add "X-Amz-Content-Sha256", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Date")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Date", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Credential")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Credential", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Security-Token")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Security-Token", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Algorithm")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Algorithm", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-SignedHeaders", valid_614473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614474: Call_GetResourceDefinitionVersion_614462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_614474.validator(path, query, header, formData, body)
  let scheme = call_614474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614474.url(scheme.get, call_614474.host, call_614474.base,
                         call_614474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614474, url, valid)

proc call*(call_614475: Call_GetResourceDefinitionVersion_614462;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_614476 = newJObject()
  add(path_614476, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_614476, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_614475.call(path_614476, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_614462(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_614463, base: "/",
    url: url_GetResourceDefinitionVersion_614464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_614477 = ref object of OpenApiRestCall_612642
proc url_GetSubscriptionDefinitionVersion_614479(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSubscriptionDefinitionVersion_614478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a subscription definition version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionDefinitionVersionId: JString (required)
  ##                                  : The ID of the subscription definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListSubscriptionDefinitionVersions'' requests. If the version is the last one that was associated with a subscription definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   SubscriptionDefinitionId: JString (required)
  ##                           : The ID of the subscription definition.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SubscriptionDefinitionVersionId` field"
  var valid_614480 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_614480 = validateParameter(valid_614480, JString, required = true,
                                 default = nil)
  if valid_614480 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_614480
  var valid_614481 = path.getOrDefault("SubscriptionDefinitionId")
  valid_614481 = validateParameter(valid_614481, JString, required = true,
                                 default = nil)
  if valid_614481 != nil:
    section.add "SubscriptionDefinitionId", valid_614481
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614482 = query.getOrDefault("NextToken")
  valid_614482 = validateParameter(valid_614482, JString, required = false,
                                 default = nil)
  if valid_614482 != nil:
    section.add "NextToken", valid_614482
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
  var valid_614483 = header.getOrDefault("X-Amz-Signature")
  valid_614483 = validateParameter(valid_614483, JString, required = false,
                                 default = nil)
  if valid_614483 != nil:
    section.add "X-Amz-Signature", valid_614483
  var valid_614484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "X-Amz-Content-Sha256", valid_614484
  var valid_614485 = header.getOrDefault("X-Amz-Date")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "X-Amz-Date", valid_614485
  var valid_614486 = header.getOrDefault("X-Amz-Credential")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Credential", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Security-Token")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Security-Token", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Algorithm")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Algorithm", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-SignedHeaders", valid_614489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614490: Call_GetSubscriptionDefinitionVersion_614477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_614490.validator(path, query, header, formData, body)
  let scheme = call_614490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614490.url(scheme.get, call_614490.host, call_614490.base,
                         call_614490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614490, url, valid)

proc call*(call_614491: Call_GetSubscriptionDefinitionVersion_614477;
          SubscriptionDefinitionVersionId: string;
          SubscriptionDefinitionId: string; NextToken: string = ""): Recallable =
  ## getSubscriptionDefinitionVersion
  ## Retrieves information about a subscription definition version.
  ##   SubscriptionDefinitionVersionId: string (required)
  ##                                  : The ID of the subscription definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListSubscriptionDefinitionVersions'' requests. If the version is the last one that was associated with a subscription definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_614492 = newJObject()
  var query_614493 = newJObject()
  add(path_614492, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_614493, "NextToken", newJString(NextToken))
  add(path_614492, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_614491.call(path_614492, query_614493, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_614477(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_614478, base: "/",
    url: url_GetSubscriptionDefinitionVersion_614479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_614494 = ref object of OpenApiRestCall_612642
proc url_ListBulkDeploymentDetailedReports_614496(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBulkDeploymentDetailedReports_614495(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614497 = path.getOrDefault("BulkDeploymentId")
  valid_614497 = validateParameter(valid_614497, JString, required = true,
                                 default = nil)
  if valid_614497 != nil:
    section.add "BulkDeploymentId", valid_614497
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614498 = query.getOrDefault("MaxResults")
  valid_614498 = validateParameter(valid_614498, JString, required = false,
                                 default = nil)
  if valid_614498 != nil:
    section.add "MaxResults", valid_614498
  var valid_614499 = query.getOrDefault("NextToken")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "NextToken", valid_614499
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
  var valid_614500 = header.getOrDefault("X-Amz-Signature")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-Signature", valid_614500
  var valid_614501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614501 = validateParameter(valid_614501, JString, required = false,
                                 default = nil)
  if valid_614501 != nil:
    section.add "X-Amz-Content-Sha256", valid_614501
  var valid_614502 = header.getOrDefault("X-Amz-Date")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "X-Amz-Date", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Credential")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Credential", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-Security-Token")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Security-Token", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Algorithm")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Algorithm", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-SignedHeaders", valid_614506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614507: Call_ListBulkDeploymentDetailedReports_614494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_614507.validator(path, query, header, formData, body)
  let scheme = call_614507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614507.url(scheme.get, call_614507.host, call_614507.base,
                         call_614507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614507, url, valid)

proc call*(call_614508: Call_ListBulkDeploymentDetailedReports_614494;
          BulkDeploymentId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_614509 = newJObject()
  var query_614510 = newJObject()
  add(query_614510, "MaxResults", newJString(MaxResults))
  add(query_614510, "NextToken", newJString(NextToken))
  add(path_614509, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_614508.call(path_614509, query_614510, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_614494(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_614495, base: "/",
    url: url_ListBulkDeploymentDetailedReports_614496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_614526 = ref object of OpenApiRestCall_612642
proc url_StartBulkDeployment_614528(protocol: Scheme; host: string; base: string;
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

proc validate_StartBulkDeployment_614527(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
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
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614529 = header.getOrDefault("X-Amz-Signature")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-Signature", valid_614529
  var valid_614530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614530 = validateParameter(valid_614530, JString, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "X-Amz-Content-Sha256", valid_614530
  var valid_614531 = header.getOrDefault("X-Amz-Date")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "X-Amz-Date", valid_614531
  var valid_614532 = header.getOrDefault("X-Amz-Credential")
  valid_614532 = validateParameter(valid_614532, JString, required = false,
                                 default = nil)
  if valid_614532 != nil:
    section.add "X-Amz-Credential", valid_614532
  var valid_614533 = header.getOrDefault("X-Amzn-Client-Token")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amzn-Client-Token", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Security-Token")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Security-Token", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-Algorithm")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-Algorithm", valid_614535
  var valid_614536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-SignedHeaders", valid_614536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614538: Call_StartBulkDeployment_614526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_614538.validator(path, query, header, formData, body)
  let scheme = call_614538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614538.url(scheme.get, call_614538.host, call_614538.base,
                         call_614538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614538, url, valid)

proc call*(call_614539: Call_StartBulkDeployment_614526; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_614540 = newJObject()
  if body != nil:
    body_614540 = body
  result = call_614539.call(nil, nil, nil, nil, body_614540)

var startBulkDeployment* = Call_StartBulkDeployment_614526(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_614527, base: "/",
    url: url_StartBulkDeployment_614528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_614511 = ref object of OpenApiRestCall_612642
proc url_ListBulkDeployments_614513(protocol: Scheme; host: string; base: string;
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

proc validate_ListBulkDeployments_614512(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of bulk deployments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_614514 = query.getOrDefault("MaxResults")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "MaxResults", valid_614514
  var valid_614515 = query.getOrDefault("NextToken")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "NextToken", valid_614515
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
  var valid_614516 = header.getOrDefault("X-Amz-Signature")
  valid_614516 = validateParameter(valid_614516, JString, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "X-Amz-Signature", valid_614516
  var valid_614517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614517 = validateParameter(valid_614517, JString, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "X-Amz-Content-Sha256", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Date")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Date", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Credential")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Credential", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-Security-Token")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-Security-Token", valid_614520
  var valid_614521 = header.getOrDefault("X-Amz-Algorithm")
  valid_614521 = validateParameter(valid_614521, JString, required = false,
                                 default = nil)
  if valid_614521 != nil:
    section.add "X-Amz-Algorithm", valid_614521
  var valid_614522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614522 = validateParameter(valid_614522, JString, required = false,
                                 default = nil)
  if valid_614522 != nil:
    section.add "X-Amz-SignedHeaders", valid_614522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614523: Call_ListBulkDeployments_614511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_614523.validator(path, query, header, formData, body)
  let scheme = call_614523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614523.url(scheme.get, call_614523.host, call_614523.base,
                         call_614523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614523, url, valid)

proc call*(call_614524: Call_ListBulkDeployments_614511; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_614525 = newJObject()
  add(query_614525, "MaxResults", newJString(MaxResults))
  add(query_614525, "NextToken", newJString(NextToken))
  result = call_614524.call(nil, query_614525, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_614511(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_614512, base: "/",
    url: url_ListBulkDeployments_614513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614555 = ref object of OpenApiRestCall_612642
proc url_TagResource_614557(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_614556(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614558 = path.getOrDefault("resource-arn")
  valid_614558 = validateParameter(valid_614558, JString, required = true,
                                 default = nil)
  if valid_614558 != nil:
    section.add "resource-arn", valid_614558
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
  var valid_614559 = header.getOrDefault("X-Amz-Signature")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Signature", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-Content-Sha256", valid_614560
  var valid_614561 = header.getOrDefault("X-Amz-Date")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-Date", valid_614561
  var valid_614562 = header.getOrDefault("X-Amz-Credential")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "X-Amz-Credential", valid_614562
  var valid_614563 = header.getOrDefault("X-Amz-Security-Token")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "X-Amz-Security-Token", valid_614563
  var valid_614564 = header.getOrDefault("X-Amz-Algorithm")
  valid_614564 = validateParameter(valid_614564, JString, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "X-Amz-Algorithm", valid_614564
  var valid_614565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "X-Amz-SignedHeaders", valid_614565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614567: Call_TagResource_614555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_614567.validator(path, query, header, formData, body)
  let scheme = call_614567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614567.url(scheme.get, call_614567.host, call_614567.base,
                         call_614567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614567, url, valid)

proc call*(call_614568: Call_TagResource_614555; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_614569 = newJObject()
  var body_614570 = newJObject()
  add(path_614569, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_614570 = body
  result = call_614568.call(path_614569, nil, nil, nil, body_614570)

var tagResource* = Call_TagResource_614555(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_614556,
                                        base: "/", url: url_TagResource_614557,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_614541 = ref object of OpenApiRestCall_612642
proc url_ListTagsForResource_614543(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_614542(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_614544 = path.getOrDefault("resource-arn")
  valid_614544 = validateParameter(valid_614544, JString, required = true,
                                 default = nil)
  if valid_614544 != nil:
    section.add "resource-arn", valid_614544
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
  var valid_614545 = header.getOrDefault("X-Amz-Signature")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-Signature", valid_614545
  var valid_614546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-Content-Sha256", valid_614546
  var valid_614547 = header.getOrDefault("X-Amz-Date")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-Date", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Credential")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Credential", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-Security-Token")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-Security-Token", valid_614549
  var valid_614550 = header.getOrDefault("X-Amz-Algorithm")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-Algorithm", valid_614550
  var valid_614551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-SignedHeaders", valid_614551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614552: Call_ListTagsForResource_614541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_614552.validator(path, query, header, formData, body)
  let scheme = call_614552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614552.url(scheme.get, call_614552.host, call_614552.base,
                         call_614552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614552, url, valid)

proc call*(call_614553: Call_ListTagsForResource_614541; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_614554 = newJObject()
  add(path_614554, "resource-arn", newJString(resourceArn))
  result = call_614553.call(path_614554, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_614541(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_614542, base: "/",
    url: url_ListTagsForResource_614543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_614571 = ref object of OpenApiRestCall_612642
proc url_ResetDeployments_614573(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ResetDeployments_614572(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a group's deployments.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupId: JString (required)
  ##          : The ID of the Greengrass group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupId` field"
  var valid_614574 = path.getOrDefault("GroupId")
  valid_614574 = validateParameter(valid_614574, JString, required = true,
                                 default = nil)
  if valid_614574 != nil:
    section.add "GroupId", valid_614574
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amzn-Client-Token: JString
  ##                      : A client token used to correlate requests and responses.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614575 = header.getOrDefault("X-Amz-Signature")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "X-Amz-Signature", valid_614575
  var valid_614576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614576 = validateParameter(valid_614576, JString, required = false,
                                 default = nil)
  if valid_614576 != nil:
    section.add "X-Amz-Content-Sha256", valid_614576
  var valid_614577 = header.getOrDefault("X-Amz-Date")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "X-Amz-Date", valid_614577
  var valid_614578 = header.getOrDefault("X-Amz-Credential")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "X-Amz-Credential", valid_614578
  var valid_614579 = header.getOrDefault("X-Amzn-Client-Token")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amzn-Client-Token", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Security-Token")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Security-Token", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Algorithm")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Algorithm", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-SignedHeaders", valid_614582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614584: Call_ResetDeployments_614571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_614584.validator(path, query, header, formData, body)
  let scheme = call_614584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614584.url(scheme.get, call_614584.host, call_614584.base,
                         call_614584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614584, url, valid)

proc call*(call_614585: Call_ResetDeployments_614571; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_614586 = newJObject()
  var body_614587 = newJObject()
  add(path_614586, "GroupId", newJString(GroupId))
  if body != nil:
    body_614587 = body
  result = call_614585.call(path_614586, nil, nil, nil, body_614587)

var resetDeployments* = Call_ResetDeployments_614571(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_614572, base: "/",
    url: url_ResetDeployments_614573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_614588 = ref object of OpenApiRestCall_612642
proc url_StopBulkDeployment_614590(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopBulkDeployment_614589(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_614591 = path.getOrDefault("BulkDeploymentId")
  valid_614591 = validateParameter(valid_614591, JString, required = true,
                                 default = nil)
  if valid_614591 != nil:
    section.add "BulkDeploymentId", valid_614591
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
  var valid_614592 = header.getOrDefault("X-Amz-Signature")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "X-Amz-Signature", valid_614592
  var valid_614593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614593 = validateParameter(valid_614593, JString, required = false,
                                 default = nil)
  if valid_614593 != nil:
    section.add "X-Amz-Content-Sha256", valid_614593
  var valid_614594 = header.getOrDefault("X-Amz-Date")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Date", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Credential")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Credential", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Security-Token")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Security-Token", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Algorithm")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Algorithm", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-SignedHeaders", valid_614598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614599: Call_StopBulkDeployment_614588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_614599.validator(path, query, header, formData, body)
  let scheme = call_614599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614599.url(scheme.get, call_614599.host, call_614599.base,
                         call_614599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614599, url, valid)

proc call*(call_614600: Call_StopBulkDeployment_614588; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_614601 = newJObject()
  add(path_614601, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_614600.call(path_614601, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_614588(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_614589, base: "/",
    url: url_StopBulkDeployment_614590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614602 = ref object of OpenApiRestCall_612642
proc url_UntagResource_614604(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_614603(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_614605 = path.getOrDefault("resource-arn")
  valid_614605 = validateParameter(valid_614605, JString, required = true,
                                 default = nil)
  if valid_614605 != nil:
    section.add "resource-arn", valid_614605
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_614606 = query.getOrDefault("tagKeys")
  valid_614606 = validateParameter(valid_614606, JArray, required = true, default = nil)
  if valid_614606 != nil:
    section.add "tagKeys", valid_614606
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
  var valid_614607 = header.getOrDefault("X-Amz-Signature")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Signature", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-Content-Sha256", valid_614608
  var valid_614609 = header.getOrDefault("X-Amz-Date")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "X-Amz-Date", valid_614609
  var valid_614610 = header.getOrDefault("X-Amz-Credential")
  valid_614610 = validateParameter(valid_614610, JString, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "X-Amz-Credential", valid_614610
  var valid_614611 = header.getOrDefault("X-Amz-Security-Token")
  valid_614611 = validateParameter(valid_614611, JString, required = false,
                                 default = nil)
  if valid_614611 != nil:
    section.add "X-Amz-Security-Token", valid_614611
  var valid_614612 = header.getOrDefault("X-Amz-Algorithm")
  valid_614612 = validateParameter(valid_614612, JString, required = false,
                                 default = nil)
  if valid_614612 != nil:
    section.add "X-Amz-Algorithm", valid_614612
  var valid_614613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614613 = validateParameter(valid_614613, JString, required = false,
                                 default = nil)
  if valid_614613 != nil:
    section.add "X-Amz-SignedHeaders", valid_614613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614614: Call_UntagResource_614602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_614614.validator(path, query, header, formData, body)
  let scheme = call_614614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614614.url(scheme.get, call_614614.host, call_614614.base,
                         call_614614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614614, url, valid)

proc call*(call_614615: Call_UntagResource_614602; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_614616 = newJObject()
  var query_614617 = newJObject()
  add(path_614616, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_614617.add "tagKeys", tagKeys
  result = call_614615.call(path_614616, query_614617, nil, nil, nil)

var untagResource* = Call_UntagResource_614602(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_614603,
    base: "/", url: url_UntagResource_614604, schemes: {Scheme.Https, Scheme.Http})
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
