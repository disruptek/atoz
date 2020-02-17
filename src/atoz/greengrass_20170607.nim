
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRoleToGroup_611250 = ref object of OpenApiRestCall_610642
proc url_AssociateRoleToGroup_611252(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRoleToGroup_611251(path: JsonNode; query: JsonNode;
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
  var valid_611253 = path.getOrDefault("GroupId")
  valid_611253 = validateParameter(valid_611253, JString, required = true,
                                 default = nil)
  if valid_611253 != nil:
    section.add "GroupId", valid_611253
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
  var valid_611254 = header.getOrDefault("X-Amz-Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Signature", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Content-Sha256", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Date")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Date", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Credential")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Credential", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Security-Token")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Security-Token", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Algorithm")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Algorithm", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-SignedHeaders", valid_611260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_AssociateRoleToGroup_611250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_AssociateRoleToGroup_611250; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_611264 = newJObject()
  var body_611265 = newJObject()
  add(path_611264, "GroupId", newJString(GroupId))
  if body != nil:
    body_611265 = body
  result = call_611263.call(path_611264, nil, nil, nil, body_611265)

var associateRoleToGroup* = Call_AssociateRoleToGroup_611250(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_611251, base: "/",
    url: url_AssociateRoleToGroup_611252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_610980 = ref object of OpenApiRestCall_610642
proc url_GetAssociatedRole_610982(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssociatedRole_610981(path: JsonNode; query: JsonNode;
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
  var valid_611108 = path.getOrDefault("GroupId")
  valid_611108 = validateParameter(valid_611108, JString, required = true,
                                 default = nil)
  if valid_611108 != nil:
    section.add "GroupId", valid_611108
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
  var valid_611109 = header.getOrDefault("X-Amz-Signature")
  valid_611109 = validateParameter(valid_611109, JString, required = false,
                                 default = nil)
  if valid_611109 != nil:
    section.add "X-Amz-Signature", valid_611109
  var valid_611110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Content-Sha256", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Date")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Date", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Credential")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Credential", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Security-Token")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Security-Token", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Algorithm")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Algorithm", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-SignedHeaders", valid_611115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611138: Call_GetAssociatedRole_610980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_611138.validator(path, query, header, formData, body)
  let scheme = call_611138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611138.url(scheme.get, call_611138.host, call_611138.base,
                         call_611138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611138, url, valid)

proc call*(call_611209: Call_GetAssociatedRole_610980; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_611210 = newJObject()
  add(path_611210, "GroupId", newJString(GroupId))
  result = call_611209.call(path_611210, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_610980(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_610981, base: "/",
    url: url_GetAssociatedRole_610982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_611266 = ref object of OpenApiRestCall_610642
proc url_DisassociateRoleFromGroup_611268(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_611267(path: JsonNode; query: JsonNode;
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
  var valid_611269 = path.getOrDefault("GroupId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "GroupId", valid_611269
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
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_DisassociateRoleFromGroup_611266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_DisassociateRoleFromGroup_611266; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_611279 = newJObject()
  add(path_611279, "GroupId", newJString(GroupId))
  result = call_611278.call(path_611279, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_611266(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_611267, base: "/",
    url: url_DisassociateRoleFromGroup_611268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_611292 = ref object of OpenApiRestCall_610642
proc url_AssociateServiceRoleToAccount_611294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceRoleToAccount_611293(path: JsonNode; query: JsonNode;
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
  var valid_611295 = header.getOrDefault("X-Amz-Signature")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Signature", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Content-Sha256", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Date")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Date", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Credential")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Credential", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Security-Token")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Security-Token", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Algorithm")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Algorithm", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-SignedHeaders", valid_611301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611303: Call_AssociateServiceRoleToAccount_611292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_611303.validator(path, query, header, formData, body)
  let scheme = call_611303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611303.url(scheme.get, call_611303.host, call_611303.base,
                         call_611303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611303, url, valid)

proc call*(call_611304: Call_AssociateServiceRoleToAccount_611292; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_611305 = newJObject()
  if body != nil:
    body_611305 = body
  result = call_611304.call(nil, nil, nil, nil, body_611305)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_611292(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_611293, base: "/",
    url: url_AssociateServiceRoleToAccount_611294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_611280 = ref object of OpenApiRestCall_610642
proc url_GetServiceRoleForAccount_611282(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceRoleForAccount_611281(path: JsonNode; query: JsonNode;
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
  var valid_611283 = header.getOrDefault("X-Amz-Signature")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Signature", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Content-Sha256", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Date")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Date", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Credential")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Credential", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Security-Token")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Security-Token", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Algorithm")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Algorithm", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-SignedHeaders", valid_611289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611290: Call_GetServiceRoleForAccount_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_611290.validator(path, query, header, formData, body)
  let scheme = call_611290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611290.url(scheme.get, call_611290.host, call_611290.base,
                         call_611290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611290, url, valid)

proc call*(call_611291: Call_GetServiceRoleForAccount_611280): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_611291.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_611280(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_611281, base: "/",
    url: url_GetServiceRoleForAccount_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_611306 = ref object of OpenApiRestCall_610642
proc url_DisassociateServiceRoleFromAccount_611308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_611307(path: JsonNode;
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
  var valid_611309 = header.getOrDefault("X-Amz-Signature")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Signature", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Content-Sha256", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Date")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Date", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Credential")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Credential", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Security-Token")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Security-Token", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Algorithm")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Algorithm", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-SignedHeaders", valid_611315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611316: Call_DisassociateServiceRoleFromAccount_611306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_611316.validator(path, query, header, formData, body)
  let scheme = call_611316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611316.url(scheme.get, call_611316.host, call_611316.base,
                         call_611316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611316, url, valid)

proc call*(call_611317: Call_DisassociateServiceRoleFromAccount_611306): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_611317.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_611306(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_611307, base: "/",
    url: url_DisassociateServiceRoleFromAccount_611308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_611333 = ref object of OpenApiRestCall_610642
proc url_CreateConnectorDefinition_611335(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnectorDefinition_611334(path: JsonNode; query: JsonNode;
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
  var valid_611336 = header.getOrDefault("X-Amz-Signature")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Signature", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Content-Sha256", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Date")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Date", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Credential")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Credential", valid_611339
  var valid_611340 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amzn-Client-Token", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_CreateConnectorDefinition_611333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_CreateConnectorDefinition_611333; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_611347 = newJObject()
  if body != nil:
    body_611347 = body
  result = call_611346.call(nil, nil, nil, nil, body_611347)

var createConnectorDefinition* = Call_CreateConnectorDefinition_611333(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_611334, base: "/",
    url: url_CreateConnectorDefinition_611335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_611318 = ref object of OpenApiRestCall_610642
proc url_ListConnectorDefinitions_611320(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnectorDefinitions_611319(path: JsonNode; query: JsonNode;
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
  var valid_611321 = query.getOrDefault("MaxResults")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "MaxResults", valid_611321
  var valid_611322 = query.getOrDefault("NextToken")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "NextToken", valid_611322
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
  var valid_611323 = header.getOrDefault("X-Amz-Signature")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Signature", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Content-Sha256", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Date")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Date", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Credential")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Credential", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Security-Token")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Security-Token", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Algorithm")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Algorithm", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-SignedHeaders", valid_611329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611330: Call_ListConnectorDefinitions_611318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_611330.validator(path, query, header, formData, body)
  let scheme = call_611330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611330.url(scheme.get, call_611330.host, call_611330.base,
                         call_611330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611330, url, valid)

proc call*(call_611331: Call_ListConnectorDefinitions_611318;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611332 = newJObject()
  add(query_611332, "MaxResults", newJString(MaxResults))
  add(query_611332, "NextToken", newJString(NextToken))
  result = call_611331.call(nil, query_611332, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_611318(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_611319, base: "/",
    url: url_ListConnectorDefinitions_611320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_611365 = ref object of OpenApiRestCall_610642
proc url_CreateConnectorDefinitionVersion_611367(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinitionVersion_611366(path: JsonNode;
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
  var valid_611368 = path.getOrDefault("ConnectorDefinitionId")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = nil)
  if valid_611368 != nil:
    section.add "ConnectorDefinitionId", valid_611368
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
  var valid_611369 = header.getOrDefault("X-Amz-Signature")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Signature", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Content-Sha256", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Date")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Date", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Credential")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Credential", valid_611372
  var valid_611373 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amzn-Client-Token", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611378: Call_CreateConnectorDefinitionVersion_611365;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_611378.validator(path, query, header, formData, body)
  let scheme = call_611378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611378.url(scheme.get, call_611378.host, call_611378.base,
                         call_611378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611378, url, valid)

proc call*(call_611379: Call_CreateConnectorDefinitionVersion_611365;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_611380 = newJObject()
  var body_611381 = newJObject()
  add(path_611380, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_611381 = body
  result = call_611379.call(path_611380, nil, nil, nil, body_611381)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_611365(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_611366, base: "/",
    url: url_CreateConnectorDefinitionVersion_611367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_611348 = ref object of OpenApiRestCall_610642
proc url_ListConnectorDefinitionVersions_611350(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitionVersions_611349(path: JsonNode;
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
  var valid_611351 = path.getOrDefault("ConnectorDefinitionId")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "ConnectorDefinitionId", valid_611351
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611352 = query.getOrDefault("MaxResults")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "MaxResults", valid_611352
  var valid_611353 = query.getOrDefault("NextToken")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "NextToken", valid_611353
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
  var valid_611354 = header.getOrDefault("X-Amz-Signature")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Signature", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Content-Sha256", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Date")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Date", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Credential")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Credential", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Security-Token")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Security-Token", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Algorithm")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Algorithm", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-SignedHeaders", valid_611360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_ListConnectorDefinitionVersions_611348;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_ListConnectorDefinitionVersions_611348;
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
  var path_611363 = newJObject()
  var query_611364 = newJObject()
  add(query_611364, "MaxResults", newJString(MaxResults))
  add(query_611364, "NextToken", newJString(NextToken))
  add(path_611363, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_611362.call(path_611363, query_611364, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_611348(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_611349, base: "/",
    url: url_ListConnectorDefinitionVersions_611350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_611397 = ref object of OpenApiRestCall_610642
proc url_CreateCoreDefinition_611399(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCoreDefinition_611398(path: JsonNode; query: JsonNode;
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
  var valid_611400 = header.getOrDefault("X-Amz-Signature")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Signature", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Content-Sha256", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Date")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Date", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Credential")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Credential", valid_611403
  var valid_611404 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amzn-Client-Token", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Security-Token")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Security-Token", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Algorithm")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Algorithm", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-SignedHeaders", valid_611407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611409: Call_CreateCoreDefinition_611397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_611409.validator(path, query, header, formData, body)
  let scheme = call_611409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611409.url(scheme.get, call_611409.host, call_611409.base,
                         call_611409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611409, url, valid)

proc call*(call_611410: Call_CreateCoreDefinition_611397; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_611411 = newJObject()
  if body != nil:
    body_611411 = body
  result = call_611410.call(nil, nil, nil, nil, body_611411)

var createCoreDefinition* = Call_CreateCoreDefinition_611397(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_611398, base: "/",
    url: url_CreateCoreDefinition_611399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_611382 = ref object of OpenApiRestCall_610642
proc url_ListCoreDefinitions_611384(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCoreDefinitions_611383(path: JsonNode; query: JsonNode;
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
  var valid_611385 = query.getOrDefault("MaxResults")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "MaxResults", valid_611385
  var valid_611386 = query.getOrDefault("NextToken")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "NextToken", valid_611386
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
  var valid_611387 = header.getOrDefault("X-Amz-Signature")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Signature", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Content-Sha256", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Date")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Date", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Credential")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Credential", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Security-Token")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Security-Token", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Algorithm")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Algorithm", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-SignedHeaders", valid_611393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611394: Call_ListCoreDefinitions_611382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_611394.validator(path, query, header, formData, body)
  let scheme = call_611394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611394.url(scheme.get, call_611394.host, call_611394.base,
                         call_611394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611394, url, valid)

proc call*(call_611395: Call_ListCoreDefinitions_611382; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611396 = newJObject()
  add(query_611396, "MaxResults", newJString(MaxResults))
  add(query_611396, "NextToken", newJString(NextToken))
  result = call_611395.call(nil, query_611396, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_611382(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_611383, base: "/",
    url: url_ListCoreDefinitions_611384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_611429 = ref object of OpenApiRestCall_610642
proc url_CreateCoreDefinitionVersion_611431(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_611430(path: JsonNode; query: JsonNode;
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
  var valid_611432 = path.getOrDefault("CoreDefinitionId")
  valid_611432 = validateParameter(valid_611432, JString, required = true,
                                 default = nil)
  if valid_611432 != nil:
    section.add "CoreDefinitionId", valid_611432
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
  var valid_611433 = header.getOrDefault("X-Amz-Signature")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Signature", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Content-Sha256", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Date")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Date", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Credential")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Credential", valid_611436
  var valid_611437 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amzn-Client-Token", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CreateCoreDefinitionVersion_611429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CreateCoreDefinitionVersion_611429;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_611444 = newJObject()
  var body_611445 = newJObject()
  add(path_611444, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_611445 = body
  result = call_611443.call(path_611444, nil, nil, nil, body_611445)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_611429(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_611430, base: "/",
    url: url_CreateCoreDefinitionVersion_611431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_611412 = ref object of OpenApiRestCall_610642
proc url_ListCoreDefinitionVersions_611414(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_611413(path: JsonNode; query: JsonNode;
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
  var valid_611415 = path.getOrDefault("CoreDefinitionId")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "CoreDefinitionId", valid_611415
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611416 = query.getOrDefault("MaxResults")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "MaxResults", valid_611416
  var valid_611417 = query.getOrDefault("NextToken")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "NextToken", valid_611417
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
  var valid_611418 = header.getOrDefault("X-Amz-Signature")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Signature", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Content-Sha256", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Date")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Date", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Credential")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Credential", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Security-Token")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Security-Token", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Algorithm")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Algorithm", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-SignedHeaders", valid_611424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611425: Call_ListCoreDefinitionVersions_611412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_611425.validator(path, query, header, formData, body)
  let scheme = call_611425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611425.url(scheme.get, call_611425.host, call_611425.base,
                         call_611425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611425, url, valid)

proc call*(call_611426: Call_ListCoreDefinitionVersions_611412;
          CoreDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_611427 = newJObject()
  var query_611428 = newJObject()
  add(query_611428, "MaxResults", newJString(MaxResults))
  add(query_611428, "NextToken", newJString(NextToken))
  add(path_611427, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_611426.call(path_611427, query_611428, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_611412(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_611413, base: "/",
    url: url_ListCoreDefinitionVersions_611414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_611463 = ref object of OpenApiRestCall_610642
proc url_CreateDeployment_611465(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_611464(path: JsonNode; query: JsonNode;
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
  var valid_611466 = path.getOrDefault("GroupId")
  valid_611466 = validateParameter(valid_611466, JString, required = true,
                                 default = nil)
  if valid_611466 != nil:
    section.add "GroupId", valid_611466
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
  var valid_611467 = header.getOrDefault("X-Amz-Signature")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Signature", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Content-Sha256", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Date")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Date", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Credential")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Credential", valid_611470
  var valid_611471 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amzn-Client-Token", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Security-Token")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Security-Token", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Algorithm")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Algorithm", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-SignedHeaders", valid_611474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_CreateDeployment_611463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_CreateDeployment_611463; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_611478 = newJObject()
  var body_611479 = newJObject()
  add(path_611478, "GroupId", newJString(GroupId))
  if body != nil:
    body_611479 = body
  result = call_611477.call(path_611478, nil, nil, nil, body_611479)

var createDeployment* = Call_CreateDeployment_611463(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_611464, base: "/",
    url: url_CreateDeployment_611465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_611446 = ref object of OpenApiRestCall_610642
proc url_ListDeployments_611448(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_611447(path: JsonNode; query: JsonNode;
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
  var valid_611449 = path.getOrDefault("GroupId")
  valid_611449 = validateParameter(valid_611449, JString, required = true,
                                 default = nil)
  if valid_611449 != nil:
    section.add "GroupId", valid_611449
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611450 = query.getOrDefault("MaxResults")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "MaxResults", valid_611450
  var valid_611451 = query.getOrDefault("NextToken")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "NextToken", valid_611451
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
  var valid_611452 = header.getOrDefault("X-Amz-Signature")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Signature", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Content-Sha256", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Date")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Date", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Credential")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Credential", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Security-Token")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Security-Token", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Algorithm")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Algorithm", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-SignedHeaders", valid_611458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611459: Call_ListDeployments_611446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_611459.validator(path, query, header, formData, body)
  let scheme = call_611459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611459.url(scheme.get, call_611459.host, call_611459.base,
                         call_611459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611459, url, valid)

proc call*(call_611460: Call_ListDeployments_611446; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_611461 = newJObject()
  var query_611462 = newJObject()
  add(path_611461, "GroupId", newJString(GroupId))
  add(query_611462, "MaxResults", newJString(MaxResults))
  add(query_611462, "NextToken", newJString(NextToken))
  result = call_611460.call(path_611461, query_611462, nil, nil, nil)

var listDeployments* = Call_ListDeployments_611446(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_611447, base: "/", url: url_ListDeployments_611448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_611495 = ref object of OpenApiRestCall_610642
proc url_CreateDeviceDefinition_611497(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeviceDefinition_611496(path: JsonNode; query: JsonNode;
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
  var valid_611498 = header.getOrDefault("X-Amz-Signature")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Signature", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Content-Sha256", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Date")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Date", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Credential")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Credential", valid_611501
  var valid_611502 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amzn-Client-Token", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Security-Token")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Security-Token", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Algorithm")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Algorithm", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-SignedHeaders", valid_611505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611507: Call_CreateDeviceDefinition_611495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_611507.validator(path, query, header, formData, body)
  let scheme = call_611507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611507.url(scheme.get, call_611507.host, call_611507.base,
                         call_611507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611507, url, valid)

proc call*(call_611508: Call_CreateDeviceDefinition_611495; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_611509 = newJObject()
  if body != nil:
    body_611509 = body
  result = call_611508.call(nil, nil, nil, nil, body_611509)

var createDeviceDefinition* = Call_CreateDeviceDefinition_611495(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_611496, base: "/",
    url: url_CreateDeviceDefinition_611497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_611480 = ref object of OpenApiRestCall_610642
proc url_ListDeviceDefinitions_611482(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceDefinitions_611481(path: JsonNode; query: JsonNode;
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
  var valid_611483 = query.getOrDefault("MaxResults")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "MaxResults", valid_611483
  var valid_611484 = query.getOrDefault("NextToken")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "NextToken", valid_611484
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
  var valid_611485 = header.getOrDefault("X-Amz-Signature")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Signature", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Content-Sha256", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Date")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Date", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Credential")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Credential", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Security-Token")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Security-Token", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Algorithm")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Algorithm", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-SignedHeaders", valid_611491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611492: Call_ListDeviceDefinitions_611480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_611492.validator(path, query, header, formData, body)
  let scheme = call_611492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611492.url(scheme.get, call_611492.host, call_611492.base,
                         call_611492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611492, url, valid)

proc call*(call_611493: Call_ListDeviceDefinitions_611480; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611494 = newJObject()
  add(query_611494, "MaxResults", newJString(MaxResults))
  add(query_611494, "NextToken", newJString(NextToken))
  result = call_611493.call(nil, query_611494, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_611480(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_611481, base: "/",
    url: url_ListDeviceDefinitions_611482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_611527 = ref object of OpenApiRestCall_610642
proc url_CreateDeviceDefinitionVersion_611529(protocol: Scheme; host: string;
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

proc validate_CreateDeviceDefinitionVersion_611528(path: JsonNode; query: JsonNode;
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
  var valid_611530 = path.getOrDefault("DeviceDefinitionId")
  valid_611530 = validateParameter(valid_611530, JString, required = true,
                                 default = nil)
  if valid_611530 != nil:
    section.add "DeviceDefinitionId", valid_611530
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
  var valid_611531 = header.getOrDefault("X-Amz-Signature")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Signature", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Content-Sha256", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Date")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Date", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Credential")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Credential", valid_611534
  var valid_611535 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amzn-Client-Token", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Security-Token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Security-Token", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Algorithm")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Algorithm", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-SignedHeaders", valid_611538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611540: Call_CreateDeviceDefinitionVersion_611527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_611540.validator(path, query, header, formData, body)
  let scheme = call_611540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611540.url(scheme.get, call_611540.host, call_611540.base,
                         call_611540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611540, url, valid)

proc call*(call_611541: Call_CreateDeviceDefinitionVersion_611527;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_611542 = newJObject()
  var body_611543 = newJObject()
  add(path_611542, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_611543 = body
  result = call_611541.call(path_611542, nil, nil, nil, body_611543)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_611527(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_611528, base: "/",
    url: url_CreateDeviceDefinitionVersion_611529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_611510 = ref object of OpenApiRestCall_610642
proc url_ListDeviceDefinitionVersions_611512(protocol: Scheme; host: string;
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

proc validate_ListDeviceDefinitionVersions_611511(path: JsonNode; query: JsonNode;
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
  var valid_611513 = path.getOrDefault("DeviceDefinitionId")
  valid_611513 = validateParameter(valid_611513, JString, required = true,
                                 default = nil)
  if valid_611513 != nil:
    section.add "DeviceDefinitionId", valid_611513
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611514 = query.getOrDefault("MaxResults")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "MaxResults", valid_611514
  var valid_611515 = query.getOrDefault("NextToken")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "NextToken", valid_611515
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
  var valid_611516 = header.getOrDefault("X-Amz-Signature")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Signature", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Content-Sha256", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Date")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Date", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Credential")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Credential", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Security-Token")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Security-Token", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Algorithm")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Algorithm", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-SignedHeaders", valid_611522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611523: Call_ListDeviceDefinitionVersions_611510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_611523.validator(path, query, header, formData, body)
  let scheme = call_611523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611523.url(scheme.get, call_611523.host, call_611523.base,
                         call_611523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611523, url, valid)

proc call*(call_611524: Call_ListDeviceDefinitionVersions_611510;
          DeviceDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_611525 = newJObject()
  var query_611526 = newJObject()
  add(path_611525, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_611526, "MaxResults", newJString(MaxResults))
  add(query_611526, "NextToken", newJString(NextToken))
  result = call_611524.call(path_611525, query_611526, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_611510(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_611511, base: "/",
    url: url_ListDeviceDefinitionVersions_611512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_611559 = ref object of OpenApiRestCall_610642
proc url_CreateFunctionDefinition_611561(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunctionDefinition_611560(path: JsonNode; query: JsonNode;
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
  var valid_611562 = header.getOrDefault("X-Amz-Signature")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Signature", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Content-Sha256", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Date")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Date", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Credential")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Credential", valid_611565
  var valid_611566 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amzn-Client-Token", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Security-Token")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Security-Token", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Algorithm")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Algorithm", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-SignedHeaders", valid_611569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611571: Call_CreateFunctionDefinition_611559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_611571.validator(path, query, header, formData, body)
  let scheme = call_611571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611571.url(scheme.get, call_611571.host, call_611571.base,
                         call_611571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611571, url, valid)

proc call*(call_611572: Call_CreateFunctionDefinition_611559; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_611573 = newJObject()
  if body != nil:
    body_611573 = body
  result = call_611572.call(nil, nil, nil, nil, body_611573)

var createFunctionDefinition* = Call_CreateFunctionDefinition_611559(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_611560, base: "/",
    url: url_CreateFunctionDefinition_611561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_611544 = ref object of OpenApiRestCall_610642
proc url_ListFunctionDefinitions_611546(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctionDefinitions_611545(path: JsonNode; query: JsonNode;
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
  var valid_611547 = query.getOrDefault("MaxResults")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "MaxResults", valid_611547
  var valid_611548 = query.getOrDefault("NextToken")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "NextToken", valid_611548
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
  var valid_611549 = header.getOrDefault("X-Amz-Signature")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Signature", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Content-Sha256", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Date")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Date", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Credential")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Credential", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Security-Token")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Security-Token", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Algorithm")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Algorithm", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-SignedHeaders", valid_611555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611556: Call_ListFunctionDefinitions_611544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_611556.validator(path, query, header, formData, body)
  let scheme = call_611556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611556.url(scheme.get, call_611556.host, call_611556.base,
                         call_611556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611556, url, valid)

proc call*(call_611557: Call_ListFunctionDefinitions_611544;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611558 = newJObject()
  add(query_611558, "MaxResults", newJString(MaxResults))
  add(query_611558, "NextToken", newJString(NextToken))
  result = call_611557.call(nil, query_611558, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_611544(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_611545, base: "/",
    url: url_ListFunctionDefinitions_611546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_611591 = ref object of OpenApiRestCall_610642
proc url_CreateFunctionDefinitionVersion_611593(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinitionVersion_611592(path: JsonNode;
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
  var valid_611594 = path.getOrDefault("FunctionDefinitionId")
  valid_611594 = validateParameter(valid_611594, JString, required = true,
                                 default = nil)
  if valid_611594 != nil:
    section.add "FunctionDefinitionId", valid_611594
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
  var valid_611595 = header.getOrDefault("X-Amz-Signature")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Signature", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Content-Sha256", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Date")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Date", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Credential")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Credential", valid_611598
  var valid_611599 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amzn-Client-Token", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Algorithm")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Algorithm", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-SignedHeaders", valid_611602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_CreateFunctionDefinitionVersion_611591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_CreateFunctionDefinitionVersion_611591;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_611606 = newJObject()
  var body_611607 = newJObject()
  add(path_611606, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_611607 = body
  result = call_611605.call(path_611606, nil, nil, nil, body_611607)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_611591(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_611592, base: "/",
    url: url_CreateFunctionDefinitionVersion_611593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_611574 = ref object of OpenApiRestCall_610642
proc url_ListFunctionDefinitionVersions_611576(protocol: Scheme; host: string;
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

proc validate_ListFunctionDefinitionVersions_611575(path: JsonNode;
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
  var valid_611577 = path.getOrDefault("FunctionDefinitionId")
  valid_611577 = validateParameter(valid_611577, JString, required = true,
                                 default = nil)
  if valid_611577 != nil:
    section.add "FunctionDefinitionId", valid_611577
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611578 = query.getOrDefault("MaxResults")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "MaxResults", valid_611578
  var valid_611579 = query.getOrDefault("NextToken")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "NextToken", valid_611579
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
  var valid_611580 = header.getOrDefault("X-Amz-Signature")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Signature", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Content-Sha256", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Date")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Date", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Credential")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Credential", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Security-Token")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Security-Token", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Algorithm")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Algorithm", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-SignedHeaders", valid_611586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611587: Call_ListFunctionDefinitionVersions_611574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_611587.validator(path, query, header, formData, body)
  let scheme = call_611587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611587.url(scheme.get, call_611587.host, call_611587.base,
                         call_611587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611587, url, valid)

proc call*(call_611588: Call_ListFunctionDefinitionVersions_611574;
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
  var path_611589 = newJObject()
  var query_611590 = newJObject()
  add(query_611590, "MaxResults", newJString(MaxResults))
  add(query_611590, "NextToken", newJString(NextToken))
  add(path_611589, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_611588.call(path_611589, query_611590, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_611574(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_611575, base: "/",
    url: url_ListFunctionDefinitionVersions_611576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_611623 = ref object of OpenApiRestCall_610642
proc url_CreateGroup_611625(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_611624(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611626 = header.getOrDefault("X-Amz-Signature")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Signature", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Content-Sha256", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Date")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Date", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Credential")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Credential", valid_611629
  var valid_611630 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amzn-Client-Token", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Security-Token")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Security-Token", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Algorithm")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Algorithm", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-SignedHeaders", valid_611633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611635: Call_CreateGroup_611623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_611635.validator(path, query, header, formData, body)
  let scheme = call_611635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611635.url(scheme.get, call_611635.host, call_611635.base,
                         call_611635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611635, url, valid)

proc call*(call_611636: Call_CreateGroup_611623; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_611637 = newJObject()
  if body != nil:
    body_611637 = body
  result = call_611636.call(nil, nil, nil, nil, body_611637)

var createGroup* = Call_CreateGroup_611623(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_611624,
                                        base: "/", url: url_CreateGroup_611625,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_611608 = ref object of OpenApiRestCall_610642
proc url_ListGroups_611610(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_611609(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611611 = query.getOrDefault("MaxResults")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "MaxResults", valid_611611
  var valid_611612 = query.getOrDefault("NextToken")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "NextToken", valid_611612
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
  var valid_611613 = header.getOrDefault("X-Amz-Signature")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Signature", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Content-Sha256", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Date")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Date", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Credential")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Credential", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Security-Token")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Security-Token", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Algorithm")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Algorithm", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-SignedHeaders", valid_611619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611620: Call_ListGroups_611608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_611620.validator(path, query, header, formData, body)
  let scheme = call_611620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611620.url(scheme.get, call_611620.host, call_611620.base,
                         call_611620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611620, url, valid)

proc call*(call_611621: Call_ListGroups_611608; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611622 = newJObject()
  add(query_611622, "MaxResults", newJString(MaxResults))
  add(query_611622, "NextToken", newJString(NextToken))
  result = call_611621.call(nil, query_611622, nil, nil, nil)

var listGroups* = Call_ListGroups_611608(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_611609,
                                      base: "/", url: url_ListGroups_611610,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_611652 = ref object of OpenApiRestCall_610642
proc url_CreateGroupCertificateAuthority_611654(protocol: Scheme; host: string;
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

proc validate_CreateGroupCertificateAuthority_611653(path: JsonNode;
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
  var valid_611655 = path.getOrDefault("GroupId")
  valid_611655 = validateParameter(valid_611655, JString, required = true,
                                 default = nil)
  if valid_611655 != nil:
    section.add "GroupId", valid_611655
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
  var valid_611656 = header.getOrDefault("X-Amz-Signature")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Signature", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Content-Sha256", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Date")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Date", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Credential")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Credential", valid_611659
  var valid_611660 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amzn-Client-Token", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Security-Token")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Security-Token", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Algorithm")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Algorithm", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-SignedHeaders", valid_611663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611664: Call_CreateGroupCertificateAuthority_611652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_611664.validator(path, query, header, formData, body)
  let scheme = call_611664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611664.url(scheme.get, call_611664.host, call_611664.base,
                         call_611664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611664, url, valid)

proc call*(call_611665: Call_CreateGroupCertificateAuthority_611652;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_611666 = newJObject()
  add(path_611666, "GroupId", newJString(GroupId))
  result = call_611665.call(path_611666, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_611652(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_611653, base: "/",
    url: url_CreateGroupCertificateAuthority_611654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_611638 = ref object of OpenApiRestCall_610642
proc url_ListGroupCertificateAuthorities_611640(protocol: Scheme; host: string;
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

proc validate_ListGroupCertificateAuthorities_611639(path: JsonNode;
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
  var valid_611641 = path.getOrDefault("GroupId")
  valid_611641 = validateParameter(valid_611641, JString, required = true,
                                 default = nil)
  if valid_611641 != nil:
    section.add "GroupId", valid_611641
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
  var valid_611642 = header.getOrDefault("X-Amz-Signature")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Signature", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Content-Sha256", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Date")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Date", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Credential")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Credential", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Security-Token")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Security-Token", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Algorithm")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Algorithm", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-SignedHeaders", valid_611648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611649: Call_ListGroupCertificateAuthorities_611638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_611649.validator(path, query, header, formData, body)
  let scheme = call_611649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611649.url(scheme.get, call_611649.host, call_611649.base,
                         call_611649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611649, url, valid)

proc call*(call_611650: Call_ListGroupCertificateAuthorities_611638;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_611651 = newJObject()
  add(path_611651, "GroupId", newJString(GroupId))
  result = call_611650.call(path_611651, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_611638(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_611639, base: "/",
    url: url_ListGroupCertificateAuthorities_611640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_611684 = ref object of OpenApiRestCall_610642
proc url_CreateGroupVersion_611686(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupVersion_611685(path: JsonNode; query: JsonNode;
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
  var valid_611687 = path.getOrDefault("GroupId")
  valid_611687 = validateParameter(valid_611687, JString, required = true,
                                 default = nil)
  if valid_611687 != nil:
    section.add "GroupId", valid_611687
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
  var valid_611688 = header.getOrDefault("X-Amz-Signature")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Signature", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Content-Sha256", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Date")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Date", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Credential")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Credential", valid_611691
  var valid_611692 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amzn-Client-Token", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_CreateGroupVersion_611684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_CreateGroupVersion_611684; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_611699 = newJObject()
  var body_611700 = newJObject()
  add(path_611699, "GroupId", newJString(GroupId))
  if body != nil:
    body_611700 = body
  result = call_611698.call(path_611699, nil, nil, nil, body_611700)

var createGroupVersion* = Call_CreateGroupVersion_611684(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_611685, base: "/",
    url: url_CreateGroupVersion_611686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_611667 = ref object of OpenApiRestCall_610642
proc url_ListGroupVersions_611669(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupVersions_611668(path: JsonNode; query: JsonNode;
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
  var valid_611670 = path.getOrDefault("GroupId")
  valid_611670 = validateParameter(valid_611670, JString, required = true,
                                 default = nil)
  if valid_611670 != nil:
    section.add "GroupId", valid_611670
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611671 = query.getOrDefault("MaxResults")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "MaxResults", valid_611671
  var valid_611672 = query.getOrDefault("NextToken")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "NextToken", valid_611672
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
  var valid_611673 = header.getOrDefault("X-Amz-Signature")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Signature", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Content-Sha256", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Date")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Date", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Credential")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Credential", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Security-Token")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Security-Token", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Algorithm")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Algorithm", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-SignedHeaders", valid_611679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611680: Call_ListGroupVersions_611667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_611680.validator(path, query, header, formData, body)
  let scheme = call_611680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611680.url(scheme.get, call_611680.host, call_611680.base,
                         call_611680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611680, url, valid)

proc call*(call_611681: Call_ListGroupVersions_611667; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_611682 = newJObject()
  var query_611683 = newJObject()
  add(path_611682, "GroupId", newJString(GroupId))
  add(query_611683, "MaxResults", newJString(MaxResults))
  add(query_611683, "NextToken", newJString(NextToken))
  result = call_611681.call(path_611682, query_611683, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_611667(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_611668, base: "/",
    url: url_ListGroupVersions_611669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_611716 = ref object of OpenApiRestCall_610642
proc url_CreateLoggerDefinition_611718(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoggerDefinition_611717(path: JsonNode; query: JsonNode;
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
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amzn-Client-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Security-Token")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Security-Token", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Algorithm")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Algorithm", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-SignedHeaders", valid_611726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611728: Call_CreateLoggerDefinition_611716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_611728.validator(path, query, header, formData, body)
  let scheme = call_611728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611728.url(scheme.get, call_611728.host, call_611728.base,
                         call_611728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611728, url, valid)

proc call*(call_611729: Call_CreateLoggerDefinition_611716; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_611730 = newJObject()
  if body != nil:
    body_611730 = body
  result = call_611729.call(nil, nil, nil, nil, body_611730)

var createLoggerDefinition* = Call_CreateLoggerDefinition_611716(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_611717, base: "/",
    url: url_CreateLoggerDefinition_611718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_611701 = ref object of OpenApiRestCall_610642
proc url_ListLoggerDefinitions_611703(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggerDefinitions_611702(path: JsonNode; query: JsonNode;
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
  var valid_611704 = query.getOrDefault("MaxResults")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "MaxResults", valid_611704
  var valid_611705 = query.getOrDefault("NextToken")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "NextToken", valid_611705
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
  var valid_611706 = header.getOrDefault("X-Amz-Signature")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Signature", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Content-Sha256", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Date")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Date", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Credential")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Credential", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Security-Token")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Security-Token", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Algorithm")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Algorithm", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-SignedHeaders", valid_611712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611713: Call_ListLoggerDefinitions_611701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_611713.validator(path, query, header, formData, body)
  let scheme = call_611713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611713.url(scheme.get, call_611713.host, call_611713.base,
                         call_611713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611713, url, valid)

proc call*(call_611714: Call_ListLoggerDefinitions_611701; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611715 = newJObject()
  add(query_611715, "MaxResults", newJString(MaxResults))
  add(query_611715, "NextToken", newJString(NextToken))
  result = call_611714.call(nil, query_611715, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_611701(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_611702, base: "/",
    url: url_ListLoggerDefinitions_611703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_611748 = ref object of OpenApiRestCall_610642
proc url_CreateLoggerDefinitionVersion_611750(protocol: Scheme; host: string;
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

proc validate_CreateLoggerDefinitionVersion_611749(path: JsonNode; query: JsonNode;
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
  var valid_611751 = path.getOrDefault("LoggerDefinitionId")
  valid_611751 = validateParameter(valid_611751, JString, required = true,
                                 default = nil)
  if valid_611751 != nil:
    section.add "LoggerDefinitionId", valid_611751
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
  var valid_611752 = header.getOrDefault("X-Amz-Signature")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Signature", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Content-Sha256", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Date")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Date", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Credential")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Credential", valid_611755
  var valid_611756 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amzn-Client-Token", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Security-Token")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Security-Token", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Algorithm")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Algorithm", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-SignedHeaders", valid_611759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611761: Call_CreateLoggerDefinitionVersion_611748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_611761.validator(path, query, header, formData, body)
  let scheme = call_611761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611761.url(scheme.get, call_611761.host, call_611761.base,
                         call_611761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611761, url, valid)

proc call*(call_611762: Call_CreateLoggerDefinitionVersion_611748;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_611763 = newJObject()
  var body_611764 = newJObject()
  add(path_611763, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_611764 = body
  result = call_611762.call(path_611763, nil, nil, nil, body_611764)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_611748(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_611749, base: "/",
    url: url_CreateLoggerDefinitionVersion_611750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_611731 = ref object of OpenApiRestCall_610642
proc url_ListLoggerDefinitionVersions_611733(protocol: Scheme; host: string;
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

proc validate_ListLoggerDefinitionVersions_611732(path: JsonNode; query: JsonNode;
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
  var valid_611734 = path.getOrDefault("LoggerDefinitionId")
  valid_611734 = validateParameter(valid_611734, JString, required = true,
                                 default = nil)
  if valid_611734 != nil:
    section.add "LoggerDefinitionId", valid_611734
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611735 = query.getOrDefault("MaxResults")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "MaxResults", valid_611735
  var valid_611736 = query.getOrDefault("NextToken")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "NextToken", valid_611736
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
  var valid_611737 = header.getOrDefault("X-Amz-Signature")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Signature", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Content-Sha256", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Date")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Date", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Credential")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Credential", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Security-Token")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Security-Token", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Algorithm")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Algorithm", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-SignedHeaders", valid_611743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611744: Call_ListLoggerDefinitionVersions_611731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_611744.validator(path, query, header, formData, body)
  let scheme = call_611744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611744.url(scheme.get, call_611744.host, call_611744.base,
                         call_611744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611744, url, valid)

proc call*(call_611745: Call_ListLoggerDefinitionVersions_611731;
          LoggerDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_611746 = newJObject()
  var query_611747 = newJObject()
  add(query_611747, "MaxResults", newJString(MaxResults))
  add(query_611747, "NextToken", newJString(NextToken))
  add(path_611746, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_611745.call(path_611746, query_611747, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_611731(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_611732, base: "/",
    url: url_ListLoggerDefinitionVersions_611733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_611780 = ref object of OpenApiRestCall_610642
proc url_CreateResourceDefinition_611782(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDefinition_611781(path: JsonNode; query: JsonNode;
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
  var valid_611783 = header.getOrDefault("X-Amz-Signature")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Signature", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Content-Sha256", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Date")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Date", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Credential")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Credential", valid_611786
  var valid_611787 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amzn-Client-Token", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Security-Token")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Security-Token", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Algorithm")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Algorithm", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-SignedHeaders", valid_611790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611792: Call_CreateResourceDefinition_611780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_611792.validator(path, query, header, formData, body)
  let scheme = call_611792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611792.url(scheme.get, call_611792.host, call_611792.base,
                         call_611792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611792, url, valid)

proc call*(call_611793: Call_CreateResourceDefinition_611780; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_611794 = newJObject()
  if body != nil:
    body_611794 = body
  result = call_611793.call(nil, nil, nil, nil, body_611794)

var createResourceDefinition* = Call_CreateResourceDefinition_611780(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_611781, base: "/",
    url: url_CreateResourceDefinition_611782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_611765 = ref object of OpenApiRestCall_610642
proc url_ListResourceDefinitions_611767(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDefinitions_611766(path: JsonNode; query: JsonNode;
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
  var valid_611768 = query.getOrDefault("MaxResults")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "MaxResults", valid_611768
  var valid_611769 = query.getOrDefault("NextToken")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "NextToken", valid_611769
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
  var valid_611770 = header.getOrDefault("X-Amz-Signature")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Signature", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Content-Sha256", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Date")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Date", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Credential")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Credential", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Security-Token")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Security-Token", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Algorithm")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Algorithm", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-SignedHeaders", valid_611776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611777: Call_ListResourceDefinitions_611765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_611777.validator(path, query, header, formData, body)
  let scheme = call_611777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611777.url(scheme.get, call_611777.host, call_611777.base,
                         call_611777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611777, url, valid)

proc call*(call_611778: Call_ListResourceDefinitions_611765;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611779 = newJObject()
  add(query_611779, "MaxResults", newJString(MaxResults))
  add(query_611779, "NextToken", newJString(NextToken))
  result = call_611778.call(nil, query_611779, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_611765(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_611766, base: "/",
    url: url_ListResourceDefinitions_611767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_611812 = ref object of OpenApiRestCall_610642
proc url_CreateResourceDefinitionVersion_611814(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinitionVersion_611813(path: JsonNode;
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
  var valid_611815 = path.getOrDefault("ResourceDefinitionId")
  valid_611815 = validateParameter(valid_611815, JString, required = true,
                                 default = nil)
  if valid_611815 != nil:
    section.add "ResourceDefinitionId", valid_611815
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
  var valid_611816 = header.getOrDefault("X-Amz-Signature")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Signature", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Content-Sha256", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Date")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Date", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Credential")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Credential", valid_611819
  var valid_611820 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amzn-Client-Token", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Security-Token")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Security-Token", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-Algorithm")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Algorithm", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-SignedHeaders", valid_611823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611825: Call_CreateResourceDefinitionVersion_611812;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_611825.validator(path, query, header, formData, body)
  let scheme = call_611825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611825.url(scheme.get, call_611825.host, call_611825.base,
                         call_611825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611825, url, valid)

proc call*(call_611826: Call_CreateResourceDefinitionVersion_611812;
          body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_611827 = newJObject()
  var body_611828 = newJObject()
  if body != nil:
    body_611828 = body
  add(path_611827, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_611826.call(path_611827, nil, nil, nil, body_611828)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_611812(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_611813, base: "/",
    url: url_CreateResourceDefinitionVersion_611814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_611795 = ref object of OpenApiRestCall_610642
proc url_ListResourceDefinitionVersions_611797(protocol: Scheme; host: string;
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

proc validate_ListResourceDefinitionVersions_611796(path: JsonNode;
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
  var valid_611798 = path.getOrDefault("ResourceDefinitionId")
  valid_611798 = validateParameter(valid_611798, JString, required = true,
                                 default = nil)
  if valid_611798 != nil:
    section.add "ResourceDefinitionId", valid_611798
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611799 = query.getOrDefault("MaxResults")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "MaxResults", valid_611799
  var valid_611800 = query.getOrDefault("NextToken")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "NextToken", valid_611800
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
  var valid_611801 = header.getOrDefault("X-Amz-Signature")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Signature", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Content-Sha256", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Date")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Date", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Credential")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Credential", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Security-Token")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Security-Token", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Algorithm")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Algorithm", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-SignedHeaders", valid_611807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611808: Call_ListResourceDefinitionVersions_611795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_611808.validator(path, query, header, formData, body)
  let scheme = call_611808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611808.url(scheme.get, call_611808.host, call_611808.base,
                         call_611808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611808, url, valid)

proc call*(call_611809: Call_ListResourceDefinitionVersions_611795;
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
  var path_611810 = newJObject()
  var query_611811 = newJObject()
  add(query_611811, "MaxResults", newJString(MaxResults))
  add(query_611811, "NextToken", newJString(NextToken))
  add(path_611810, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_611809.call(path_611810, query_611811, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_611795(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_611796, base: "/",
    url: url_ListResourceDefinitionVersions_611797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_611829 = ref object of OpenApiRestCall_610642
proc url_CreateSoftwareUpdateJob_611831(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSoftwareUpdateJob_611830(path: JsonNode; query: JsonNode;
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
  var valid_611832 = header.getOrDefault("X-Amz-Signature")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Signature", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Content-Sha256", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Date")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Date", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Credential")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Credential", valid_611835
  var valid_611836 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amzn-Client-Token", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Security-Token")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Security-Token", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Algorithm")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Algorithm", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-SignedHeaders", valid_611839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611841: Call_CreateSoftwareUpdateJob_611829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_611841.validator(path, query, header, formData, body)
  let scheme = call_611841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611841.url(scheme.get, call_611841.host, call_611841.base,
                         call_611841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611841, url, valid)

proc call*(call_611842: Call_CreateSoftwareUpdateJob_611829; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_611843 = newJObject()
  if body != nil:
    body_611843 = body
  result = call_611842.call(nil, nil, nil, nil, body_611843)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_611829(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_611830, base: "/",
    url: url_CreateSoftwareUpdateJob_611831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_611859 = ref object of OpenApiRestCall_610642
proc url_CreateSubscriptionDefinition_611861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubscriptionDefinition_611860(path: JsonNode; query: JsonNode;
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
  var valid_611862 = header.getOrDefault("X-Amz-Signature")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Signature", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Content-Sha256", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Date")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Date", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Credential")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Credential", valid_611865
  var valid_611866 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amzn-Client-Token", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Security-Token")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Security-Token", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Algorithm")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Algorithm", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-SignedHeaders", valid_611869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611871: Call_CreateSubscriptionDefinition_611859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_611871.validator(path, query, header, formData, body)
  let scheme = call_611871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611871.url(scheme.get, call_611871.host, call_611871.base,
                         call_611871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611871, url, valid)

proc call*(call_611872: Call_CreateSubscriptionDefinition_611859; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_611873 = newJObject()
  if body != nil:
    body_611873 = body
  result = call_611872.call(nil, nil, nil, nil, body_611873)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_611859(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_611860, base: "/",
    url: url_CreateSubscriptionDefinition_611861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_611844 = ref object of OpenApiRestCall_610642
proc url_ListSubscriptionDefinitions_611846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscriptionDefinitions_611845(path: JsonNode; query: JsonNode;
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
  var valid_611847 = query.getOrDefault("MaxResults")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "MaxResults", valid_611847
  var valid_611848 = query.getOrDefault("NextToken")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "NextToken", valid_611848
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
  var valid_611849 = header.getOrDefault("X-Amz-Signature")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Signature", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Content-Sha256", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Date")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Date", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Credential")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Credential", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Security-Token")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Security-Token", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Algorithm")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Algorithm", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-SignedHeaders", valid_611855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611856: Call_ListSubscriptionDefinitions_611844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_611856.validator(path, query, header, formData, body)
  let scheme = call_611856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611856.url(scheme.get, call_611856.host, call_611856.base,
                         call_611856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611856, url, valid)

proc call*(call_611857: Call_ListSubscriptionDefinitions_611844;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_611858 = newJObject()
  add(query_611858, "MaxResults", newJString(MaxResults))
  add(query_611858, "NextToken", newJString(NextToken))
  result = call_611857.call(nil, query_611858, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_611844(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_611845, base: "/",
    url: url_ListSubscriptionDefinitions_611846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_611891 = ref object of OpenApiRestCall_610642
proc url_CreateSubscriptionDefinitionVersion_611893(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSubscriptionDefinitionVersion_611892(path: JsonNode;
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
  var valid_611894 = path.getOrDefault("SubscriptionDefinitionId")
  valid_611894 = validateParameter(valid_611894, JString, required = true,
                                 default = nil)
  if valid_611894 != nil:
    section.add "SubscriptionDefinitionId", valid_611894
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
  var valid_611895 = header.getOrDefault("X-Amz-Signature")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Signature", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Content-Sha256", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Date")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Date", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Credential")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Credential", valid_611898
  var valid_611899 = header.getOrDefault("X-Amzn-Client-Token")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amzn-Client-Token", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Security-Token")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Security-Token", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Algorithm")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Algorithm", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-SignedHeaders", valid_611902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611904: Call_CreateSubscriptionDefinitionVersion_611891;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_611904.validator(path, query, header, formData, body)
  let scheme = call_611904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611904.url(scheme.get, call_611904.host, call_611904.base,
                         call_611904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611904, url, valid)

proc call*(call_611905: Call_CreateSubscriptionDefinitionVersion_611891;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_611906 = newJObject()
  var body_611907 = newJObject()
  add(path_611906, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_611907 = body
  result = call_611905.call(path_611906, nil, nil, nil, body_611907)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_611891(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_611892, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_611893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_611874 = ref object of OpenApiRestCall_610642
proc url_ListSubscriptionDefinitionVersions_611876(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSubscriptionDefinitionVersions_611875(path: JsonNode;
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
  var valid_611877 = path.getOrDefault("SubscriptionDefinitionId")
  valid_611877 = validateParameter(valid_611877, JString, required = true,
                                 default = nil)
  if valid_611877 != nil:
    section.add "SubscriptionDefinitionId", valid_611877
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_611878 = query.getOrDefault("MaxResults")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "MaxResults", valid_611878
  var valid_611879 = query.getOrDefault("NextToken")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "NextToken", valid_611879
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
  var valid_611880 = header.getOrDefault("X-Amz-Signature")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Signature", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Content-Sha256", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Date")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Date", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Credential")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Credential", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Security-Token")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Security-Token", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Algorithm")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Algorithm", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-SignedHeaders", valid_611886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611887: Call_ListSubscriptionDefinitionVersions_611874;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_611887.validator(path, query, header, formData, body)
  let scheme = call_611887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611887.url(scheme.get, call_611887.host, call_611887.base,
                         call_611887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611887, url, valid)

proc call*(call_611888: Call_ListSubscriptionDefinitionVersions_611874;
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
  var path_611889 = newJObject()
  var query_611890 = newJObject()
  add(query_611890, "MaxResults", newJString(MaxResults))
  add(query_611890, "NextToken", newJString(NextToken))
  add(path_611889, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_611888.call(path_611889, query_611890, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_611874(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_611875, base: "/",
    url: url_ListSubscriptionDefinitionVersions_611876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_611922 = ref object of OpenApiRestCall_610642
proc url_UpdateConnectorDefinition_611924(protocol: Scheme; host: string;
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

proc validate_UpdateConnectorDefinition_611923(path: JsonNode; query: JsonNode;
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
  var valid_611925 = path.getOrDefault("ConnectorDefinitionId")
  valid_611925 = validateParameter(valid_611925, JString, required = true,
                                 default = nil)
  if valid_611925 != nil:
    section.add "ConnectorDefinitionId", valid_611925
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
  var valid_611926 = header.getOrDefault("X-Amz-Signature")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Signature", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Content-Sha256", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Date")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Date", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Credential")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Credential", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Security-Token")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Security-Token", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Algorithm")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Algorithm", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-SignedHeaders", valid_611932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611934: Call_UpdateConnectorDefinition_611922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_611934.validator(path, query, header, formData, body)
  let scheme = call_611934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611934.url(scheme.get, call_611934.host, call_611934.base,
                         call_611934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611934, url, valid)

proc call*(call_611935: Call_UpdateConnectorDefinition_611922;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_611936 = newJObject()
  var body_611937 = newJObject()
  add(path_611936, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_611937 = body
  result = call_611935.call(path_611936, nil, nil, nil, body_611937)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_611922(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_611923, base: "/",
    url: url_UpdateConnectorDefinition_611924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_611908 = ref object of OpenApiRestCall_610642
proc url_GetConnectorDefinition_611910(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConnectorDefinition_611909(path: JsonNode; query: JsonNode;
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
  var valid_611911 = path.getOrDefault("ConnectorDefinitionId")
  valid_611911 = validateParameter(valid_611911, JString, required = true,
                                 default = nil)
  if valid_611911 != nil:
    section.add "ConnectorDefinitionId", valid_611911
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
  var valid_611912 = header.getOrDefault("X-Amz-Signature")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Signature", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Content-Sha256", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Date")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Date", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Credential")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Credential", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Security-Token")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Security-Token", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Algorithm")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Algorithm", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-SignedHeaders", valid_611918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611919: Call_GetConnectorDefinition_611908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_611919.validator(path, query, header, formData, body)
  let scheme = call_611919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611919.url(scheme.get, call_611919.host, call_611919.base,
                         call_611919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611919, url, valid)

proc call*(call_611920: Call_GetConnectorDefinition_611908;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_611921 = newJObject()
  add(path_611921, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_611920.call(path_611921, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_611908(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_611909, base: "/",
    url: url_GetConnectorDefinition_611910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_611938 = ref object of OpenApiRestCall_610642
proc url_DeleteConnectorDefinition_611940(protocol: Scheme; host: string;
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

proc validate_DeleteConnectorDefinition_611939(path: JsonNode; query: JsonNode;
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
  var valid_611941 = path.getOrDefault("ConnectorDefinitionId")
  valid_611941 = validateParameter(valid_611941, JString, required = true,
                                 default = nil)
  if valid_611941 != nil:
    section.add "ConnectorDefinitionId", valid_611941
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
  var valid_611942 = header.getOrDefault("X-Amz-Signature")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Signature", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Content-Sha256", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Date")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Date", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Credential")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Credential", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Security-Token")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Security-Token", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Algorithm")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Algorithm", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-SignedHeaders", valid_611948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611949: Call_DeleteConnectorDefinition_611938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_611949.validator(path, query, header, formData, body)
  let scheme = call_611949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611949.url(scheme.get, call_611949.host, call_611949.base,
                         call_611949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611949, url, valid)

proc call*(call_611950: Call_DeleteConnectorDefinition_611938;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_611951 = newJObject()
  add(path_611951, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_611950.call(path_611951, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_611938(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_611939, base: "/",
    url: url_DeleteConnectorDefinition_611940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_611966 = ref object of OpenApiRestCall_610642
proc url_UpdateCoreDefinition_611968(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCoreDefinition_611967(path: JsonNode; query: JsonNode;
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
  var valid_611969 = path.getOrDefault("CoreDefinitionId")
  valid_611969 = validateParameter(valid_611969, JString, required = true,
                                 default = nil)
  if valid_611969 != nil:
    section.add "CoreDefinitionId", valid_611969
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
  var valid_611970 = header.getOrDefault("X-Amz-Signature")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Signature", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Content-Sha256", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-Date")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Date", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Credential")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Credential", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Security-Token")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Security-Token", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Algorithm")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Algorithm", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-SignedHeaders", valid_611976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611978: Call_UpdateCoreDefinition_611966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_611978.validator(path, query, header, formData, body)
  let scheme = call_611978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611978.url(scheme.get, call_611978.host, call_611978.base,
                         call_611978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611978, url, valid)

proc call*(call_611979: Call_UpdateCoreDefinition_611966; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_611980 = newJObject()
  var body_611981 = newJObject()
  add(path_611980, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_611981 = body
  result = call_611979.call(path_611980, nil, nil, nil, body_611981)

var updateCoreDefinition* = Call_UpdateCoreDefinition_611966(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_611967, base: "/",
    url: url_UpdateCoreDefinition_611968, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_611952 = ref object of OpenApiRestCall_610642
proc url_GetCoreDefinition_611954(protocol: Scheme; host: string; base: string;
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

proc validate_GetCoreDefinition_611953(path: JsonNode; query: JsonNode;
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
  var valid_611955 = path.getOrDefault("CoreDefinitionId")
  valid_611955 = validateParameter(valid_611955, JString, required = true,
                                 default = nil)
  if valid_611955 != nil:
    section.add "CoreDefinitionId", valid_611955
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
  var valid_611956 = header.getOrDefault("X-Amz-Signature")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Signature", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Content-Sha256", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Date")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Date", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Credential")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Credential", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Security-Token")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Security-Token", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Algorithm")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Algorithm", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-SignedHeaders", valid_611962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611963: Call_GetCoreDefinition_611952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_611963.validator(path, query, header, formData, body)
  let scheme = call_611963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611963.url(scheme.get, call_611963.host, call_611963.base,
                         call_611963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611963, url, valid)

proc call*(call_611964: Call_GetCoreDefinition_611952; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_611965 = newJObject()
  add(path_611965, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_611964.call(path_611965, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_611952(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_611953, base: "/",
    url: url_GetCoreDefinition_611954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_611982 = ref object of OpenApiRestCall_610642
proc url_DeleteCoreDefinition_611984(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCoreDefinition_611983(path: JsonNode; query: JsonNode;
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
  var valid_611985 = path.getOrDefault("CoreDefinitionId")
  valid_611985 = validateParameter(valid_611985, JString, required = true,
                                 default = nil)
  if valid_611985 != nil:
    section.add "CoreDefinitionId", valid_611985
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
  var valid_611986 = header.getOrDefault("X-Amz-Signature")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Signature", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Content-Sha256", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Date")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Date", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Credential")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Credential", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Security-Token")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Security-Token", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Algorithm")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Algorithm", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-SignedHeaders", valid_611992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611993: Call_DeleteCoreDefinition_611982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_611993.validator(path, query, header, formData, body)
  let scheme = call_611993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611993.url(scheme.get, call_611993.host, call_611993.base,
                         call_611993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611993, url, valid)

proc call*(call_611994: Call_DeleteCoreDefinition_611982; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_611995 = newJObject()
  add(path_611995, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_611994.call(path_611995, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_611982(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_611983, base: "/",
    url: url_DeleteCoreDefinition_611984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_612010 = ref object of OpenApiRestCall_610642
proc url_UpdateDeviceDefinition_612012(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceDefinition_612011(path: JsonNode; query: JsonNode;
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
  var valid_612013 = path.getOrDefault("DeviceDefinitionId")
  valid_612013 = validateParameter(valid_612013, JString, required = true,
                                 default = nil)
  if valid_612013 != nil:
    section.add "DeviceDefinitionId", valid_612013
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
  var valid_612014 = header.getOrDefault("X-Amz-Signature")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Signature", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Content-Sha256", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Date")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Date", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Credential")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Credential", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Security-Token")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Security-Token", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-Algorithm")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Algorithm", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-SignedHeaders", valid_612020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612022: Call_UpdateDeviceDefinition_612010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_612022.validator(path, query, header, formData, body)
  let scheme = call_612022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612022.url(scheme.get, call_612022.host, call_612022.base,
                         call_612022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612022, url, valid)

proc call*(call_612023: Call_UpdateDeviceDefinition_612010;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_612024 = newJObject()
  var body_612025 = newJObject()
  add(path_612024, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_612025 = body
  result = call_612023.call(path_612024, nil, nil, nil, body_612025)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_612010(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_612011, base: "/",
    url: url_UpdateDeviceDefinition_612012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_611996 = ref object of OpenApiRestCall_610642
proc url_GetDeviceDefinition_611998(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceDefinition_611997(path: JsonNode; query: JsonNode;
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
  var valid_611999 = path.getOrDefault("DeviceDefinitionId")
  valid_611999 = validateParameter(valid_611999, JString, required = true,
                                 default = nil)
  if valid_611999 != nil:
    section.add "DeviceDefinitionId", valid_611999
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
  var valid_612000 = header.getOrDefault("X-Amz-Signature")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Signature", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Content-Sha256", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Date")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Date", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Credential")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Credential", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Security-Token")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Security-Token", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Algorithm")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Algorithm", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-SignedHeaders", valid_612006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612007: Call_GetDeviceDefinition_611996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_612007.validator(path, query, header, formData, body)
  let scheme = call_612007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612007.url(scheme.get, call_612007.host, call_612007.base,
                         call_612007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612007, url, valid)

proc call*(call_612008: Call_GetDeviceDefinition_611996; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_612009 = newJObject()
  add(path_612009, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_612008.call(path_612009, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_611996(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_611997, base: "/",
    url: url_GetDeviceDefinition_611998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_612026 = ref object of OpenApiRestCall_610642
proc url_DeleteDeviceDefinition_612028(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceDefinition_612027(path: JsonNode; query: JsonNode;
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
  var valid_612029 = path.getOrDefault("DeviceDefinitionId")
  valid_612029 = validateParameter(valid_612029, JString, required = true,
                                 default = nil)
  if valid_612029 != nil:
    section.add "DeviceDefinitionId", valid_612029
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
  var valid_612030 = header.getOrDefault("X-Amz-Signature")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Signature", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Content-Sha256", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Date")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Date", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Credential")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Credential", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-Security-Token")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Security-Token", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-Algorithm")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-Algorithm", valid_612035
  var valid_612036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "X-Amz-SignedHeaders", valid_612036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612037: Call_DeleteDeviceDefinition_612026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_612037.validator(path, query, header, formData, body)
  let scheme = call_612037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612037.url(scheme.get, call_612037.host, call_612037.base,
                         call_612037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612037, url, valid)

proc call*(call_612038: Call_DeleteDeviceDefinition_612026;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_612039 = newJObject()
  add(path_612039, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_612038.call(path_612039, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_612026(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_612027, base: "/",
    url: url_DeleteDeviceDefinition_612028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_612054 = ref object of OpenApiRestCall_610642
proc url_UpdateFunctionDefinition_612056(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionDefinition_612055(path: JsonNode; query: JsonNode;
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
  var valid_612057 = path.getOrDefault("FunctionDefinitionId")
  valid_612057 = validateParameter(valid_612057, JString, required = true,
                                 default = nil)
  if valid_612057 != nil:
    section.add "FunctionDefinitionId", valid_612057
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
  var valid_612058 = header.getOrDefault("X-Amz-Signature")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Signature", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Content-Sha256", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Date")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Date", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Credential")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Credential", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Security-Token")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Security-Token", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Algorithm")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Algorithm", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-SignedHeaders", valid_612064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612066: Call_UpdateFunctionDefinition_612054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_612066.validator(path, query, header, formData, body)
  let scheme = call_612066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612066.url(scheme.get, call_612066.host, call_612066.base,
                         call_612066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612066, url, valid)

proc call*(call_612067: Call_UpdateFunctionDefinition_612054;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_612068 = newJObject()
  var body_612069 = newJObject()
  add(path_612068, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_612069 = body
  result = call_612067.call(path_612068, nil, nil, nil, body_612069)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_612054(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_612055, base: "/",
    url: url_UpdateFunctionDefinition_612056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_612040 = ref object of OpenApiRestCall_610642
proc url_GetFunctionDefinition_612042(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionDefinition_612041(path: JsonNode; query: JsonNode;
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
  var valid_612043 = path.getOrDefault("FunctionDefinitionId")
  valid_612043 = validateParameter(valid_612043, JString, required = true,
                                 default = nil)
  if valid_612043 != nil:
    section.add "FunctionDefinitionId", valid_612043
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
  var valid_612044 = header.getOrDefault("X-Amz-Signature")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Signature", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Content-Sha256", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Date")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Date", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Credential")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Credential", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Security-Token")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Security-Token", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Algorithm")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Algorithm", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-SignedHeaders", valid_612050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612051: Call_GetFunctionDefinition_612040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_612051.validator(path, query, header, formData, body)
  let scheme = call_612051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612051.url(scheme.get, call_612051.host, call_612051.base,
                         call_612051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612051, url, valid)

proc call*(call_612052: Call_GetFunctionDefinition_612040;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_612053 = newJObject()
  add(path_612053, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_612052.call(path_612053, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_612040(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_612041, base: "/",
    url: url_GetFunctionDefinition_612042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_612070 = ref object of OpenApiRestCall_610642
proc url_DeleteFunctionDefinition_612072(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionDefinition_612071(path: JsonNode; query: JsonNode;
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
  var valid_612073 = path.getOrDefault("FunctionDefinitionId")
  valid_612073 = validateParameter(valid_612073, JString, required = true,
                                 default = nil)
  if valid_612073 != nil:
    section.add "FunctionDefinitionId", valid_612073
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
  var valid_612074 = header.getOrDefault("X-Amz-Signature")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Signature", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Content-Sha256", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Date")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Date", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Credential")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Credential", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Security-Token")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Security-Token", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Algorithm")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Algorithm", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-SignedHeaders", valid_612080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612081: Call_DeleteFunctionDefinition_612070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_612081.validator(path, query, header, formData, body)
  let scheme = call_612081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612081.url(scheme.get, call_612081.host, call_612081.base,
                         call_612081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612081, url, valid)

proc call*(call_612082: Call_DeleteFunctionDefinition_612070;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_612083 = newJObject()
  add(path_612083, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_612082.call(path_612083, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_612070(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_612071, base: "/",
    url: url_DeleteFunctionDefinition_612072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_612098 = ref object of OpenApiRestCall_610642
proc url_UpdateGroup_612100(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_612099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612101 = path.getOrDefault("GroupId")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = nil)
  if valid_612101 != nil:
    section.add "GroupId", valid_612101
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
  var valid_612102 = header.getOrDefault("X-Amz-Signature")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Signature", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Content-Sha256", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Date")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Date", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Credential")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Credential", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Security-Token")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Security-Token", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Algorithm")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Algorithm", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-SignedHeaders", valid_612108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612110: Call_UpdateGroup_612098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_612110.validator(path, query, header, formData, body)
  let scheme = call_612110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612110.url(scheme.get, call_612110.host, call_612110.base,
                         call_612110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612110, url, valid)

proc call*(call_612111: Call_UpdateGroup_612098; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_612112 = newJObject()
  var body_612113 = newJObject()
  add(path_612112, "GroupId", newJString(GroupId))
  if body != nil:
    body_612113 = body
  result = call_612111.call(path_612112, nil, nil, nil, body_612113)

var updateGroup* = Call_UpdateGroup_612098(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_612099,
                                        base: "/", url: url_UpdateGroup_612100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_612084 = ref object of OpenApiRestCall_610642
proc url_GetGroup_612086(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_612085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612087 = path.getOrDefault("GroupId")
  valid_612087 = validateParameter(valid_612087, JString, required = true,
                                 default = nil)
  if valid_612087 != nil:
    section.add "GroupId", valid_612087
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
  var valid_612088 = header.getOrDefault("X-Amz-Signature")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Signature", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Content-Sha256", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Date")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Date", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Credential")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Credential", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Security-Token")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Security-Token", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Algorithm")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Algorithm", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-SignedHeaders", valid_612094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612095: Call_GetGroup_612084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_612095.validator(path, query, header, formData, body)
  let scheme = call_612095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612095.url(scheme.get, call_612095.host, call_612095.base,
                         call_612095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612095, url, valid)

proc call*(call_612096: Call_GetGroup_612084; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_612097 = newJObject()
  add(path_612097, "GroupId", newJString(GroupId))
  result = call_612096.call(path_612097, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_612084(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_612085, base: "/",
                                  url: url_GetGroup_612086,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_612114 = ref object of OpenApiRestCall_610642
proc url_DeleteGroup_612116(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_612115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612117 = path.getOrDefault("GroupId")
  valid_612117 = validateParameter(valid_612117, JString, required = true,
                                 default = nil)
  if valid_612117 != nil:
    section.add "GroupId", valid_612117
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
  var valid_612118 = header.getOrDefault("X-Amz-Signature")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Signature", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Content-Sha256", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Date")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Date", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Credential")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Credential", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-Security-Token")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-Security-Token", valid_612122
  var valid_612123 = header.getOrDefault("X-Amz-Algorithm")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "X-Amz-Algorithm", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-SignedHeaders", valid_612124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612125: Call_DeleteGroup_612114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_612125.validator(path, query, header, formData, body)
  let scheme = call_612125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612125.url(scheme.get, call_612125.host, call_612125.base,
                         call_612125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612125, url, valid)

proc call*(call_612126: Call_DeleteGroup_612114; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_612127 = newJObject()
  add(path_612127, "GroupId", newJString(GroupId))
  result = call_612126.call(path_612127, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_612114(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_612115,
                                        base: "/", url: url_DeleteGroup_612116,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_612142 = ref object of OpenApiRestCall_610642
proc url_UpdateLoggerDefinition_612144(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLoggerDefinition_612143(path: JsonNode; query: JsonNode;
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
  var valid_612145 = path.getOrDefault("LoggerDefinitionId")
  valid_612145 = validateParameter(valid_612145, JString, required = true,
                                 default = nil)
  if valid_612145 != nil:
    section.add "LoggerDefinitionId", valid_612145
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
  var valid_612146 = header.getOrDefault("X-Amz-Signature")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Signature", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Content-Sha256", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Date")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Date", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Credential")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Credential", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Security-Token")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Security-Token", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Algorithm")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Algorithm", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-SignedHeaders", valid_612152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612154: Call_UpdateLoggerDefinition_612142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_612154.validator(path, query, header, formData, body)
  let scheme = call_612154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612154.url(scheme.get, call_612154.host, call_612154.base,
                         call_612154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612154, url, valid)

proc call*(call_612155: Call_UpdateLoggerDefinition_612142;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_612156 = newJObject()
  var body_612157 = newJObject()
  add(path_612156, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_612157 = body
  result = call_612155.call(path_612156, nil, nil, nil, body_612157)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_612142(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_612143, base: "/",
    url: url_UpdateLoggerDefinition_612144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_612128 = ref object of OpenApiRestCall_610642
proc url_GetLoggerDefinition_612130(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoggerDefinition_612129(path: JsonNode; query: JsonNode;
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
  var valid_612131 = path.getOrDefault("LoggerDefinitionId")
  valid_612131 = validateParameter(valid_612131, JString, required = true,
                                 default = nil)
  if valid_612131 != nil:
    section.add "LoggerDefinitionId", valid_612131
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
  var valid_612132 = header.getOrDefault("X-Amz-Signature")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Signature", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Content-Sha256", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Date")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Date", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Credential")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Credential", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Security-Token")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Security-Token", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Algorithm")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Algorithm", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-SignedHeaders", valid_612138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612139: Call_GetLoggerDefinition_612128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_612139.validator(path, query, header, formData, body)
  let scheme = call_612139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612139.url(scheme.get, call_612139.host, call_612139.base,
                         call_612139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612139, url, valid)

proc call*(call_612140: Call_GetLoggerDefinition_612128; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_612141 = newJObject()
  add(path_612141, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_612140.call(path_612141, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_612128(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_612129, base: "/",
    url: url_GetLoggerDefinition_612130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_612158 = ref object of OpenApiRestCall_610642
proc url_DeleteLoggerDefinition_612160(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoggerDefinition_612159(path: JsonNode; query: JsonNode;
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
  var valid_612161 = path.getOrDefault("LoggerDefinitionId")
  valid_612161 = validateParameter(valid_612161, JString, required = true,
                                 default = nil)
  if valid_612161 != nil:
    section.add "LoggerDefinitionId", valid_612161
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
  var valid_612162 = header.getOrDefault("X-Amz-Signature")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Signature", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Content-Sha256", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Date")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Date", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Credential")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Credential", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Security-Token")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Security-Token", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Algorithm")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Algorithm", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-SignedHeaders", valid_612168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612169: Call_DeleteLoggerDefinition_612158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_612169.validator(path, query, header, formData, body)
  let scheme = call_612169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612169.url(scheme.get, call_612169.host, call_612169.base,
                         call_612169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612169, url, valid)

proc call*(call_612170: Call_DeleteLoggerDefinition_612158;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_612171 = newJObject()
  add(path_612171, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_612170.call(path_612171, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_612158(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_612159, base: "/",
    url: url_DeleteLoggerDefinition_612160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_612186 = ref object of OpenApiRestCall_610642
proc url_UpdateResourceDefinition_612188(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResourceDefinition_612187(path: JsonNode; query: JsonNode;
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
  var valid_612189 = path.getOrDefault("ResourceDefinitionId")
  valid_612189 = validateParameter(valid_612189, JString, required = true,
                                 default = nil)
  if valid_612189 != nil:
    section.add "ResourceDefinitionId", valid_612189
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
  var valid_612190 = header.getOrDefault("X-Amz-Signature")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Signature", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Content-Sha256", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Date")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Date", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Credential")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Credential", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Security-Token")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Security-Token", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Algorithm")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Algorithm", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-SignedHeaders", valid_612196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612198: Call_UpdateResourceDefinition_612186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_612198.validator(path, query, header, formData, body)
  let scheme = call_612198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612198.url(scheme.get, call_612198.host, call_612198.base,
                         call_612198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612198, url, valid)

proc call*(call_612199: Call_UpdateResourceDefinition_612186; body: JsonNode;
          ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_612200 = newJObject()
  var body_612201 = newJObject()
  if body != nil:
    body_612201 = body
  add(path_612200, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_612199.call(path_612200, nil, nil, nil, body_612201)

var updateResourceDefinition* = Call_UpdateResourceDefinition_612186(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_612187, base: "/",
    url: url_UpdateResourceDefinition_612188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_612172 = ref object of OpenApiRestCall_610642
proc url_GetResourceDefinition_612174(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResourceDefinition_612173(path: JsonNode; query: JsonNode;
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
  var valid_612175 = path.getOrDefault("ResourceDefinitionId")
  valid_612175 = validateParameter(valid_612175, JString, required = true,
                                 default = nil)
  if valid_612175 != nil:
    section.add "ResourceDefinitionId", valid_612175
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
  var valid_612176 = header.getOrDefault("X-Amz-Signature")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Signature", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Content-Sha256", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Date")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Date", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Credential")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Credential", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Security-Token")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Security-Token", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Algorithm")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Algorithm", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-SignedHeaders", valid_612182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612183: Call_GetResourceDefinition_612172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_612183.validator(path, query, header, formData, body)
  let scheme = call_612183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612183.url(scheme.get, call_612183.host, call_612183.base,
                         call_612183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612183, url, valid)

proc call*(call_612184: Call_GetResourceDefinition_612172;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_612185 = newJObject()
  add(path_612185, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_612184.call(path_612185, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_612172(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_612173, base: "/",
    url: url_GetResourceDefinition_612174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_612202 = ref object of OpenApiRestCall_610642
proc url_DeleteResourceDefinition_612204(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResourceDefinition_612203(path: JsonNode; query: JsonNode;
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
  var valid_612205 = path.getOrDefault("ResourceDefinitionId")
  valid_612205 = validateParameter(valid_612205, JString, required = true,
                                 default = nil)
  if valid_612205 != nil:
    section.add "ResourceDefinitionId", valid_612205
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
  var valid_612206 = header.getOrDefault("X-Amz-Signature")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-Signature", valid_612206
  var valid_612207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Content-Sha256", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Date")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Date", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Credential")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Credential", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Security-Token")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Security-Token", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Algorithm")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Algorithm", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-SignedHeaders", valid_612212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612213: Call_DeleteResourceDefinition_612202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_612213.validator(path, query, header, formData, body)
  let scheme = call_612213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612213.url(scheme.get, call_612213.host, call_612213.base,
                         call_612213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612213, url, valid)

proc call*(call_612214: Call_DeleteResourceDefinition_612202;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_612215 = newJObject()
  add(path_612215, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_612214.call(path_612215, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_612202(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_612203, base: "/",
    url: url_DeleteResourceDefinition_612204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_612230 = ref object of OpenApiRestCall_610642
proc url_UpdateSubscriptionDefinition_612232(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_612231(path: JsonNode; query: JsonNode;
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
  var valid_612233 = path.getOrDefault("SubscriptionDefinitionId")
  valid_612233 = validateParameter(valid_612233, JString, required = true,
                                 default = nil)
  if valid_612233 != nil:
    section.add "SubscriptionDefinitionId", valid_612233
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
  var valid_612234 = header.getOrDefault("X-Amz-Signature")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Signature", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-Content-Sha256", valid_612235
  var valid_612236 = header.getOrDefault("X-Amz-Date")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-Date", valid_612236
  var valid_612237 = header.getOrDefault("X-Amz-Credential")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "X-Amz-Credential", valid_612237
  var valid_612238 = header.getOrDefault("X-Amz-Security-Token")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "X-Amz-Security-Token", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Algorithm")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Algorithm", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-SignedHeaders", valid_612240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612242: Call_UpdateSubscriptionDefinition_612230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_612242.validator(path, query, header, formData, body)
  let scheme = call_612242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612242.url(scheme.get, call_612242.host, call_612242.base,
                         call_612242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612242, url, valid)

proc call*(call_612243: Call_UpdateSubscriptionDefinition_612230;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_612244 = newJObject()
  var body_612245 = newJObject()
  add(path_612244, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_612245 = body
  result = call_612243.call(path_612244, nil, nil, nil, body_612245)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_612230(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_612231, base: "/",
    url: url_UpdateSubscriptionDefinition_612232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_612216 = ref object of OpenApiRestCall_610642
proc url_GetSubscriptionDefinition_612218(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_612217(path: JsonNode; query: JsonNode;
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
  var valid_612219 = path.getOrDefault("SubscriptionDefinitionId")
  valid_612219 = validateParameter(valid_612219, JString, required = true,
                                 default = nil)
  if valid_612219 != nil:
    section.add "SubscriptionDefinitionId", valid_612219
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
  var valid_612220 = header.getOrDefault("X-Amz-Signature")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Signature", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Content-Sha256", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-Date")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Date", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Credential")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Credential", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Security-Token")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Security-Token", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Algorithm")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Algorithm", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-SignedHeaders", valid_612226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612227: Call_GetSubscriptionDefinition_612216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_612227.validator(path, query, header, formData, body)
  let scheme = call_612227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612227.url(scheme.get, call_612227.host, call_612227.base,
                         call_612227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612227, url, valid)

proc call*(call_612228: Call_GetSubscriptionDefinition_612216;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_612229 = newJObject()
  add(path_612229, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_612228.call(path_612229, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_612216(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_612217, base: "/",
    url: url_GetSubscriptionDefinition_612218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_612246 = ref object of OpenApiRestCall_610642
proc url_DeleteSubscriptionDefinition_612248(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_612247(path: JsonNode; query: JsonNode;
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
  var valid_612249 = path.getOrDefault("SubscriptionDefinitionId")
  valid_612249 = validateParameter(valid_612249, JString, required = true,
                                 default = nil)
  if valid_612249 != nil:
    section.add "SubscriptionDefinitionId", valid_612249
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
  var valid_612250 = header.getOrDefault("X-Amz-Signature")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-Signature", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Content-Sha256", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Date")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Date", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Credential")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Credential", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Security-Token")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Security-Token", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Algorithm")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Algorithm", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-SignedHeaders", valid_612256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612257: Call_DeleteSubscriptionDefinition_612246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_612257.validator(path, query, header, formData, body)
  let scheme = call_612257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612257.url(scheme.get, call_612257.host, call_612257.base,
                         call_612257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612257, url, valid)

proc call*(call_612258: Call_DeleteSubscriptionDefinition_612246;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_612259 = newJObject()
  add(path_612259, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_612258.call(path_612259, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_612246(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_612247, base: "/",
    url: url_DeleteSubscriptionDefinition_612248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_612260 = ref object of OpenApiRestCall_610642
proc url_GetBulkDeploymentStatus_612262(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkDeploymentStatus_612261(path: JsonNode; query: JsonNode;
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
  var valid_612263 = path.getOrDefault("BulkDeploymentId")
  valid_612263 = validateParameter(valid_612263, JString, required = true,
                                 default = nil)
  if valid_612263 != nil:
    section.add "BulkDeploymentId", valid_612263
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
  var valid_612264 = header.getOrDefault("X-Amz-Signature")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Signature", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Content-Sha256", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-Date")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Date", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Credential")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Credential", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Security-Token")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Security-Token", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Algorithm")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Algorithm", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-SignedHeaders", valid_612270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612271: Call_GetBulkDeploymentStatus_612260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_612271.validator(path, query, header, formData, body)
  let scheme = call_612271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612271.url(scheme.get, call_612271.host, call_612271.base,
                         call_612271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612271, url, valid)

proc call*(call_612272: Call_GetBulkDeploymentStatus_612260;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_612273 = newJObject()
  add(path_612273, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_612272.call(path_612273, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_612260(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_612261, base: "/",
    url: url_GetBulkDeploymentStatus_612262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_612288 = ref object of OpenApiRestCall_610642
proc url_UpdateConnectivityInfo_612290(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnectivityInfo_612289(path: JsonNode; query: JsonNode;
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
  var valid_612291 = path.getOrDefault("ThingName")
  valid_612291 = validateParameter(valid_612291, JString, required = true,
                                 default = nil)
  if valid_612291 != nil:
    section.add "ThingName", valid_612291
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
  var valid_612292 = header.getOrDefault("X-Amz-Signature")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Signature", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Content-Sha256", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Date")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Date", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-Credential")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-Credential", valid_612295
  var valid_612296 = header.getOrDefault("X-Amz-Security-Token")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-Security-Token", valid_612296
  var valid_612297 = header.getOrDefault("X-Amz-Algorithm")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "X-Amz-Algorithm", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-SignedHeaders", valid_612298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612300: Call_UpdateConnectivityInfo_612288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_612300.validator(path, query, header, formData, body)
  let scheme = call_612300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612300.url(scheme.get, call_612300.host, call_612300.base,
                         call_612300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612300, url, valid)

proc call*(call_612301: Call_UpdateConnectivityInfo_612288; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_612302 = newJObject()
  var body_612303 = newJObject()
  add(path_612302, "ThingName", newJString(ThingName))
  if body != nil:
    body_612303 = body
  result = call_612301.call(path_612302, nil, nil, nil, body_612303)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_612288(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_612289, base: "/",
    url: url_UpdateConnectivityInfo_612290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_612274 = ref object of OpenApiRestCall_610642
proc url_GetConnectivityInfo_612276(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectivityInfo_612275(path: JsonNode; query: JsonNode;
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
  var valid_612277 = path.getOrDefault("ThingName")
  valid_612277 = validateParameter(valid_612277, JString, required = true,
                                 default = nil)
  if valid_612277 != nil:
    section.add "ThingName", valid_612277
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
  var valid_612278 = header.getOrDefault("X-Amz-Signature")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "X-Amz-Signature", valid_612278
  var valid_612279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Content-Sha256", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-Date")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-Date", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-Credential")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-Credential", valid_612281
  var valid_612282 = header.getOrDefault("X-Amz-Security-Token")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Security-Token", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Algorithm")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Algorithm", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-SignedHeaders", valid_612284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612285: Call_GetConnectivityInfo_612274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_612285.validator(path, query, header, formData, body)
  let scheme = call_612285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612285.url(scheme.get, call_612285.host, call_612285.base,
                         call_612285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612285, url, valid)

proc call*(call_612286: Call_GetConnectivityInfo_612274; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_612287 = newJObject()
  add(path_612287, "ThingName", newJString(ThingName))
  result = call_612286.call(path_612287, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_612274(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_612275, base: "/",
    url: url_GetConnectivityInfo_612276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_612304 = ref object of OpenApiRestCall_610642
proc url_GetConnectorDefinitionVersion_612306(protocol: Scheme; host: string;
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

proc validate_GetConnectorDefinitionVersion_612305(path: JsonNode; query: JsonNode;
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
  var valid_612307 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_612307 = validateParameter(valid_612307, JString, required = true,
                                 default = nil)
  if valid_612307 != nil:
    section.add "ConnectorDefinitionVersionId", valid_612307
  var valid_612308 = path.getOrDefault("ConnectorDefinitionId")
  valid_612308 = validateParameter(valid_612308, JString, required = true,
                                 default = nil)
  if valid_612308 != nil:
    section.add "ConnectorDefinitionId", valid_612308
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612309 = query.getOrDefault("NextToken")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "NextToken", valid_612309
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
  var valid_612310 = header.getOrDefault("X-Amz-Signature")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-Signature", valid_612310
  var valid_612311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-Content-Sha256", valid_612311
  var valid_612312 = header.getOrDefault("X-Amz-Date")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "X-Amz-Date", valid_612312
  var valid_612313 = header.getOrDefault("X-Amz-Credential")
  valid_612313 = validateParameter(valid_612313, JString, required = false,
                                 default = nil)
  if valid_612313 != nil:
    section.add "X-Amz-Credential", valid_612313
  var valid_612314 = header.getOrDefault("X-Amz-Security-Token")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-Security-Token", valid_612314
  var valid_612315 = header.getOrDefault("X-Amz-Algorithm")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Algorithm", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-SignedHeaders", valid_612316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612317: Call_GetConnectorDefinitionVersion_612304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_612317.validator(path, query, header, formData, body)
  let scheme = call_612317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612317.url(scheme.get, call_612317.host, call_612317.base,
                         call_612317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612317, url, valid)

proc call*(call_612318: Call_GetConnectorDefinitionVersion_612304;
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
  var path_612319 = newJObject()
  var query_612320 = newJObject()
  add(path_612319, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_612320, "NextToken", newJString(NextToken))
  add(path_612319, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_612318.call(path_612319, query_612320, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_612304(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_612305, base: "/",
    url: url_GetConnectorDefinitionVersion_612306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_612321 = ref object of OpenApiRestCall_610642
proc url_GetCoreDefinitionVersion_612323(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCoreDefinitionVersion_612322(path: JsonNode; query: JsonNode;
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
  var valid_612324 = path.getOrDefault("CoreDefinitionVersionId")
  valid_612324 = validateParameter(valid_612324, JString, required = true,
                                 default = nil)
  if valid_612324 != nil:
    section.add "CoreDefinitionVersionId", valid_612324
  var valid_612325 = path.getOrDefault("CoreDefinitionId")
  valid_612325 = validateParameter(valid_612325, JString, required = true,
                                 default = nil)
  if valid_612325 != nil:
    section.add "CoreDefinitionId", valid_612325
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
  var valid_612326 = header.getOrDefault("X-Amz-Signature")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "X-Amz-Signature", valid_612326
  var valid_612327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "X-Amz-Content-Sha256", valid_612327
  var valid_612328 = header.getOrDefault("X-Amz-Date")
  valid_612328 = validateParameter(valid_612328, JString, required = false,
                                 default = nil)
  if valid_612328 != nil:
    section.add "X-Amz-Date", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-Credential")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-Credential", valid_612329
  var valid_612330 = header.getOrDefault("X-Amz-Security-Token")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "X-Amz-Security-Token", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-Algorithm")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Algorithm", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-SignedHeaders", valid_612332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612333: Call_GetCoreDefinitionVersion_612321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_612333.validator(path, query, header, formData, body)
  let scheme = call_612333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612333.url(scheme.get, call_612333.host, call_612333.base,
                         call_612333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612333, url, valid)

proc call*(call_612334: Call_GetCoreDefinitionVersion_612321;
          CoreDefinitionVersionId: string; CoreDefinitionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_612335 = newJObject()
  add(path_612335, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  add(path_612335, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_612334.call(path_612335, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_612321(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_612322, base: "/",
    url: url_GetCoreDefinitionVersion_612323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_612336 = ref object of OpenApiRestCall_610642
proc url_GetDeploymentStatus_612338(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStatus_612337(path: JsonNode; query: JsonNode;
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
  var valid_612339 = path.getOrDefault("GroupId")
  valid_612339 = validateParameter(valid_612339, JString, required = true,
                                 default = nil)
  if valid_612339 != nil:
    section.add "GroupId", valid_612339
  var valid_612340 = path.getOrDefault("DeploymentId")
  valid_612340 = validateParameter(valid_612340, JString, required = true,
                                 default = nil)
  if valid_612340 != nil:
    section.add "DeploymentId", valid_612340
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
  var valid_612341 = header.getOrDefault("X-Amz-Signature")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-Signature", valid_612341
  var valid_612342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612342 = validateParameter(valid_612342, JString, required = false,
                                 default = nil)
  if valid_612342 != nil:
    section.add "X-Amz-Content-Sha256", valid_612342
  var valid_612343 = header.getOrDefault("X-Amz-Date")
  valid_612343 = validateParameter(valid_612343, JString, required = false,
                                 default = nil)
  if valid_612343 != nil:
    section.add "X-Amz-Date", valid_612343
  var valid_612344 = header.getOrDefault("X-Amz-Credential")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-Credential", valid_612344
  var valid_612345 = header.getOrDefault("X-Amz-Security-Token")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "X-Amz-Security-Token", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Algorithm")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Algorithm", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-SignedHeaders", valid_612347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612348: Call_GetDeploymentStatus_612336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_612348.validator(path, query, header, formData, body)
  let scheme = call_612348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612348.url(scheme.get, call_612348.host, call_612348.base,
                         call_612348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612348, url, valid)

proc call*(call_612349: Call_GetDeploymentStatus_612336; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_612350 = newJObject()
  add(path_612350, "GroupId", newJString(GroupId))
  add(path_612350, "DeploymentId", newJString(DeploymentId))
  result = call_612349.call(path_612350, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_612336(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_612337, base: "/",
    url: url_GetDeploymentStatus_612338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_612351 = ref object of OpenApiRestCall_610642
proc url_GetDeviceDefinitionVersion_612353(protocol: Scheme; host: string;
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

proc validate_GetDeviceDefinitionVersion_612352(path: JsonNode; query: JsonNode;
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
  var valid_612354 = path.getOrDefault("DeviceDefinitionId")
  valid_612354 = validateParameter(valid_612354, JString, required = true,
                                 default = nil)
  if valid_612354 != nil:
    section.add "DeviceDefinitionId", valid_612354
  var valid_612355 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_612355 = validateParameter(valid_612355, JString, required = true,
                                 default = nil)
  if valid_612355 != nil:
    section.add "DeviceDefinitionVersionId", valid_612355
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612356 = query.getOrDefault("NextToken")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "NextToken", valid_612356
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
  var valid_612357 = header.getOrDefault("X-Amz-Signature")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "X-Amz-Signature", valid_612357
  var valid_612358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "X-Amz-Content-Sha256", valid_612358
  var valid_612359 = header.getOrDefault("X-Amz-Date")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "X-Amz-Date", valid_612359
  var valid_612360 = header.getOrDefault("X-Amz-Credential")
  valid_612360 = validateParameter(valid_612360, JString, required = false,
                                 default = nil)
  if valid_612360 != nil:
    section.add "X-Amz-Credential", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Security-Token")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Security-Token", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Algorithm")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Algorithm", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-SignedHeaders", valid_612363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612364: Call_GetDeviceDefinitionVersion_612351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_612364.validator(path, query, header, formData, body)
  let scheme = call_612364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612364.url(scheme.get, call_612364.host, call_612364.base,
                         call_612364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612364, url, valid)

proc call*(call_612365: Call_GetDeviceDefinitionVersion_612351;
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
  var path_612366 = newJObject()
  var query_612367 = newJObject()
  add(path_612366, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_612367, "NextToken", newJString(NextToken))
  add(path_612366, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_612365.call(path_612366, query_612367, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_612351(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_612352, base: "/",
    url: url_GetDeviceDefinitionVersion_612353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_612368 = ref object of OpenApiRestCall_610642
proc url_GetFunctionDefinitionVersion_612370(protocol: Scheme; host: string;
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

proc validate_GetFunctionDefinitionVersion_612369(path: JsonNode; query: JsonNode;
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
  var valid_612371 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_612371 = validateParameter(valid_612371, JString, required = true,
                                 default = nil)
  if valid_612371 != nil:
    section.add "FunctionDefinitionVersionId", valid_612371
  var valid_612372 = path.getOrDefault("FunctionDefinitionId")
  valid_612372 = validateParameter(valid_612372, JString, required = true,
                                 default = nil)
  if valid_612372 != nil:
    section.add "FunctionDefinitionId", valid_612372
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612373 = query.getOrDefault("NextToken")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "NextToken", valid_612373
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
  var valid_612374 = header.getOrDefault("X-Amz-Signature")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Signature", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-Content-Sha256", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-Date")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-Date", valid_612376
  var valid_612377 = header.getOrDefault("X-Amz-Credential")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "X-Amz-Credential", valid_612377
  var valid_612378 = header.getOrDefault("X-Amz-Security-Token")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "X-Amz-Security-Token", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Algorithm")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Algorithm", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-SignedHeaders", valid_612380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612381: Call_GetFunctionDefinitionVersion_612368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_612381.validator(path, query, header, formData, body)
  let scheme = call_612381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612381.url(scheme.get, call_612381.host, call_612381.base,
                         call_612381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612381, url, valid)

proc call*(call_612382: Call_GetFunctionDefinitionVersion_612368;
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
  var path_612383 = newJObject()
  var query_612384 = newJObject()
  add(path_612383, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_612384, "NextToken", newJString(NextToken))
  add(path_612383, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_612382.call(path_612383, query_612384, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_612368(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_612369, base: "/",
    url: url_GetFunctionDefinitionVersion_612370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_612385 = ref object of OpenApiRestCall_610642
proc url_GetGroupCertificateAuthority_612387(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_612386(path: JsonNode; query: JsonNode;
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
  var valid_612388 = path.getOrDefault("GroupId")
  valid_612388 = validateParameter(valid_612388, JString, required = true,
                                 default = nil)
  if valid_612388 != nil:
    section.add "GroupId", valid_612388
  var valid_612389 = path.getOrDefault("CertificateAuthorityId")
  valid_612389 = validateParameter(valid_612389, JString, required = true,
                                 default = nil)
  if valid_612389 != nil:
    section.add "CertificateAuthorityId", valid_612389
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
  var valid_612390 = header.getOrDefault("X-Amz-Signature")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Signature", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-Content-Sha256", valid_612391
  var valid_612392 = header.getOrDefault("X-Amz-Date")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "X-Amz-Date", valid_612392
  var valid_612393 = header.getOrDefault("X-Amz-Credential")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Credential", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Security-Token")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Security-Token", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Algorithm")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Algorithm", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-SignedHeaders", valid_612396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612397: Call_GetGroupCertificateAuthority_612385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_612397.validator(path, query, header, formData, body)
  let scheme = call_612397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612397.url(scheme.get, call_612397.host, call_612397.base,
                         call_612397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612397, url, valid)

proc call*(call_612398: Call_GetGroupCertificateAuthority_612385; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_612399 = newJObject()
  add(path_612399, "GroupId", newJString(GroupId))
  add(path_612399, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_612398.call(path_612399, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_612385(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_612386, base: "/",
    url: url_GetGroupCertificateAuthority_612387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_612414 = ref object of OpenApiRestCall_610642
proc url_UpdateGroupCertificateConfiguration_612416(protocol: Scheme; host: string;
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

proc validate_UpdateGroupCertificateConfiguration_612415(path: JsonNode;
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
  var valid_612417 = path.getOrDefault("GroupId")
  valid_612417 = validateParameter(valid_612417, JString, required = true,
                                 default = nil)
  if valid_612417 != nil:
    section.add "GroupId", valid_612417
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
  var valid_612418 = header.getOrDefault("X-Amz-Signature")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Signature", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Content-Sha256", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Date")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Date", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Credential")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Credential", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Security-Token")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Security-Token", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Algorithm")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Algorithm", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-SignedHeaders", valid_612424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612426: Call_UpdateGroupCertificateConfiguration_612414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_612426.validator(path, query, header, formData, body)
  let scheme = call_612426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612426.url(scheme.get, call_612426.host, call_612426.base,
                         call_612426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612426, url, valid)

proc call*(call_612427: Call_UpdateGroupCertificateConfiguration_612414;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_612428 = newJObject()
  var body_612429 = newJObject()
  add(path_612428, "GroupId", newJString(GroupId))
  if body != nil:
    body_612429 = body
  result = call_612427.call(path_612428, nil, nil, nil, body_612429)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_612414(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_612415, base: "/",
    url: url_UpdateGroupCertificateConfiguration_612416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_612400 = ref object of OpenApiRestCall_610642
proc url_GetGroupCertificateConfiguration_612402(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateConfiguration_612401(path: JsonNode;
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
  var valid_612403 = path.getOrDefault("GroupId")
  valid_612403 = validateParameter(valid_612403, JString, required = true,
                                 default = nil)
  if valid_612403 != nil:
    section.add "GroupId", valid_612403
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
  var valid_612404 = header.getOrDefault("X-Amz-Signature")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Signature", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Content-Sha256", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Date")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Date", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Credential")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Credential", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Security-Token")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Security-Token", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Algorithm")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Algorithm", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-SignedHeaders", valid_612410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612411: Call_GetGroupCertificateConfiguration_612400;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_612411.validator(path, query, header, formData, body)
  let scheme = call_612411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612411.url(scheme.get, call_612411.host, call_612411.base,
                         call_612411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612411, url, valid)

proc call*(call_612412: Call_GetGroupCertificateConfiguration_612400;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_612413 = newJObject()
  add(path_612413, "GroupId", newJString(GroupId))
  result = call_612412.call(path_612413, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_612400(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_612401, base: "/",
    url: url_GetGroupCertificateConfiguration_612402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_612430 = ref object of OpenApiRestCall_610642
proc url_GetGroupVersion_612432(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupVersion_612431(path: JsonNode; query: JsonNode;
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
  var valid_612433 = path.getOrDefault("GroupVersionId")
  valid_612433 = validateParameter(valid_612433, JString, required = true,
                                 default = nil)
  if valid_612433 != nil:
    section.add "GroupVersionId", valid_612433
  var valid_612434 = path.getOrDefault("GroupId")
  valid_612434 = validateParameter(valid_612434, JString, required = true,
                                 default = nil)
  if valid_612434 != nil:
    section.add "GroupId", valid_612434
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
  var valid_612435 = header.getOrDefault("X-Amz-Signature")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "X-Amz-Signature", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Content-Sha256", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Date")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Date", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Credential")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Credential", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Security-Token")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Security-Token", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Algorithm")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Algorithm", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-SignedHeaders", valid_612441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612442: Call_GetGroupVersion_612430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_612442.validator(path, query, header, formData, body)
  let scheme = call_612442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612442.url(scheme.get, call_612442.host, call_612442.base,
                         call_612442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612442, url, valid)

proc call*(call_612443: Call_GetGroupVersion_612430; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_612444 = newJObject()
  add(path_612444, "GroupVersionId", newJString(GroupVersionId))
  add(path_612444, "GroupId", newJString(GroupId))
  result = call_612443.call(path_612444, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_612430(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_612431, base: "/", url: url_GetGroupVersion_612432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_612445 = ref object of OpenApiRestCall_610642
proc url_GetLoggerDefinitionVersion_612447(protocol: Scheme; host: string;
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

proc validate_GetLoggerDefinitionVersion_612446(path: JsonNode; query: JsonNode;
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
  var valid_612448 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_612448 = validateParameter(valid_612448, JString, required = true,
                                 default = nil)
  if valid_612448 != nil:
    section.add "LoggerDefinitionVersionId", valid_612448
  var valid_612449 = path.getOrDefault("LoggerDefinitionId")
  valid_612449 = validateParameter(valid_612449, JString, required = true,
                                 default = nil)
  if valid_612449 != nil:
    section.add "LoggerDefinitionId", valid_612449
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612450 = query.getOrDefault("NextToken")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "NextToken", valid_612450
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
  var valid_612451 = header.getOrDefault("X-Amz-Signature")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Signature", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Content-Sha256", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Date")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Date", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Credential")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Credential", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Security-Token")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Security-Token", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Algorithm")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Algorithm", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-SignedHeaders", valid_612457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612458: Call_GetLoggerDefinitionVersion_612445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_612458.validator(path, query, header, formData, body)
  let scheme = call_612458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612458.url(scheme.get, call_612458.host, call_612458.base,
                         call_612458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612458, url, valid)

proc call*(call_612459: Call_GetLoggerDefinitionVersion_612445;
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
  var path_612460 = newJObject()
  var query_612461 = newJObject()
  add(path_612460, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_612461, "NextToken", newJString(NextToken))
  add(path_612460, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_612459.call(path_612460, query_612461, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_612445(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_612446, base: "/",
    url: url_GetLoggerDefinitionVersion_612447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_612462 = ref object of OpenApiRestCall_610642
proc url_GetResourceDefinitionVersion_612464(protocol: Scheme; host: string;
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

proc validate_GetResourceDefinitionVersion_612463(path: JsonNode; query: JsonNode;
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
  var valid_612465 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_612465 = validateParameter(valid_612465, JString, required = true,
                                 default = nil)
  if valid_612465 != nil:
    section.add "ResourceDefinitionVersionId", valid_612465
  var valid_612466 = path.getOrDefault("ResourceDefinitionId")
  valid_612466 = validateParameter(valid_612466, JString, required = true,
                                 default = nil)
  if valid_612466 != nil:
    section.add "ResourceDefinitionId", valid_612466
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
  var valid_612467 = header.getOrDefault("X-Amz-Signature")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Signature", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Content-Sha256", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Date")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Date", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Credential")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Credential", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Security-Token")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Security-Token", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Algorithm")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Algorithm", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-SignedHeaders", valid_612473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612474: Call_GetResourceDefinitionVersion_612462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_612474.validator(path, query, header, formData, body)
  let scheme = call_612474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612474.url(scheme.get, call_612474.host, call_612474.base,
                         call_612474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612474, url, valid)

proc call*(call_612475: Call_GetResourceDefinitionVersion_612462;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_612476 = newJObject()
  add(path_612476, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_612476, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_612475.call(path_612476, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_612462(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_612463, base: "/",
    url: url_GetResourceDefinitionVersion_612464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_612477 = ref object of OpenApiRestCall_610642
proc url_GetSubscriptionDefinitionVersion_612479(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinitionVersion_612478(path: JsonNode;
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
  var valid_612480 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_612480 = validateParameter(valid_612480, JString, required = true,
                                 default = nil)
  if valid_612480 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_612480
  var valid_612481 = path.getOrDefault("SubscriptionDefinitionId")
  valid_612481 = validateParameter(valid_612481, JString, required = true,
                                 default = nil)
  if valid_612481 != nil:
    section.add "SubscriptionDefinitionId", valid_612481
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612482 = query.getOrDefault("NextToken")
  valid_612482 = validateParameter(valid_612482, JString, required = false,
                                 default = nil)
  if valid_612482 != nil:
    section.add "NextToken", valid_612482
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
  var valid_612483 = header.getOrDefault("X-Amz-Signature")
  valid_612483 = validateParameter(valid_612483, JString, required = false,
                                 default = nil)
  if valid_612483 != nil:
    section.add "X-Amz-Signature", valid_612483
  var valid_612484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "X-Amz-Content-Sha256", valid_612484
  var valid_612485 = header.getOrDefault("X-Amz-Date")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "X-Amz-Date", valid_612485
  var valid_612486 = header.getOrDefault("X-Amz-Credential")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Credential", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Security-Token")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Security-Token", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Algorithm")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Algorithm", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-SignedHeaders", valid_612489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612490: Call_GetSubscriptionDefinitionVersion_612477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_612490.validator(path, query, header, formData, body)
  let scheme = call_612490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612490.url(scheme.get, call_612490.host, call_612490.base,
                         call_612490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612490, url, valid)

proc call*(call_612491: Call_GetSubscriptionDefinitionVersion_612477;
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
  var path_612492 = newJObject()
  var query_612493 = newJObject()
  add(path_612492, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_612493, "NextToken", newJString(NextToken))
  add(path_612492, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_612491.call(path_612492, query_612493, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_612477(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_612478, base: "/",
    url: url_GetSubscriptionDefinitionVersion_612479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_612494 = ref object of OpenApiRestCall_610642
proc url_ListBulkDeploymentDetailedReports_612496(protocol: Scheme; host: string;
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

proc validate_ListBulkDeploymentDetailedReports_612495(path: JsonNode;
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
  var valid_612497 = path.getOrDefault("BulkDeploymentId")
  valid_612497 = validateParameter(valid_612497, JString, required = true,
                                 default = nil)
  if valid_612497 != nil:
    section.add "BulkDeploymentId", valid_612497
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_612498 = query.getOrDefault("MaxResults")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "MaxResults", valid_612498
  var valid_612499 = query.getOrDefault("NextToken")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "NextToken", valid_612499
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
  var valid_612500 = header.getOrDefault("X-Amz-Signature")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-Signature", valid_612500
  var valid_612501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612501 = validateParameter(valid_612501, JString, required = false,
                                 default = nil)
  if valid_612501 != nil:
    section.add "X-Amz-Content-Sha256", valid_612501
  var valid_612502 = header.getOrDefault("X-Amz-Date")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "X-Amz-Date", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-Credential")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-Credential", valid_612503
  var valid_612504 = header.getOrDefault("X-Amz-Security-Token")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-Security-Token", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Algorithm")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Algorithm", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-SignedHeaders", valid_612506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612507: Call_ListBulkDeploymentDetailedReports_612494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_612507.validator(path, query, header, formData, body)
  let scheme = call_612507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612507.url(scheme.get, call_612507.host, call_612507.base,
                         call_612507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612507, url, valid)

proc call*(call_612508: Call_ListBulkDeploymentDetailedReports_612494;
          BulkDeploymentId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_612509 = newJObject()
  var query_612510 = newJObject()
  add(query_612510, "MaxResults", newJString(MaxResults))
  add(query_612510, "NextToken", newJString(NextToken))
  add(path_612509, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_612508.call(path_612509, query_612510, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_612494(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_612495, base: "/",
    url: url_ListBulkDeploymentDetailedReports_612496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_612526 = ref object of OpenApiRestCall_610642
proc url_StartBulkDeployment_612528(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBulkDeployment_612527(path: JsonNode; query: JsonNode;
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
  var valid_612529 = header.getOrDefault("X-Amz-Signature")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-Signature", valid_612529
  var valid_612530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612530 = validateParameter(valid_612530, JString, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "X-Amz-Content-Sha256", valid_612530
  var valid_612531 = header.getOrDefault("X-Amz-Date")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "X-Amz-Date", valid_612531
  var valid_612532 = header.getOrDefault("X-Amz-Credential")
  valid_612532 = validateParameter(valid_612532, JString, required = false,
                                 default = nil)
  if valid_612532 != nil:
    section.add "X-Amz-Credential", valid_612532
  var valid_612533 = header.getOrDefault("X-Amzn-Client-Token")
  valid_612533 = validateParameter(valid_612533, JString, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "X-Amzn-Client-Token", valid_612533
  var valid_612534 = header.getOrDefault("X-Amz-Security-Token")
  valid_612534 = validateParameter(valid_612534, JString, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "X-Amz-Security-Token", valid_612534
  var valid_612535 = header.getOrDefault("X-Amz-Algorithm")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "X-Amz-Algorithm", valid_612535
  var valid_612536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-SignedHeaders", valid_612536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612538: Call_StartBulkDeployment_612526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_612538.validator(path, query, header, formData, body)
  let scheme = call_612538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612538.url(scheme.get, call_612538.host, call_612538.base,
                         call_612538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612538, url, valid)

proc call*(call_612539: Call_StartBulkDeployment_612526; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_612540 = newJObject()
  if body != nil:
    body_612540 = body
  result = call_612539.call(nil, nil, nil, nil, body_612540)

var startBulkDeployment* = Call_StartBulkDeployment_612526(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_612527, base: "/",
    url: url_StartBulkDeployment_612528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_612511 = ref object of OpenApiRestCall_610642
proc url_ListBulkDeployments_612513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBulkDeployments_612512(path: JsonNode; query: JsonNode;
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
  var valid_612514 = query.getOrDefault("MaxResults")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "MaxResults", valid_612514
  var valid_612515 = query.getOrDefault("NextToken")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "NextToken", valid_612515
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
  var valid_612516 = header.getOrDefault("X-Amz-Signature")
  valid_612516 = validateParameter(valid_612516, JString, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "X-Amz-Signature", valid_612516
  var valid_612517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "X-Amz-Content-Sha256", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-Date")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-Date", valid_612518
  var valid_612519 = header.getOrDefault("X-Amz-Credential")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "X-Amz-Credential", valid_612519
  var valid_612520 = header.getOrDefault("X-Amz-Security-Token")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "X-Amz-Security-Token", valid_612520
  var valid_612521 = header.getOrDefault("X-Amz-Algorithm")
  valid_612521 = validateParameter(valid_612521, JString, required = false,
                                 default = nil)
  if valid_612521 != nil:
    section.add "X-Amz-Algorithm", valid_612521
  var valid_612522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612522 = validateParameter(valid_612522, JString, required = false,
                                 default = nil)
  if valid_612522 != nil:
    section.add "X-Amz-SignedHeaders", valid_612522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612523: Call_ListBulkDeployments_612511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_612523.validator(path, query, header, formData, body)
  let scheme = call_612523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612523.url(scheme.get, call_612523.host, call_612523.base,
                         call_612523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612523, url, valid)

proc call*(call_612524: Call_ListBulkDeployments_612511; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_612525 = newJObject()
  add(query_612525, "MaxResults", newJString(MaxResults))
  add(query_612525, "NextToken", newJString(NextToken))
  result = call_612524.call(nil, query_612525, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_612511(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_612512, base: "/",
    url: url_ListBulkDeployments_612513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612555 = ref object of OpenApiRestCall_610642
proc url_TagResource_612557(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_612556(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612558 = path.getOrDefault("resource-arn")
  valid_612558 = validateParameter(valid_612558, JString, required = true,
                                 default = nil)
  if valid_612558 != nil:
    section.add "resource-arn", valid_612558
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
  var valid_612559 = header.getOrDefault("X-Amz-Signature")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Signature", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-Content-Sha256", valid_612560
  var valid_612561 = header.getOrDefault("X-Amz-Date")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-Date", valid_612561
  var valid_612562 = header.getOrDefault("X-Amz-Credential")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "X-Amz-Credential", valid_612562
  var valid_612563 = header.getOrDefault("X-Amz-Security-Token")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "X-Amz-Security-Token", valid_612563
  var valid_612564 = header.getOrDefault("X-Amz-Algorithm")
  valid_612564 = validateParameter(valid_612564, JString, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "X-Amz-Algorithm", valid_612564
  var valid_612565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "X-Amz-SignedHeaders", valid_612565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612567: Call_TagResource_612555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_612567.validator(path, query, header, formData, body)
  let scheme = call_612567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612567.url(scheme.get, call_612567.host, call_612567.base,
                         call_612567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612567, url, valid)

proc call*(call_612568: Call_TagResource_612555; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_612569 = newJObject()
  var body_612570 = newJObject()
  add(path_612569, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_612570 = body
  result = call_612568.call(path_612569, nil, nil, nil, body_612570)

var tagResource* = Call_TagResource_612555(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_612556,
                                        base: "/", url: url_TagResource_612557,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612541 = ref object of OpenApiRestCall_610642
proc url_ListTagsForResource_612543(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_612542(path: JsonNode; query: JsonNode;
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
  var valid_612544 = path.getOrDefault("resource-arn")
  valid_612544 = validateParameter(valid_612544, JString, required = true,
                                 default = nil)
  if valid_612544 != nil:
    section.add "resource-arn", valid_612544
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
  var valid_612545 = header.getOrDefault("X-Amz-Signature")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-Signature", valid_612545
  var valid_612546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-Content-Sha256", valid_612546
  var valid_612547 = header.getOrDefault("X-Amz-Date")
  valid_612547 = validateParameter(valid_612547, JString, required = false,
                                 default = nil)
  if valid_612547 != nil:
    section.add "X-Amz-Date", valid_612547
  var valid_612548 = header.getOrDefault("X-Amz-Credential")
  valid_612548 = validateParameter(valid_612548, JString, required = false,
                                 default = nil)
  if valid_612548 != nil:
    section.add "X-Amz-Credential", valid_612548
  var valid_612549 = header.getOrDefault("X-Amz-Security-Token")
  valid_612549 = validateParameter(valid_612549, JString, required = false,
                                 default = nil)
  if valid_612549 != nil:
    section.add "X-Amz-Security-Token", valid_612549
  var valid_612550 = header.getOrDefault("X-Amz-Algorithm")
  valid_612550 = validateParameter(valid_612550, JString, required = false,
                                 default = nil)
  if valid_612550 != nil:
    section.add "X-Amz-Algorithm", valid_612550
  var valid_612551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-SignedHeaders", valid_612551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612552: Call_ListTagsForResource_612541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_612552.validator(path, query, header, formData, body)
  let scheme = call_612552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612552.url(scheme.get, call_612552.host, call_612552.base,
                         call_612552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612552, url, valid)

proc call*(call_612553: Call_ListTagsForResource_612541; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_612554 = newJObject()
  add(path_612554, "resource-arn", newJString(resourceArn))
  result = call_612553.call(path_612554, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_612541(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_612542, base: "/",
    url: url_ListTagsForResource_612543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_612571 = ref object of OpenApiRestCall_610642
proc url_ResetDeployments_612573(protocol: Scheme; host: string; base: string;
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

proc validate_ResetDeployments_612572(path: JsonNode; query: JsonNode;
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
  var valid_612574 = path.getOrDefault("GroupId")
  valid_612574 = validateParameter(valid_612574, JString, required = true,
                                 default = nil)
  if valid_612574 != nil:
    section.add "GroupId", valid_612574
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
  var valid_612575 = header.getOrDefault("X-Amz-Signature")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-Signature", valid_612575
  var valid_612576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612576 = validateParameter(valid_612576, JString, required = false,
                                 default = nil)
  if valid_612576 != nil:
    section.add "X-Amz-Content-Sha256", valid_612576
  var valid_612577 = header.getOrDefault("X-Amz-Date")
  valid_612577 = validateParameter(valid_612577, JString, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "X-Amz-Date", valid_612577
  var valid_612578 = header.getOrDefault("X-Amz-Credential")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "X-Amz-Credential", valid_612578
  var valid_612579 = header.getOrDefault("X-Amzn-Client-Token")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "X-Amzn-Client-Token", valid_612579
  var valid_612580 = header.getOrDefault("X-Amz-Security-Token")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Security-Token", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Algorithm")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Algorithm", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-SignedHeaders", valid_612582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612584: Call_ResetDeployments_612571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_612584.validator(path, query, header, formData, body)
  let scheme = call_612584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612584.url(scheme.get, call_612584.host, call_612584.base,
                         call_612584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612584, url, valid)

proc call*(call_612585: Call_ResetDeployments_612571; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_612586 = newJObject()
  var body_612587 = newJObject()
  add(path_612586, "GroupId", newJString(GroupId))
  if body != nil:
    body_612587 = body
  result = call_612585.call(path_612586, nil, nil, nil, body_612587)

var resetDeployments* = Call_ResetDeployments_612571(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_612572, base: "/",
    url: url_ResetDeployments_612573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_612588 = ref object of OpenApiRestCall_610642
proc url_StopBulkDeployment_612590(protocol: Scheme; host: string; base: string;
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

proc validate_StopBulkDeployment_612589(path: JsonNode; query: JsonNode;
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
  var valid_612591 = path.getOrDefault("BulkDeploymentId")
  valid_612591 = validateParameter(valid_612591, JString, required = true,
                                 default = nil)
  if valid_612591 != nil:
    section.add "BulkDeploymentId", valid_612591
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
  var valid_612592 = header.getOrDefault("X-Amz-Signature")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "X-Amz-Signature", valid_612592
  var valid_612593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612593 = validateParameter(valid_612593, JString, required = false,
                                 default = nil)
  if valid_612593 != nil:
    section.add "X-Amz-Content-Sha256", valid_612593
  var valid_612594 = header.getOrDefault("X-Amz-Date")
  valid_612594 = validateParameter(valid_612594, JString, required = false,
                                 default = nil)
  if valid_612594 != nil:
    section.add "X-Amz-Date", valid_612594
  var valid_612595 = header.getOrDefault("X-Amz-Credential")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Credential", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Security-Token")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Security-Token", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Algorithm")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Algorithm", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-SignedHeaders", valid_612598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612599: Call_StopBulkDeployment_612588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_612599.validator(path, query, header, formData, body)
  let scheme = call_612599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612599.url(scheme.get, call_612599.host, call_612599.base,
                         call_612599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612599, url, valid)

proc call*(call_612600: Call_StopBulkDeployment_612588; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_612601 = newJObject()
  add(path_612601, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_612600.call(path_612601, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_612588(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_612589, base: "/",
    url: url_StopBulkDeployment_612590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612602 = ref object of OpenApiRestCall_610642
proc url_UntagResource_612604(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_612603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612605 = path.getOrDefault("resource-arn")
  valid_612605 = validateParameter(valid_612605, JString, required = true,
                                 default = nil)
  if valid_612605 != nil:
    section.add "resource-arn", valid_612605
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_612606 = query.getOrDefault("tagKeys")
  valid_612606 = validateParameter(valid_612606, JArray, required = true, default = nil)
  if valid_612606 != nil:
    section.add "tagKeys", valid_612606
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
  var valid_612607 = header.getOrDefault("X-Amz-Signature")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Signature", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-Content-Sha256", valid_612608
  var valid_612609 = header.getOrDefault("X-Amz-Date")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "X-Amz-Date", valid_612609
  var valid_612610 = header.getOrDefault("X-Amz-Credential")
  valid_612610 = validateParameter(valid_612610, JString, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "X-Amz-Credential", valid_612610
  var valid_612611 = header.getOrDefault("X-Amz-Security-Token")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "X-Amz-Security-Token", valid_612611
  var valid_612612 = header.getOrDefault("X-Amz-Algorithm")
  valid_612612 = validateParameter(valid_612612, JString, required = false,
                                 default = nil)
  if valid_612612 != nil:
    section.add "X-Amz-Algorithm", valid_612612
  var valid_612613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "X-Amz-SignedHeaders", valid_612613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612614: Call_UntagResource_612602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_612614.validator(path, query, header, formData, body)
  let scheme = call_612614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612614.url(scheme.get, call_612614.host, call_612614.base,
                         call_612614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612614, url, valid)

proc call*(call_612615: Call_UntagResource_612602; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_612616 = newJObject()
  var query_612617 = newJObject()
  add(path_612616, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_612617.add "tagKeys", tagKeys
  result = call_612615.call(path_612616, query_612617, nil, nil, nil)

var untagResource* = Call_UntagResource_612602(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_612603,
    base: "/", url: url_UntagResource_612604, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
