
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_AssociateRoleToGroup_606181 = ref object of OpenApiRestCall_605573
proc url_AssociateRoleToGroup_606183(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRoleToGroup_606182(path: JsonNode; query: JsonNode;
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
  var valid_606184 = path.getOrDefault("GroupId")
  valid_606184 = validateParameter(valid_606184, JString, required = true,
                                 default = nil)
  if valid_606184 != nil:
    section.add "GroupId", valid_606184
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
  var valid_606185 = header.getOrDefault("X-Amz-Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Signature", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Content-Sha256", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Date")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Date", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Credential")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Credential", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Security-Token")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Security-Token", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Algorithm")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Algorithm", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_AssociateRoleToGroup_606181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_AssociateRoleToGroup_606181; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_606195 = newJObject()
  var body_606196 = newJObject()
  add(path_606195, "GroupId", newJString(GroupId))
  if body != nil:
    body_606196 = body
  result = call_606194.call(path_606195, nil, nil, nil, body_606196)

var associateRoleToGroup* = Call_AssociateRoleToGroup_606181(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_606182, base: "/",
    url: url_AssociateRoleToGroup_606183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_605911 = ref object of OpenApiRestCall_605573
proc url_GetAssociatedRole_605913(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssociatedRole_605912(path: JsonNode; query: JsonNode;
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
  var valid_606039 = path.getOrDefault("GroupId")
  valid_606039 = validateParameter(valid_606039, JString, required = true,
                                 default = nil)
  if valid_606039 != nil:
    section.add "GroupId", valid_606039
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
  var valid_606040 = header.getOrDefault("X-Amz-Signature")
  valid_606040 = validateParameter(valid_606040, JString, required = false,
                                 default = nil)
  if valid_606040 != nil:
    section.add "X-Amz-Signature", valid_606040
  var valid_606041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Content-Sha256", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Date")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Date", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Credential")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Credential", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Security-Token")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Security-Token", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Algorithm")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Algorithm", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-SignedHeaders", valid_606046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606069: Call_GetAssociatedRole_605911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_606069.validator(path, query, header, formData, body)
  let scheme = call_606069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606069.url(scheme.get, call_606069.host, call_606069.base,
                         call_606069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606069, url, valid)

proc call*(call_606140: Call_GetAssociatedRole_605911; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_606141 = newJObject()
  add(path_606141, "GroupId", newJString(GroupId))
  result = call_606140.call(path_606141, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_605911(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_605912, base: "/",
    url: url_GetAssociatedRole_605913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_606197 = ref object of OpenApiRestCall_605573
proc url_DisassociateRoleFromGroup_606199(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_606198(path: JsonNode; query: JsonNode;
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
  var valid_606200 = path.getOrDefault("GroupId")
  valid_606200 = validateParameter(valid_606200, JString, required = true,
                                 default = nil)
  if valid_606200 != nil:
    section.add "GroupId", valid_606200
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
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_DisassociateRoleFromGroup_606197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_DisassociateRoleFromGroup_606197; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_606210 = newJObject()
  add(path_606210, "GroupId", newJString(GroupId))
  result = call_606209.call(path_606210, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_606197(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_606198, base: "/",
    url: url_DisassociateRoleFromGroup_606199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_606223 = ref object of OpenApiRestCall_605573
proc url_AssociateServiceRoleToAccount_606225(protocol: Scheme; host: string;
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

proc validate_AssociateServiceRoleToAccount_606224(path: JsonNode; query: JsonNode;
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
  var valid_606226 = header.getOrDefault("X-Amz-Signature")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Signature", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Content-Sha256", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Date")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Date", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Credential")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Credential", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Security-Token")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Security-Token", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Algorithm")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Algorithm", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-SignedHeaders", valid_606232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606234: Call_AssociateServiceRoleToAccount_606223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_606234.validator(path, query, header, formData, body)
  let scheme = call_606234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606234.url(scheme.get, call_606234.host, call_606234.base,
                         call_606234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606234, url, valid)

proc call*(call_606235: Call_AssociateServiceRoleToAccount_606223; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_606236 = newJObject()
  if body != nil:
    body_606236 = body
  result = call_606235.call(nil, nil, nil, nil, body_606236)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_606223(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_606224, base: "/",
    url: url_AssociateServiceRoleToAccount_606225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_606211 = ref object of OpenApiRestCall_605573
proc url_GetServiceRoleForAccount_606213(protocol: Scheme; host: string;
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

proc validate_GetServiceRoleForAccount_606212(path: JsonNode; query: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Signature")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Signature", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Content-Sha256", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Date")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Date", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Credential")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Credential", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Security-Token")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Security-Token", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Algorithm")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Algorithm", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-SignedHeaders", valid_606220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606221: Call_GetServiceRoleForAccount_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_606221.validator(path, query, header, formData, body)
  let scheme = call_606221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606221.url(scheme.get, call_606221.host, call_606221.base,
                         call_606221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606221, url, valid)

proc call*(call_606222: Call_GetServiceRoleForAccount_606211): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_606222.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_606211(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_606212, base: "/",
    url: url_GetServiceRoleForAccount_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_606237 = ref object of OpenApiRestCall_605573
proc url_DisassociateServiceRoleFromAccount_606239(protocol: Scheme; host: string;
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

proc validate_DisassociateServiceRoleFromAccount_606238(path: JsonNode;
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
  var valid_606240 = header.getOrDefault("X-Amz-Signature")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Signature", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Content-Sha256", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Date")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Date", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Credential")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Credential", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Security-Token")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Security-Token", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Algorithm")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Algorithm", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-SignedHeaders", valid_606246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606247: Call_DisassociateServiceRoleFromAccount_606237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_606247.validator(path, query, header, formData, body)
  let scheme = call_606247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606247.url(scheme.get, call_606247.host, call_606247.base,
                         call_606247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606247, url, valid)

proc call*(call_606248: Call_DisassociateServiceRoleFromAccount_606237): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_606248.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_606237(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_606238, base: "/",
    url: url_DisassociateServiceRoleFromAccount_606239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_606264 = ref object of OpenApiRestCall_605573
proc url_CreateConnectorDefinition_606266(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinition_606265(path: JsonNode; query: JsonNode;
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
  var valid_606267 = header.getOrDefault("X-Amz-Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Signature", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Content-Sha256", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Date")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Date", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Credential")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Credential", valid_606270
  var valid_606271 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amzn-Client-Token", valid_606271
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

proc call*(call_606276: Call_CreateConnectorDefinition_606264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateConnectorDefinition_606264; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_606278 = newJObject()
  if body != nil:
    body_606278 = body
  result = call_606277.call(nil, nil, nil, nil, body_606278)

var createConnectorDefinition* = Call_CreateConnectorDefinition_606264(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_606265, base: "/",
    url: url_CreateConnectorDefinition_606266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_606249 = ref object of OpenApiRestCall_605573
proc url_ListConnectorDefinitions_606251(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitions_606250(path: JsonNode; query: JsonNode;
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
  var valid_606252 = query.getOrDefault("MaxResults")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "MaxResults", valid_606252
  var valid_606253 = query.getOrDefault("NextToken")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "NextToken", valid_606253
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
  var valid_606254 = header.getOrDefault("X-Amz-Signature")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Signature", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Content-Sha256", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Date")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Date", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Credential")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Credential", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Security-Token")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Security-Token", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Algorithm")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Algorithm", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-SignedHeaders", valid_606260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606261: Call_ListConnectorDefinitions_606249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_606261.validator(path, query, header, formData, body)
  let scheme = call_606261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606261.url(scheme.get, call_606261.host, call_606261.base,
                         call_606261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606261, url, valid)

proc call*(call_606262: Call_ListConnectorDefinitions_606249;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606263 = newJObject()
  add(query_606263, "MaxResults", newJString(MaxResults))
  add(query_606263, "NextToken", newJString(NextToken))
  result = call_606262.call(nil, query_606263, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_606249(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_606250, base: "/",
    url: url_ListConnectorDefinitions_606251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_606296 = ref object of OpenApiRestCall_605573
proc url_CreateConnectorDefinitionVersion_606298(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinitionVersion_606297(path: JsonNode;
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
  var valid_606299 = path.getOrDefault("ConnectorDefinitionId")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = nil)
  if valid_606299 != nil:
    section.add "ConnectorDefinitionId", valid_606299
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
  var valid_606300 = header.getOrDefault("X-Amz-Signature")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Signature", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Content-Sha256", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Date")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Date", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Credential")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Credential", valid_606303
  var valid_606304 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amzn-Client-Token", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606309: Call_CreateConnectorDefinitionVersion_606296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_606309.validator(path, query, header, formData, body)
  let scheme = call_606309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606309.url(scheme.get, call_606309.host, call_606309.base,
                         call_606309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606309, url, valid)

proc call*(call_606310: Call_CreateConnectorDefinitionVersion_606296;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_606311 = newJObject()
  var body_606312 = newJObject()
  add(path_606311, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_606312 = body
  result = call_606310.call(path_606311, nil, nil, nil, body_606312)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_606296(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_606297, base: "/",
    url: url_CreateConnectorDefinitionVersion_606298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_606279 = ref object of OpenApiRestCall_605573
proc url_ListConnectorDefinitionVersions_606281(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitionVersions_606280(path: JsonNode;
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
  var valid_606282 = path.getOrDefault("ConnectorDefinitionId")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "ConnectorDefinitionId", valid_606282
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606283 = query.getOrDefault("MaxResults")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "MaxResults", valid_606283
  var valid_606284 = query.getOrDefault("NextToken")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "NextToken", valid_606284
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
  var valid_606285 = header.getOrDefault("X-Amz-Signature")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Signature", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Content-Sha256", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Date")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Date", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Credential")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Credential", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Security-Token")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Security-Token", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Algorithm")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Algorithm", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-SignedHeaders", valid_606291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_ListConnectorDefinitionVersions_606279;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_ListConnectorDefinitionVersions_606279;
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
  var path_606294 = newJObject()
  var query_606295 = newJObject()
  add(query_606295, "MaxResults", newJString(MaxResults))
  add(query_606295, "NextToken", newJString(NextToken))
  add(path_606294, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_606293.call(path_606294, query_606295, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_606279(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_606280, base: "/",
    url: url_ListConnectorDefinitionVersions_606281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_606328 = ref object of OpenApiRestCall_605573
proc url_CreateCoreDefinition_606330(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCoreDefinition_606329(path: JsonNode; query: JsonNode;
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
  var valid_606331 = header.getOrDefault("X-Amz-Signature")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Signature", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Content-Sha256", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Date")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Date", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Credential")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Credential", valid_606334
  var valid_606335 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amzn-Client-Token", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Security-Token")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Security-Token", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Algorithm")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Algorithm", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-SignedHeaders", valid_606338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606340: Call_CreateCoreDefinition_606328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_606340.validator(path, query, header, formData, body)
  let scheme = call_606340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606340.url(scheme.get, call_606340.host, call_606340.base,
                         call_606340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606340, url, valid)

proc call*(call_606341: Call_CreateCoreDefinition_606328; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_606342 = newJObject()
  if body != nil:
    body_606342 = body
  result = call_606341.call(nil, nil, nil, nil, body_606342)

var createCoreDefinition* = Call_CreateCoreDefinition_606328(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_606329, base: "/",
    url: url_CreateCoreDefinition_606330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_606313 = ref object of OpenApiRestCall_605573
proc url_ListCoreDefinitions_606315(protocol: Scheme; host: string; base: string;
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

proc validate_ListCoreDefinitions_606314(path: JsonNode; query: JsonNode;
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
  var valid_606316 = query.getOrDefault("MaxResults")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "MaxResults", valid_606316
  var valid_606317 = query.getOrDefault("NextToken")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "NextToken", valid_606317
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
  var valid_606318 = header.getOrDefault("X-Amz-Signature")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Signature", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Content-Sha256", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Date")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Date", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Credential")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Credential", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Security-Token")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Security-Token", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Algorithm")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Algorithm", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-SignedHeaders", valid_606324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606325: Call_ListCoreDefinitions_606313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_606325.validator(path, query, header, formData, body)
  let scheme = call_606325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606325.url(scheme.get, call_606325.host, call_606325.base,
                         call_606325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606325, url, valid)

proc call*(call_606326: Call_ListCoreDefinitions_606313; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606327 = newJObject()
  add(query_606327, "MaxResults", newJString(MaxResults))
  add(query_606327, "NextToken", newJString(NextToken))
  result = call_606326.call(nil, query_606327, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_606313(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_606314, base: "/",
    url: url_ListCoreDefinitions_606315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_606360 = ref object of OpenApiRestCall_605573
proc url_CreateCoreDefinitionVersion_606362(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_606361(path: JsonNode; query: JsonNode;
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
  var valid_606363 = path.getOrDefault("CoreDefinitionId")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = nil)
  if valid_606363 != nil:
    section.add "CoreDefinitionId", valid_606363
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
  var valid_606364 = header.getOrDefault("X-Amz-Signature")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Signature", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Content-Sha256", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Date")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Date", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Credential")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Credential", valid_606367
  var valid_606368 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amzn-Client-Token", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CreateCoreDefinitionVersion_606360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CreateCoreDefinitionVersion_606360;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_606375 = newJObject()
  var body_606376 = newJObject()
  add(path_606375, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_606376 = body
  result = call_606374.call(path_606375, nil, nil, nil, body_606376)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_606360(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_606361, base: "/",
    url: url_CreateCoreDefinitionVersion_606362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_606343 = ref object of OpenApiRestCall_605573
proc url_ListCoreDefinitionVersions_606345(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_606344(path: JsonNode; query: JsonNode;
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
  var valid_606346 = path.getOrDefault("CoreDefinitionId")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "CoreDefinitionId", valid_606346
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606347 = query.getOrDefault("MaxResults")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "MaxResults", valid_606347
  var valid_606348 = query.getOrDefault("NextToken")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "NextToken", valid_606348
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
  var valid_606349 = header.getOrDefault("X-Amz-Signature")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Signature", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Content-Sha256", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Date")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Date", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Credential")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Credential", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Security-Token")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Security-Token", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Algorithm")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Algorithm", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-SignedHeaders", valid_606355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606356: Call_ListCoreDefinitionVersions_606343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_606356.validator(path, query, header, formData, body)
  let scheme = call_606356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606356.url(scheme.get, call_606356.host, call_606356.base,
                         call_606356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606356, url, valid)

proc call*(call_606357: Call_ListCoreDefinitionVersions_606343;
          CoreDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_606358 = newJObject()
  var query_606359 = newJObject()
  add(query_606359, "MaxResults", newJString(MaxResults))
  add(query_606359, "NextToken", newJString(NextToken))
  add(path_606358, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_606357.call(path_606358, query_606359, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_606343(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_606344, base: "/",
    url: url_ListCoreDefinitionVersions_606345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_606394 = ref object of OpenApiRestCall_605573
proc url_CreateDeployment_606396(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_606395(path: JsonNode; query: JsonNode;
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
  var valid_606397 = path.getOrDefault("GroupId")
  valid_606397 = validateParameter(valid_606397, JString, required = true,
                                 default = nil)
  if valid_606397 != nil:
    section.add "GroupId", valid_606397
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
  var valid_606398 = header.getOrDefault("X-Amz-Signature")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Signature", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Content-Sha256", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Date")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Date", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Credential")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Credential", valid_606401
  var valid_606402 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amzn-Client-Token", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Security-Token")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Security-Token", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Algorithm")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Algorithm", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-SignedHeaders", valid_606405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_CreateDeployment_606394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_CreateDeployment_606394; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_606409 = newJObject()
  var body_606410 = newJObject()
  add(path_606409, "GroupId", newJString(GroupId))
  if body != nil:
    body_606410 = body
  result = call_606408.call(path_606409, nil, nil, nil, body_606410)

var createDeployment* = Call_CreateDeployment_606394(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_606395, base: "/",
    url: url_CreateDeployment_606396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_606377 = ref object of OpenApiRestCall_605573
proc url_ListDeployments_606379(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_606378(path: JsonNode; query: JsonNode;
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
  var valid_606380 = path.getOrDefault("GroupId")
  valid_606380 = validateParameter(valid_606380, JString, required = true,
                                 default = nil)
  if valid_606380 != nil:
    section.add "GroupId", valid_606380
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606381 = query.getOrDefault("MaxResults")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "MaxResults", valid_606381
  var valid_606382 = query.getOrDefault("NextToken")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "NextToken", valid_606382
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
  var valid_606383 = header.getOrDefault("X-Amz-Signature")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Signature", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Content-Sha256", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Date")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Date", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Credential")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Credential", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Security-Token")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Security-Token", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Algorithm")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Algorithm", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-SignedHeaders", valid_606389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606390: Call_ListDeployments_606377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_606390.validator(path, query, header, formData, body)
  let scheme = call_606390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606390.url(scheme.get, call_606390.host, call_606390.base,
                         call_606390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606390, url, valid)

proc call*(call_606391: Call_ListDeployments_606377; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_606392 = newJObject()
  var query_606393 = newJObject()
  add(path_606392, "GroupId", newJString(GroupId))
  add(query_606393, "MaxResults", newJString(MaxResults))
  add(query_606393, "NextToken", newJString(NextToken))
  result = call_606391.call(path_606392, query_606393, nil, nil, nil)

var listDeployments* = Call_ListDeployments_606377(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_606378, base: "/", url: url_ListDeployments_606379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_606426 = ref object of OpenApiRestCall_605573
proc url_CreateDeviceDefinition_606428(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeviceDefinition_606427(path: JsonNode; query: JsonNode;
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
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amzn-Client-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Security-Token")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Security-Token", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Algorithm")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Algorithm", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-SignedHeaders", valid_606436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606438: Call_CreateDeviceDefinition_606426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_606438.validator(path, query, header, formData, body)
  let scheme = call_606438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606438.url(scheme.get, call_606438.host, call_606438.base,
                         call_606438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606438, url, valid)

proc call*(call_606439: Call_CreateDeviceDefinition_606426; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_606440 = newJObject()
  if body != nil:
    body_606440 = body
  result = call_606439.call(nil, nil, nil, nil, body_606440)

var createDeviceDefinition* = Call_CreateDeviceDefinition_606426(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_606427, base: "/",
    url: url_CreateDeviceDefinition_606428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_606411 = ref object of OpenApiRestCall_605573
proc url_ListDeviceDefinitions_606413(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeviceDefinitions_606412(path: JsonNode; query: JsonNode;
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
  var valid_606414 = query.getOrDefault("MaxResults")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "MaxResults", valid_606414
  var valid_606415 = query.getOrDefault("NextToken")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "NextToken", valid_606415
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
  var valid_606416 = header.getOrDefault("X-Amz-Signature")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Signature", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Content-Sha256", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Date")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Date", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Credential")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Credential", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Security-Token")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Security-Token", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Algorithm")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Algorithm", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-SignedHeaders", valid_606422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606423: Call_ListDeviceDefinitions_606411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_606423.validator(path, query, header, formData, body)
  let scheme = call_606423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606423.url(scheme.get, call_606423.host, call_606423.base,
                         call_606423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606423, url, valid)

proc call*(call_606424: Call_ListDeviceDefinitions_606411; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606425 = newJObject()
  add(query_606425, "MaxResults", newJString(MaxResults))
  add(query_606425, "NextToken", newJString(NextToken))
  result = call_606424.call(nil, query_606425, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_606411(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_606412, base: "/",
    url: url_ListDeviceDefinitions_606413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_606458 = ref object of OpenApiRestCall_605573
proc url_CreateDeviceDefinitionVersion_606460(protocol: Scheme; host: string;
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

proc validate_CreateDeviceDefinitionVersion_606459(path: JsonNode; query: JsonNode;
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
  var valid_606461 = path.getOrDefault("DeviceDefinitionId")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = nil)
  if valid_606461 != nil:
    section.add "DeviceDefinitionId", valid_606461
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
  var valid_606462 = header.getOrDefault("X-Amz-Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Signature", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Content-Sha256", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Date")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Date", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Credential")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Credential", valid_606465
  var valid_606466 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amzn-Client-Token", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606471: Call_CreateDeviceDefinitionVersion_606458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_606471.validator(path, query, header, formData, body)
  let scheme = call_606471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606471.url(scheme.get, call_606471.host, call_606471.base,
                         call_606471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606471, url, valid)

proc call*(call_606472: Call_CreateDeviceDefinitionVersion_606458;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_606473 = newJObject()
  var body_606474 = newJObject()
  add(path_606473, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_606474 = body
  result = call_606472.call(path_606473, nil, nil, nil, body_606474)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_606458(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_606459, base: "/",
    url: url_CreateDeviceDefinitionVersion_606460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_606441 = ref object of OpenApiRestCall_605573
proc url_ListDeviceDefinitionVersions_606443(protocol: Scheme; host: string;
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

proc validate_ListDeviceDefinitionVersions_606442(path: JsonNode; query: JsonNode;
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
  var valid_606444 = path.getOrDefault("DeviceDefinitionId")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "DeviceDefinitionId", valid_606444
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606445 = query.getOrDefault("MaxResults")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "MaxResults", valid_606445
  var valid_606446 = query.getOrDefault("NextToken")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "NextToken", valid_606446
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
  var valid_606447 = header.getOrDefault("X-Amz-Signature")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Signature", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Content-Sha256", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Date")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Date", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Credential")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Credential", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Security-Token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Security-Token", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Algorithm")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Algorithm", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-SignedHeaders", valid_606453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606454: Call_ListDeviceDefinitionVersions_606441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_606454.validator(path, query, header, formData, body)
  let scheme = call_606454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606454.url(scheme.get, call_606454.host, call_606454.base,
                         call_606454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606454, url, valid)

proc call*(call_606455: Call_ListDeviceDefinitionVersions_606441;
          DeviceDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_606456 = newJObject()
  var query_606457 = newJObject()
  add(path_606456, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_606457, "MaxResults", newJString(MaxResults))
  add(query_606457, "NextToken", newJString(NextToken))
  result = call_606455.call(path_606456, query_606457, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_606441(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_606442, base: "/",
    url: url_ListDeviceDefinitionVersions_606443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_606490 = ref object of OpenApiRestCall_605573
proc url_CreateFunctionDefinition_606492(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinition_606491(path: JsonNode; query: JsonNode;
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
  var valid_606493 = header.getOrDefault("X-Amz-Signature")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Signature", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Content-Sha256", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Date")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Date", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Credential")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Credential", valid_606496
  var valid_606497 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amzn-Client-Token", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Security-Token")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Security-Token", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Algorithm")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Algorithm", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-SignedHeaders", valid_606500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606502: Call_CreateFunctionDefinition_606490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_606502.validator(path, query, header, formData, body)
  let scheme = call_606502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606502.url(scheme.get, call_606502.host, call_606502.base,
                         call_606502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606502, url, valid)

proc call*(call_606503: Call_CreateFunctionDefinition_606490; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_606504 = newJObject()
  if body != nil:
    body_606504 = body
  result = call_606503.call(nil, nil, nil, nil, body_606504)

var createFunctionDefinition* = Call_CreateFunctionDefinition_606490(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_606491, base: "/",
    url: url_CreateFunctionDefinition_606492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_606475 = ref object of OpenApiRestCall_605573
proc url_ListFunctionDefinitions_606477(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctionDefinitions_606476(path: JsonNode; query: JsonNode;
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
  var valid_606478 = query.getOrDefault("MaxResults")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "MaxResults", valid_606478
  var valid_606479 = query.getOrDefault("NextToken")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "NextToken", valid_606479
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
  var valid_606480 = header.getOrDefault("X-Amz-Signature")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Signature", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Content-Sha256", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Date")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Date", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Credential")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Credential", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Security-Token")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Security-Token", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Algorithm")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Algorithm", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-SignedHeaders", valid_606486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606487: Call_ListFunctionDefinitions_606475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_606487.validator(path, query, header, formData, body)
  let scheme = call_606487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606487.url(scheme.get, call_606487.host, call_606487.base,
                         call_606487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606487, url, valid)

proc call*(call_606488: Call_ListFunctionDefinitions_606475;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606489 = newJObject()
  add(query_606489, "MaxResults", newJString(MaxResults))
  add(query_606489, "NextToken", newJString(NextToken))
  result = call_606488.call(nil, query_606489, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_606475(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_606476, base: "/",
    url: url_ListFunctionDefinitions_606477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_606522 = ref object of OpenApiRestCall_605573
proc url_CreateFunctionDefinitionVersion_606524(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinitionVersion_606523(path: JsonNode;
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
  var valid_606525 = path.getOrDefault("FunctionDefinitionId")
  valid_606525 = validateParameter(valid_606525, JString, required = true,
                                 default = nil)
  if valid_606525 != nil:
    section.add "FunctionDefinitionId", valid_606525
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
  var valid_606526 = header.getOrDefault("X-Amz-Signature")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Signature", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Content-Sha256", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Date")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Date", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Credential")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Credential", valid_606529
  var valid_606530 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amzn-Client-Token", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_CreateFunctionDefinitionVersion_606522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_CreateFunctionDefinitionVersion_606522;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_606537 = newJObject()
  var body_606538 = newJObject()
  add(path_606537, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_606538 = body
  result = call_606536.call(path_606537, nil, nil, nil, body_606538)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_606522(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_606523, base: "/",
    url: url_CreateFunctionDefinitionVersion_606524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_606505 = ref object of OpenApiRestCall_605573
proc url_ListFunctionDefinitionVersions_606507(protocol: Scheme; host: string;
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

proc validate_ListFunctionDefinitionVersions_606506(path: JsonNode;
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
  var valid_606508 = path.getOrDefault("FunctionDefinitionId")
  valid_606508 = validateParameter(valid_606508, JString, required = true,
                                 default = nil)
  if valid_606508 != nil:
    section.add "FunctionDefinitionId", valid_606508
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606509 = query.getOrDefault("MaxResults")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "MaxResults", valid_606509
  var valid_606510 = query.getOrDefault("NextToken")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "NextToken", valid_606510
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
  var valid_606511 = header.getOrDefault("X-Amz-Signature")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Signature", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Content-Sha256", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Date")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Date", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Credential")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Credential", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Security-Token")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Security-Token", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Algorithm")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Algorithm", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-SignedHeaders", valid_606517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606518: Call_ListFunctionDefinitionVersions_606505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_606518.validator(path, query, header, formData, body)
  let scheme = call_606518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606518.url(scheme.get, call_606518.host, call_606518.base,
                         call_606518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606518, url, valid)

proc call*(call_606519: Call_ListFunctionDefinitionVersions_606505;
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
  var path_606520 = newJObject()
  var query_606521 = newJObject()
  add(query_606521, "MaxResults", newJString(MaxResults))
  add(query_606521, "NextToken", newJString(NextToken))
  add(path_606520, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_606519.call(path_606520, query_606521, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_606505(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_606506, base: "/",
    url: url_ListFunctionDefinitionVersions_606507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_606554 = ref object of OpenApiRestCall_605573
proc url_CreateGroup_606556(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_606555(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606557 = header.getOrDefault("X-Amz-Signature")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Signature", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Content-Sha256", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Date")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Date", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Credential")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Credential", valid_606560
  var valid_606561 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amzn-Client-Token", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Security-Token")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Security-Token", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Algorithm")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Algorithm", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-SignedHeaders", valid_606564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606566: Call_CreateGroup_606554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_606566.validator(path, query, header, formData, body)
  let scheme = call_606566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606566.url(scheme.get, call_606566.host, call_606566.base,
                         call_606566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606566, url, valid)

proc call*(call_606567: Call_CreateGroup_606554; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_606568 = newJObject()
  if body != nil:
    body_606568 = body
  result = call_606567.call(nil, nil, nil, nil, body_606568)

var createGroup* = Call_CreateGroup_606554(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_606555,
                                        base: "/", url: url_CreateGroup_606556,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_606539 = ref object of OpenApiRestCall_605573
proc url_ListGroups_606541(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_606540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606542 = query.getOrDefault("MaxResults")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "MaxResults", valid_606542
  var valid_606543 = query.getOrDefault("NextToken")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "NextToken", valid_606543
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
  var valid_606544 = header.getOrDefault("X-Amz-Signature")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Signature", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Content-Sha256", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Date")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Date", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Credential")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Credential", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Security-Token")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Security-Token", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Algorithm")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Algorithm", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-SignedHeaders", valid_606550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606551: Call_ListGroups_606539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_606551.validator(path, query, header, formData, body)
  let scheme = call_606551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606551.url(scheme.get, call_606551.host, call_606551.base,
                         call_606551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606551, url, valid)

proc call*(call_606552: Call_ListGroups_606539; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606553 = newJObject()
  add(query_606553, "MaxResults", newJString(MaxResults))
  add(query_606553, "NextToken", newJString(NextToken))
  result = call_606552.call(nil, query_606553, nil, nil, nil)

var listGroups* = Call_ListGroups_606539(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_606540,
                                      base: "/", url: url_ListGroups_606541,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_606583 = ref object of OpenApiRestCall_605573
proc url_CreateGroupCertificateAuthority_606585(protocol: Scheme; host: string;
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

proc validate_CreateGroupCertificateAuthority_606584(path: JsonNode;
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
  var valid_606586 = path.getOrDefault("GroupId")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = nil)
  if valid_606586 != nil:
    section.add "GroupId", valid_606586
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
  var valid_606587 = header.getOrDefault("X-Amz-Signature")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Signature", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Content-Sha256", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Date")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Date", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Credential")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Credential", valid_606590
  var valid_606591 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amzn-Client-Token", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Security-Token")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Security-Token", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Algorithm")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Algorithm", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-SignedHeaders", valid_606594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606595: Call_CreateGroupCertificateAuthority_606583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_606595.validator(path, query, header, formData, body)
  let scheme = call_606595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606595.url(scheme.get, call_606595.host, call_606595.base,
                         call_606595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606595, url, valid)

proc call*(call_606596: Call_CreateGroupCertificateAuthority_606583;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_606597 = newJObject()
  add(path_606597, "GroupId", newJString(GroupId))
  result = call_606596.call(path_606597, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_606583(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_606584, base: "/",
    url: url_CreateGroupCertificateAuthority_606585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_606569 = ref object of OpenApiRestCall_605573
proc url_ListGroupCertificateAuthorities_606571(protocol: Scheme; host: string;
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

proc validate_ListGroupCertificateAuthorities_606570(path: JsonNode;
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
  var valid_606572 = path.getOrDefault("GroupId")
  valid_606572 = validateParameter(valid_606572, JString, required = true,
                                 default = nil)
  if valid_606572 != nil:
    section.add "GroupId", valid_606572
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
  var valid_606573 = header.getOrDefault("X-Amz-Signature")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Signature", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Content-Sha256", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Date")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Date", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Credential")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Credential", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Security-Token")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Security-Token", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Algorithm")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Algorithm", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-SignedHeaders", valid_606579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606580: Call_ListGroupCertificateAuthorities_606569;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_606580.validator(path, query, header, formData, body)
  let scheme = call_606580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606580.url(scheme.get, call_606580.host, call_606580.base,
                         call_606580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606580, url, valid)

proc call*(call_606581: Call_ListGroupCertificateAuthorities_606569;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_606582 = newJObject()
  add(path_606582, "GroupId", newJString(GroupId))
  result = call_606581.call(path_606582, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_606569(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_606570, base: "/",
    url: url_ListGroupCertificateAuthorities_606571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_606615 = ref object of OpenApiRestCall_605573
proc url_CreateGroupVersion_606617(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupVersion_606616(path: JsonNode; query: JsonNode;
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
  var valid_606618 = path.getOrDefault("GroupId")
  valid_606618 = validateParameter(valid_606618, JString, required = true,
                                 default = nil)
  if valid_606618 != nil:
    section.add "GroupId", valid_606618
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
  var valid_606619 = header.getOrDefault("X-Amz-Signature")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Signature", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Content-Sha256", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Date")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Date", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Credential")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Credential", valid_606622
  var valid_606623 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amzn-Client-Token", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_CreateGroupVersion_606615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_CreateGroupVersion_606615; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_606630 = newJObject()
  var body_606631 = newJObject()
  add(path_606630, "GroupId", newJString(GroupId))
  if body != nil:
    body_606631 = body
  result = call_606629.call(path_606630, nil, nil, nil, body_606631)

var createGroupVersion* = Call_CreateGroupVersion_606615(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_606616, base: "/",
    url: url_CreateGroupVersion_606617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_606598 = ref object of OpenApiRestCall_605573
proc url_ListGroupVersions_606600(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupVersions_606599(path: JsonNode; query: JsonNode;
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
  var valid_606601 = path.getOrDefault("GroupId")
  valid_606601 = validateParameter(valid_606601, JString, required = true,
                                 default = nil)
  if valid_606601 != nil:
    section.add "GroupId", valid_606601
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606602 = query.getOrDefault("MaxResults")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "MaxResults", valid_606602
  var valid_606603 = query.getOrDefault("NextToken")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "NextToken", valid_606603
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
  var valid_606604 = header.getOrDefault("X-Amz-Signature")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Signature", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Content-Sha256", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Date")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Date", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Credential")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Credential", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Security-Token")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Security-Token", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Algorithm")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Algorithm", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-SignedHeaders", valid_606610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606611: Call_ListGroupVersions_606598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_606611.validator(path, query, header, formData, body)
  let scheme = call_606611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606611.url(scheme.get, call_606611.host, call_606611.base,
                         call_606611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606611, url, valid)

proc call*(call_606612: Call_ListGroupVersions_606598; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_606613 = newJObject()
  var query_606614 = newJObject()
  add(path_606613, "GroupId", newJString(GroupId))
  add(query_606614, "MaxResults", newJString(MaxResults))
  add(query_606614, "NextToken", newJString(NextToken))
  result = call_606612.call(path_606613, query_606614, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_606598(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_606599, base: "/",
    url: url_ListGroupVersions_606600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_606647 = ref object of OpenApiRestCall_605573
proc url_CreateLoggerDefinition_606649(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLoggerDefinition_606648(path: JsonNode; query: JsonNode;
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
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amzn-Client-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Security-Token")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Security-Token", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Algorithm")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Algorithm", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-SignedHeaders", valid_606657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606659: Call_CreateLoggerDefinition_606647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_606659.validator(path, query, header, formData, body)
  let scheme = call_606659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606659.url(scheme.get, call_606659.host, call_606659.base,
                         call_606659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606659, url, valid)

proc call*(call_606660: Call_CreateLoggerDefinition_606647; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_606661 = newJObject()
  if body != nil:
    body_606661 = body
  result = call_606660.call(nil, nil, nil, nil, body_606661)

var createLoggerDefinition* = Call_CreateLoggerDefinition_606647(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_606648, base: "/",
    url: url_CreateLoggerDefinition_606649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_606632 = ref object of OpenApiRestCall_605573
proc url_ListLoggerDefinitions_606634(protocol: Scheme; host: string; base: string;
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

proc validate_ListLoggerDefinitions_606633(path: JsonNode; query: JsonNode;
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
  var valid_606635 = query.getOrDefault("MaxResults")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "MaxResults", valid_606635
  var valid_606636 = query.getOrDefault("NextToken")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "NextToken", valid_606636
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
  var valid_606637 = header.getOrDefault("X-Amz-Signature")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Signature", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Content-Sha256", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Date")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Date", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Credential")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Credential", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Security-Token")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Security-Token", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Algorithm")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Algorithm", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-SignedHeaders", valid_606643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606644: Call_ListLoggerDefinitions_606632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_606644.validator(path, query, header, formData, body)
  let scheme = call_606644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606644.url(scheme.get, call_606644.host, call_606644.base,
                         call_606644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606644, url, valid)

proc call*(call_606645: Call_ListLoggerDefinitions_606632; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606646 = newJObject()
  add(query_606646, "MaxResults", newJString(MaxResults))
  add(query_606646, "NextToken", newJString(NextToken))
  result = call_606645.call(nil, query_606646, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_606632(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_606633, base: "/",
    url: url_ListLoggerDefinitions_606634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_606679 = ref object of OpenApiRestCall_605573
proc url_CreateLoggerDefinitionVersion_606681(protocol: Scheme; host: string;
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

proc validate_CreateLoggerDefinitionVersion_606680(path: JsonNode; query: JsonNode;
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
  var valid_606682 = path.getOrDefault("LoggerDefinitionId")
  valid_606682 = validateParameter(valid_606682, JString, required = true,
                                 default = nil)
  if valid_606682 != nil:
    section.add "LoggerDefinitionId", valid_606682
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
  var valid_606683 = header.getOrDefault("X-Amz-Signature")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Signature", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Content-Sha256", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Date")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Date", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Credential")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Credential", valid_606686
  var valid_606687 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amzn-Client-Token", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Security-Token")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Security-Token", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Algorithm")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Algorithm", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-SignedHeaders", valid_606690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606692: Call_CreateLoggerDefinitionVersion_606679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_606692.validator(path, query, header, formData, body)
  let scheme = call_606692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606692.url(scheme.get, call_606692.host, call_606692.base,
                         call_606692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606692, url, valid)

proc call*(call_606693: Call_CreateLoggerDefinitionVersion_606679;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_606694 = newJObject()
  var body_606695 = newJObject()
  add(path_606694, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_606695 = body
  result = call_606693.call(path_606694, nil, nil, nil, body_606695)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_606679(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_606680, base: "/",
    url: url_CreateLoggerDefinitionVersion_606681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_606662 = ref object of OpenApiRestCall_605573
proc url_ListLoggerDefinitionVersions_606664(protocol: Scheme; host: string;
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

proc validate_ListLoggerDefinitionVersions_606663(path: JsonNode; query: JsonNode;
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
  var valid_606665 = path.getOrDefault("LoggerDefinitionId")
  valid_606665 = validateParameter(valid_606665, JString, required = true,
                                 default = nil)
  if valid_606665 != nil:
    section.add "LoggerDefinitionId", valid_606665
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606666 = query.getOrDefault("MaxResults")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "MaxResults", valid_606666
  var valid_606667 = query.getOrDefault("NextToken")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "NextToken", valid_606667
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
  var valid_606668 = header.getOrDefault("X-Amz-Signature")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Signature", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Content-Sha256", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Date")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Date", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Credential")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Credential", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Security-Token")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Security-Token", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Algorithm")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Algorithm", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-SignedHeaders", valid_606674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606675: Call_ListLoggerDefinitionVersions_606662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_606675.validator(path, query, header, formData, body)
  let scheme = call_606675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606675.url(scheme.get, call_606675.host, call_606675.base,
                         call_606675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606675, url, valid)

proc call*(call_606676: Call_ListLoggerDefinitionVersions_606662;
          LoggerDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_606677 = newJObject()
  var query_606678 = newJObject()
  add(query_606678, "MaxResults", newJString(MaxResults))
  add(query_606678, "NextToken", newJString(NextToken))
  add(path_606677, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_606676.call(path_606677, query_606678, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_606662(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_606663, base: "/",
    url: url_ListLoggerDefinitionVersions_606664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_606711 = ref object of OpenApiRestCall_605573
proc url_CreateResourceDefinition_606713(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinition_606712(path: JsonNode; query: JsonNode;
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
  var valid_606714 = header.getOrDefault("X-Amz-Signature")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Signature", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Content-Sha256", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Date")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Date", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Credential")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Credential", valid_606717
  var valid_606718 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amzn-Client-Token", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Security-Token")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Security-Token", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Algorithm")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Algorithm", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-SignedHeaders", valid_606721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606723: Call_CreateResourceDefinition_606711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_606723.validator(path, query, header, formData, body)
  let scheme = call_606723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606723.url(scheme.get, call_606723.host, call_606723.base,
                         call_606723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606723, url, valid)

proc call*(call_606724: Call_CreateResourceDefinition_606711; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_606725 = newJObject()
  if body != nil:
    body_606725 = body
  result = call_606724.call(nil, nil, nil, nil, body_606725)

var createResourceDefinition* = Call_CreateResourceDefinition_606711(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_606712, base: "/",
    url: url_CreateResourceDefinition_606713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_606696 = ref object of OpenApiRestCall_605573
proc url_ListResourceDefinitions_606698(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceDefinitions_606697(path: JsonNode; query: JsonNode;
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
  var valid_606699 = query.getOrDefault("MaxResults")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "MaxResults", valid_606699
  var valid_606700 = query.getOrDefault("NextToken")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "NextToken", valid_606700
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
  var valid_606701 = header.getOrDefault("X-Amz-Signature")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Signature", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Content-Sha256", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Date")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Date", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Credential")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Credential", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Security-Token")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Security-Token", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Algorithm")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Algorithm", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-SignedHeaders", valid_606707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606708: Call_ListResourceDefinitions_606696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_606708.validator(path, query, header, formData, body)
  let scheme = call_606708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606708.url(scheme.get, call_606708.host, call_606708.base,
                         call_606708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606708, url, valid)

proc call*(call_606709: Call_ListResourceDefinitions_606696;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606710 = newJObject()
  add(query_606710, "MaxResults", newJString(MaxResults))
  add(query_606710, "NextToken", newJString(NextToken))
  result = call_606709.call(nil, query_606710, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_606696(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_606697, base: "/",
    url: url_ListResourceDefinitions_606698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_606743 = ref object of OpenApiRestCall_605573
proc url_CreateResourceDefinitionVersion_606745(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinitionVersion_606744(path: JsonNode;
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
  var valid_606746 = path.getOrDefault("ResourceDefinitionId")
  valid_606746 = validateParameter(valid_606746, JString, required = true,
                                 default = nil)
  if valid_606746 != nil:
    section.add "ResourceDefinitionId", valid_606746
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
  var valid_606747 = header.getOrDefault("X-Amz-Signature")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Signature", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Content-Sha256", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Date")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Date", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Credential")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Credential", valid_606750
  var valid_606751 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amzn-Client-Token", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Security-Token")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Security-Token", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Algorithm")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Algorithm", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-SignedHeaders", valid_606754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606756: Call_CreateResourceDefinitionVersion_606743;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_606756.validator(path, query, header, formData, body)
  let scheme = call_606756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606756.url(scheme.get, call_606756.host, call_606756.base,
                         call_606756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606756, url, valid)

proc call*(call_606757: Call_CreateResourceDefinitionVersion_606743;
          body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_606758 = newJObject()
  var body_606759 = newJObject()
  if body != nil:
    body_606759 = body
  add(path_606758, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_606757.call(path_606758, nil, nil, nil, body_606759)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_606743(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_606744, base: "/",
    url: url_CreateResourceDefinitionVersion_606745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_606726 = ref object of OpenApiRestCall_605573
proc url_ListResourceDefinitionVersions_606728(protocol: Scheme; host: string;
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

proc validate_ListResourceDefinitionVersions_606727(path: JsonNode;
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
  var valid_606729 = path.getOrDefault("ResourceDefinitionId")
  valid_606729 = validateParameter(valid_606729, JString, required = true,
                                 default = nil)
  if valid_606729 != nil:
    section.add "ResourceDefinitionId", valid_606729
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606730 = query.getOrDefault("MaxResults")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "MaxResults", valid_606730
  var valid_606731 = query.getOrDefault("NextToken")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "NextToken", valid_606731
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
  var valid_606732 = header.getOrDefault("X-Amz-Signature")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Signature", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Content-Sha256", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Date")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Date", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Credential")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Credential", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Security-Token")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Security-Token", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Algorithm")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Algorithm", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-SignedHeaders", valid_606738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606739: Call_ListResourceDefinitionVersions_606726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_606739.validator(path, query, header, formData, body)
  let scheme = call_606739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606739.url(scheme.get, call_606739.host, call_606739.base,
                         call_606739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606739, url, valid)

proc call*(call_606740: Call_ListResourceDefinitionVersions_606726;
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
  var path_606741 = newJObject()
  var query_606742 = newJObject()
  add(query_606742, "MaxResults", newJString(MaxResults))
  add(query_606742, "NextToken", newJString(NextToken))
  add(path_606741, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_606740.call(path_606741, query_606742, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_606726(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_606727, base: "/",
    url: url_ListResourceDefinitionVersions_606728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_606760 = ref object of OpenApiRestCall_605573
proc url_CreateSoftwareUpdateJob_606762(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSoftwareUpdateJob_606761(path: JsonNode; query: JsonNode;
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
  var valid_606763 = header.getOrDefault("X-Amz-Signature")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Signature", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Content-Sha256", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Date")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Date", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Credential")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Credential", valid_606766
  var valid_606767 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amzn-Client-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Security-Token")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Security-Token", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Algorithm")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Algorithm", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-SignedHeaders", valid_606770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606772: Call_CreateSoftwareUpdateJob_606760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_606772.validator(path, query, header, formData, body)
  let scheme = call_606772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606772.url(scheme.get, call_606772.host, call_606772.base,
                         call_606772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606772, url, valid)

proc call*(call_606773: Call_CreateSoftwareUpdateJob_606760; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_606774 = newJObject()
  if body != nil:
    body_606774 = body
  result = call_606773.call(nil, nil, nil, nil, body_606774)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_606760(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_606761, base: "/",
    url: url_CreateSoftwareUpdateJob_606762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_606790 = ref object of OpenApiRestCall_605573
proc url_CreateSubscriptionDefinition_606792(protocol: Scheme; host: string;
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

proc validate_CreateSubscriptionDefinition_606791(path: JsonNode; query: JsonNode;
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
  var valid_606793 = header.getOrDefault("X-Amz-Signature")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Signature", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Content-Sha256", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Date")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Date", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Credential")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Credential", valid_606796
  var valid_606797 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amzn-Client-Token", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Security-Token")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Security-Token", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Algorithm")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Algorithm", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-SignedHeaders", valid_606800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_CreateSubscriptionDefinition_606790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_CreateSubscriptionDefinition_606790; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_606804 = newJObject()
  if body != nil:
    body_606804 = body
  result = call_606803.call(nil, nil, nil, nil, body_606804)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_606790(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_606791, base: "/",
    url: url_CreateSubscriptionDefinition_606792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_606775 = ref object of OpenApiRestCall_605573
proc url_ListSubscriptionDefinitions_606777(protocol: Scheme; host: string;
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

proc validate_ListSubscriptionDefinitions_606776(path: JsonNode; query: JsonNode;
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
  var valid_606778 = query.getOrDefault("MaxResults")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "MaxResults", valid_606778
  var valid_606779 = query.getOrDefault("NextToken")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "NextToken", valid_606779
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
  var valid_606780 = header.getOrDefault("X-Amz-Signature")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Signature", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Content-Sha256", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Date")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Date", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Credential")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Credential", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Security-Token")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Security-Token", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Algorithm")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Algorithm", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-SignedHeaders", valid_606786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606787: Call_ListSubscriptionDefinitions_606775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_606787.validator(path, query, header, formData, body)
  let scheme = call_606787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606787.url(scheme.get, call_606787.host, call_606787.base,
                         call_606787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606787, url, valid)

proc call*(call_606788: Call_ListSubscriptionDefinitions_606775;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_606789 = newJObject()
  add(query_606789, "MaxResults", newJString(MaxResults))
  add(query_606789, "NextToken", newJString(NextToken))
  result = call_606788.call(nil, query_606789, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_606775(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_606776, base: "/",
    url: url_ListSubscriptionDefinitions_606777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_606822 = ref object of OpenApiRestCall_605573
proc url_CreateSubscriptionDefinitionVersion_606824(protocol: Scheme; host: string;
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

proc validate_CreateSubscriptionDefinitionVersion_606823(path: JsonNode;
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
  var valid_606825 = path.getOrDefault("SubscriptionDefinitionId")
  valid_606825 = validateParameter(valid_606825, JString, required = true,
                                 default = nil)
  if valid_606825 != nil:
    section.add "SubscriptionDefinitionId", valid_606825
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
  var valid_606826 = header.getOrDefault("X-Amz-Signature")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Signature", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Content-Sha256", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Date")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Date", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Credential")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Credential", valid_606829
  var valid_606830 = header.getOrDefault("X-Amzn-Client-Token")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amzn-Client-Token", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Security-Token")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Security-Token", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Algorithm")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Algorithm", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-SignedHeaders", valid_606833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606835: Call_CreateSubscriptionDefinitionVersion_606822;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_606835.validator(path, query, header, formData, body)
  let scheme = call_606835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606835.url(scheme.get, call_606835.host, call_606835.base,
                         call_606835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606835, url, valid)

proc call*(call_606836: Call_CreateSubscriptionDefinitionVersion_606822;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_606837 = newJObject()
  var body_606838 = newJObject()
  add(path_606837, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_606838 = body
  result = call_606836.call(path_606837, nil, nil, nil, body_606838)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_606822(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_606823, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_606824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_606805 = ref object of OpenApiRestCall_605573
proc url_ListSubscriptionDefinitionVersions_606807(protocol: Scheme; host: string;
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

proc validate_ListSubscriptionDefinitionVersions_606806(path: JsonNode;
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
  var valid_606808 = path.getOrDefault("SubscriptionDefinitionId")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = nil)
  if valid_606808 != nil:
    section.add "SubscriptionDefinitionId", valid_606808
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_606809 = query.getOrDefault("MaxResults")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "MaxResults", valid_606809
  var valid_606810 = query.getOrDefault("NextToken")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "NextToken", valid_606810
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
  var valid_606811 = header.getOrDefault("X-Amz-Signature")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Signature", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Content-Sha256", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Date")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Date", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Credential")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Credential", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Security-Token")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Security-Token", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Algorithm")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Algorithm", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-SignedHeaders", valid_606817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_ListSubscriptionDefinitionVersions_606805;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_ListSubscriptionDefinitionVersions_606805;
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
  var path_606820 = newJObject()
  var query_606821 = newJObject()
  add(query_606821, "MaxResults", newJString(MaxResults))
  add(query_606821, "NextToken", newJString(NextToken))
  add(path_606820, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_606819.call(path_606820, query_606821, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_606805(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_606806, base: "/",
    url: url_ListSubscriptionDefinitionVersions_606807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_606853 = ref object of OpenApiRestCall_605573
proc url_UpdateConnectorDefinition_606855(protocol: Scheme; host: string;
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

proc validate_UpdateConnectorDefinition_606854(path: JsonNode; query: JsonNode;
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
  var valid_606856 = path.getOrDefault("ConnectorDefinitionId")
  valid_606856 = validateParameter(valid_606856, JString, required = true,
                                 default = nil)
  if valid_606856 != nil:
    section.add "ConnectorDefinitionId", valid_606856
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
  var valid_606857 = header.getOrDefault("X-Amz-Signature")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Signature", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Content-Sha256", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Date")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Date", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Credential")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Credential", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Security-Token")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Security-Token", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Algorithm")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Algorithm", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-SignedHeaders", valid_606863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606865: Call_UpdateConnectorDefinition_606853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_606865.validator(path, query, header, formData, body)
  let scheme = call_606865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606865.url(scheme.get, call_606865.host, call_606865.base,
                         call_606865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606865, url, valid)

proc call*(call_606866: Call_UpdateConnectorDefinition_606853;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_606867 = newJObject()
  var body_606868 = newJObject()
  add(path_606867, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_606868 = body
  result = call_606866.call(path_606867, nil, nil, nil, body_606868)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_606853(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_606854, base: "/",
    url: url_UpdateConnectorDefinition_606855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_606839 = ref object of OpenApiRestCall_605573
proc url_GetConnectorDefinition_606841(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectorDefinition_606840(path: JsonNode; query: JsonNode;
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
  var valid_606842 = path.getOrDefault("ConnectorDefinitionId")
  valid_606842 = validateParameter(valid_606842, JString, required = true,
                                 default = nil)
  if valid_606842 != nil:
    section.add "ConnectorDefinitionId", valid_606842
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
  var valid_606843 = header.getOrDefault("X-Amz-Signature")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Signature", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Content-Sha256", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Date")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Date", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Credential")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Credential", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Security-Token")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Security-Token", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Algorithm")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Algorithm", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-SignedHeaders", valid_606849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606850: Call_GetConnectorDefinition_606839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_606850.validator(path, query, header, formData, body)
  let scheme = call_606850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606850.url(scheme.get, call_606850.host, call_606850.base,
                         call_606850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606850, url, valid)

proc call*(call_606851: Call_GetConnectorDefinition_606839;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_606852 = newJObject()
  add(path_606852, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_606851.call(path_606852, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_606839(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_606840, base: "/",
    url: url_GetConnectorDefinition_606841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_606869 = ref object of OpenApiRestCall_605573
proc url_DeleteConnectorDefinition_606871(protocol: Scheme; host: string;
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

proc validate_DeleteConnectorDefinition_606870(path: JsonNode; query: JsonNode;
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
  var valid_606872 = path.getOrDefault("ConnectorDefinitionId")
  valid_606872 = validateParameter(valid_606872, JString, required = true,
                                 default = nil)
  if valid_606872 != nil:
    section.add "ConnectorDefinitionId", valid_606872
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
  var valid_606873 = header.getOrDefault("X-Amz-Signature")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Signature", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Content-Sha256", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Date")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Date", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Credential")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Credential", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Security-Token")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Security-Token", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Algorithm")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Algorithm", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-SignedHeaders", valid_606879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606880: Call_DeleteConnectorDefinition_606869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_606880.validator(path, query, header, formData, body)
  let scheme = call_606880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606880.url(scheme.get, call_606880.host, call_606880.base,
                         call_606880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606880, url, valid)

proc call*(call_606881: Call_DeleteConnectorDefinition_606869;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_606882 = newJObject()
  add(path_606882, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_606881.call(path_606882, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_606869(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_606870, base: "/",
    url: url_DeleteConnectorDefinition_606871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_606897 = ref object of OpenApiRestCall_605573
proc url_UpdateCoreDefinition_606899(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCoreDefinition_606898(path: JsonNode; query: JsonNode;
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
  var valid_606900 = path.getOrDefault("CoreDefinitionId")
  valid_606900 = validateParameter(valid_606900, JString, required = true,
                                 default = nil)
  if valid_606900 != nil:
    section.add "CoreDefinitionId", valid_606900
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
  var valid_606901 = header.getOrDefault("X-Amz-Signature")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Signature", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Content-Sha256", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Date")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Date", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Credential")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Credential", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Security-Token")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Security-Token", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Algorithm")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Algorithm", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-SignedHeaders", valid_606907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606909: Call_UpdateCoreDefinition_606897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_606909.validator(path, query, header, formData, body)
  let scheme = call_606909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606909.url(scheme.get, call_606909.host, call_606909.base,
                         call_606909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606909, url, valid)

proc call*(call_606910: Call_UpdateCoreDefinition_606897; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_606911 = newJObject()
  var body_606912 = newJObject()
  add(path_606911, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_606912 = body
  result = call_606910.call(path_606911, nil, nil, nil, body_606912)

var updateCoreDefinition* = Call_UpdateCoreDefinition_606897(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_606898, base: "/",
    url: url_UpdateCoreDefinition_606899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_606883 = ref object of OpenApiRestCall_605573
proc url_GetCoreDefinition_606885(protocol: Scheme; host: string; base: string;
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

proc validate_GetCoreDefinition_606884(path: JsonNode; query: JsonNode;
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
  var valid_606886 = path.getOrDefault("CoreDefinitionId")
  valid_606886 = validateParameter(valid_606886, JString, required = true,
                                 default = nil)
  if valid_606886 != nil:
    section.add "CoreDefinitionId", valid_606886
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
  var valid_606887 = header.getOrDefault("X-Amz-Signature")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Signature", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Content-Sha256", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Date")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Date", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Credential")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Credential", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Security-Token")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Security-Token", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Algorithm")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Algorithm", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-SignedHeaders", valid_606893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606894: Call_GetCoreDefinition_606883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_606894.validator(path, query, header, formData, body)
  let scheme = call_606894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606894.url(scheme.get, call_606894.host, call_606894.base,
                         call_606894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606894, url, valid)

proc call*(call_606895: Call_GetCoreDefinition_606883; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_606896 = newJObject()
  add(path_606896, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_606895.call(path_606896, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_606883(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_606884, base: "/",
    url: url_GetCoreDefinition_606885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_606913 = ref object of OpenApiRestCall_605573
proc url_DeleteCoreDefinition_606915(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCoreDefinition_606914(path: JsonNode; query: JsonNode;
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
  var valid_606916 = path.getOrDefault("CoreDefinitionId")
  valid_606916 = validateParameter(valid_606916, JString, required = true,
                                 default = nil)
  if valid_606916 != nil:
    section.add "CoreDefinitionId", valid_606916
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
  var valid_606917 = header.getOrDefault("X-Amz-Signature")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Signature", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Content-Sha256", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Date")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Date", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Credential")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Credential", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Security-Token")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Security-Token", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Algorithm")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Algorithm", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-SignedHeaders", valid_606923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606924: Call_DeleteCoreDefinition_606913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_606924.validator(path, query, header, formData, body)
  let scheme = call_606924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606924.url(scheme.get, call_606924.host, call_606924.base,
                         call_606924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606924, url, valid)

proc call*(call_606925: Call_DeleteCoreDefinition_606913; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_606926 = newJObject()
  add(path_606926, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_606925.call(path_606926, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_606913(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_606914, base: "/",
    url: url_DeleteCoreDefinition_606915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_606941 = ref object of OpenApiRestCall_605573
proc url_UpdateDeviceDefinition_606943(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceDefinition_606942(path: JsonNode; query: JsonNode;
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
  var valid_606944 = path.getOrDefault("DeviceDefinitionId")
  valid_606944 = validateParameter(valid_606944, JString, required = true,
                                 default = nil)
  if valid_606944 != nil:
    section.add "DeviceDefinitionId", valid_606944
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
  var valid_606945 = header.getOrDefault("X-Amz-Signature")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Signature", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Content-Sha256", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Date")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Date", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Credential")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Credential", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Security-Token")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Security-Token", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Algorithm")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Algorithm", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-SignedHeaders", valid_606951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606953: Call_UpdateDeviceDefinition_606941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_606953.validator(path, query, header, formData, body)
  let scheme = call_606953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606953.url(scheme.get, call_606953.host, call_606953.base,
                         call_606953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606953, url, valid)

proc call*(call_606954: Call_UpdateDeviceDefinition_606941;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_606955 = newJObject()
  var body_606956 = newJObject()
  add(path_606955, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_606956 = body
  result = call_606954.call(path_606955, nil, nil, nil, body_606956)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_606941(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_606942, base: "/",
    url: url_UpdateDeviceDefinition_606943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_606927 = ref object of OpenApiRestCall_605573
proc url_GetDeviceDefinition_606929(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceDefinition_606928(path: JsonNode; query: JsonNode;
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
  var valid_606930 = path.getOrDefault("DeviceDefinitionId")
  valid_606930 = validateParameter(valid_606930, JString, required = true,
                                 default = nil)
  if valid_606930 != nil:
    section.add "DeviceDefinitionId", valid_606930
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
  var valid_606931 = header.getOrDefault("X-Amz-Signature")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Signature", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Content-Sha256", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Date")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Date", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Credential")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Credential", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Security-Token")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Security-Token", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Algorithm")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Algorithm", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-SignedHeaders", valid_606937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606938: Call_GetDeviceDefinition_606927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_606938.validator(path, query, header, formData, body)
  let scheme = call_606938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606938.url(scheme.get, call_606938.host, call_606938.base,
                         call_606938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606938, url, valid)

proc call*(call_606939: Call_GetDeviceDefinition_606927; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_606940 = newJObject()
  add(path_606940, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_606939.call(path_606940, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_606927(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_606928, base: "/",
    url: url_GetDeviceDefinition_606929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_606957 = ref object of OpenApiRestCall_605573
proc url_DeleteDeviceDefinition_606959(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceDefinition_606958(path: JsonNode; query: JsonNode;
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
  var valid_606960 = path.getOrDefault("DeviceDefinitionId")
  valid_606960 = validateParameter(valid_606960, JString, required = true,
                                 default = nil)
  if valid_606960 != nil:
    section.add "DeviceDefinitionId", valid_606960
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
  var valid_606961 = header.getOrDefault("X-Amz-Signature")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Signature", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Content-Sha256", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Date")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Date", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Credential")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Credential", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Security-Token")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Security-Token", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Algorithm")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Algorithm", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-SignedHeaders", valid_606967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606968: Call_DeleteDeviceDefinition_606957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_606968.validator(path, query, header, formData, body)
  let scheme = call_606968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606968.url(scheme.get, call_606968.host, call_606968.base,
                         call_606968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606968, url, valid)

proc call*(call_606969: Call_DeleteDeviceDefinition_606957;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_606970 = newJObject()
  add(path_606970, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_606969.call(path_606970, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_606957(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_606958, base: "/",
    url: url_DeleteDeviceDefinition_606959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_606985 = ref object of OpenApiRestCall_605573
proc url_UpdateFunctionDefinition_606987(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionDefinition_606986(path: JsonNode; query: JsonNode;
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
  var valid_606988 = path.getOrDefault("FunctionDefinitionId")
  valid_606988 = validateParameter(valid_606988, JString, required = true,
                                 default = nil)
  if valid_606988 != nil:
    section.add "FunctionDefinitionId", valid_606988
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
  var valid_606989 = header.getOrDefault("X-Amz-Signature")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Signature", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Content-Sha256", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Date")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Date", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Credential")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Credential", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Security-Token")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Security-Token", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Algorithm")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Algorithm", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-SignedHeaders", valid_606995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606997: Call_UpdateFunctionDefinition_606985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_606997.validator(path, query, header, formData, body)
  let scheme = call_606997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606997.url(scheme.get, call_606997.host, call_606997.base,
                         call_606997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606997, url, valid)

proc call*(call_606998: Call_UpdateFunctionDefinition_606985;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_606999 = newJObject()
  var body_607000 = newJObject()
  add(path_606999, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_607000 = body
  result = call_606998.call(path_606999, nil, nil, nil, body_607000)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_606985(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_606986, base: "/",
    url: url_UpdateFunctionDefinition_606987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_606971 = ref object of OpenApiRestCall_605573
proc url_GetFunctionDefinition_606973(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionDefinition_606972(path: JsonNode; query: JsonNode;
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
  var valid_606974 = path.getOrDefault("FunctionDefinitionId")
  valid_606974 = validateParameter(valid_606974, JString, required = true,
                                 default = nil)
  if valid_606974 != nil:
    section.add "FunctionDefinitionId", valid_606974
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
  var valid_606975 = header.getOrDefault("X-Amz-Signature")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Signature", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Content-Sha256", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Date")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Date", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Credential")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Credential", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-Security-Token")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Security-Token", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Algorithm")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Algorithm", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-SignedHeaders", valid_606981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606982: Call_GetFunctionDefinition_606971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_606982.validator(path, query, header, formData, body)
  let scheme = call_606982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606982.url(scheme.get, call_606982.host, call_606982.base,
                         call_606982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606982, url, valid)

proc call*(call_606983: Call_GetFunctionDefinition_606971;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_606984 = newJObject()
  add(path_606984, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_606983.call(path_606984, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_606971(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_606972, base: "/",
    url: url_GetFunctionDefinition_606973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_607001 = ref object of OpenApiRestCall_605573
proc url_DeleteFunctionDefinition_607003(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionDefinition_607002(path: JsonNode; query: JsonNode;
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
  var valid_607004 = path.getOrDefault("FunctionDefinitionId")
  valid_607004 = validateParameter(valid_607004, JString, required = true,
                                 default = nil)
  if valid_607004 != nil:
    section.add "FunctionDefinitionId", valid_607004
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
  var valid_607005 = header.getOrDefault("X-Amz-Signature")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Signature", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Content-Sha256", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Date")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Date", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Credential")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Credential", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Security-Token")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Security-Token", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Algorithm")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Algorithm", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-SignedHeaders", valid_607011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607012: Call_DeleteFunctionDefinition_607001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_607012.validator(path, query, header, formData, body)
  let scheme = call_607012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607012.url(scheme.get, call_607012.host, call_607012.base,
                         call_607012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607012, url, valid)

proc call*(call_607013: Call_DeleteFunctionDefinition_607001;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_607014 = newJObject()
  add(path_607014, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_607013.call(path_607014, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_607001(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_607002, base: "/",
    url: url_DeleteFunctionDefinition_607003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_607029 = ref object of OpenApiRestCall_605573
proc url_UpdateGroup_607031(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_607030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607032 = path.getOrDefault("GroupId")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = nil)
  if valid_607032 != nil:
    section.add "GroupId", valid_607032
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
  var valid_607033 = header.getOrDefault("X-Amz-Signature")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Signature", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Content-Sha256", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Date")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Date", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Credential")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Credential", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Security-Token")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Security-Token", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Algorithm")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Algorithm", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-SignedHeaders", valid_607039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607041: Call_UpdateGroup_607029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_607041.validator(path, query, header, formData, body)
  let scheme = call_607041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607041.url(scheme.get, call_607041.host, call_607041.base,
                         call_607041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607041, url, valid)

proc call*(call_607042: Call_UpdateGroup_607029; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_607043 = newJObject()
  var body_607044 = newJObject()
  add(path_607043, "GroupId", newJString(GroupId))
  if body != nil:
    body_607044 = body
  result = call_607042.call(path_607043, nil, nil, nil, body_607044)

var updateGroup* = Call_UpdateGroup_607029(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_607030,
                                        base: "/", url: url_UpdateGroup_607031,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_607015 = ref object of OpenApiRestCall_605573
proc url_GetGroup_607017(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_607016(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607018 = path.getOrDefault("GroupId")
  valid_607018 = validateParameter(valid_607018, JString, required = true,
                                 default = nil)
  if valid_607018 != nil:
    section.add "GroupId", valid_607018
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
  var valid_607019 = header.getOrDefault("X-Amz-Signature")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Signature", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Content-Sha256", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Date")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Date", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Credential")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Credential", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Security-Token")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Security-Token", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Algorithm")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Algorithm", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-SignedHeaders", valid_607025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607026: Call_GetGroup_607015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_607026.validator(path, query, header, formData, body)
  let scheme = call_607026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607026.url(scheme.get, call_607026.host, call_607026.base,
                         call_607026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607026, url, valid)

proc call*(call_607027: Call_GetGroup_607015; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_607028 = newJObject()
  add(path_607028, "GroupId", newJString(GroupId))
  result = call_607027.call(path_607028, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_607015(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_607016, base: "/",
                                  url: url_GetGroup_607017,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_607045 = ref object of OpenApiRestCall_605573
proc url_DeleteGroup_607047(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_607046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607048 = path.getOrDefault("GroupId")
  valid_607048 = validateParameter(valid_607048, JString, required = true,
                                 default = nil)
  if valid_607048 != nil:
    section.add "GroupId", valid_607048
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
  var valid_607049 = header.getOrDefault("X-Amz-Signature")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-Signature", valid_607049
  var valid_607050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607050 = validateParameter(valid_607050, JString, required = false,
                                 default = nil)
  if valid_607050 != nil:
    section.add "X-Amz-Content-Sha256", valid_607050
  var valid_607051 = header.getOrDefault("X-Amz-Date")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "X-Amz-Date", valid_607051
  var valid_607052 = header.getOrDefault("X-Amz-Credential")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = nil)
  if valid_607052 != nil:
    section.add "X-Amz-Credential", valid_607052
  var valid_607053 = header.getOrDefault("X-Amz-Security-Token")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "X-Amz-Security-Token", valid_607053
  var valid_607054 = header.getOrDefault("X-Amz-Algorithm")
  valid_607054 = validateParameter(valid_607054, JString, required = false,
                                 default = nil)
  if valid_607054 != nil:
    section.add "X-Amz-Algorithm", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-SignedHeaders", valid_607055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607056: Call_DeleteGroup_607045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_607056.validator(path, query, header, formData, body)
  let scheme = call_607056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607056.url(scheme.get, call_607056.host, call_607056.base,
                         call_607056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607056, url, valid)

proc call*(call_607057: Call_DeleteGroup_607045; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_607058 = newJObject()
  add(path_607058, "GroupId", newJString(GroupId))
  result = call_607057.call(path_607058, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_607045(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_607046,
                                        base: "/", url: url_DeleteGroup_607047,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_607073 = ref object of OpenApiRestCall_605573
proc url_UpdateLoggerDefinition_607075(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLoggerDefinition_607074(path: JsonNode; query: JsonNode;
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
  var valid_607076 = path.getOrDefault("LoggerDefinitionId")
  valid_607076 = validateParameter(valid_607076, JString, required = true,
                                 default = nil)
  if valid_607076 != nil:
    section.add "LoggerDefinitionId", valid_607076
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
  var valid_607077 = header.getOrDefault("X-Amz-Signature")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Signature", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Content-Sha256", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Date")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Date", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Credential")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Credential", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Security-Token")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Security-Token", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Algorithm")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Algorithm", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-SignedHeaders", valid_607083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_UpdateLoggerDefinition_607073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607086: Call_UpdateLoggerDefinition_607073;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_607087 = newJObject()
  var body_607088 = newJObject()
  add(path_607087, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_607088 = body
  result = call_607086.call(path_607087, nil, nil, nil, body_607088)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_607073(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_607074, base: "/",
    url: url_UpdateLoggerDefinition_607075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_607059 = ref object of OpenApiRestCall_605573
proc url_GetLoggerDefinition_607061(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoggerDefinition_607060(path: JsonNode; query: JsonNode;
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
  var valid_607062 = path.getOrDefault("LoggerDefinitionId")
  valid_607062 = validateParameter(valid_607062, JString, required = true,
                                 default = nil)
  if valid_607062 != nil:
    section.add "LoggerDefinitionId", valid_607062
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
  var valid_607063 = header.getOrDefault("X-Amz-Signature")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Signature", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Content-Sha256", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Date")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Date", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Credential")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Credential", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Security-Token")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Security-Token", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Algorithm")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Algorithm", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-SignedHeaders", valid_607069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607070: Call_GetLoggerDefinition_607059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_607070.validator(path, query, header, formData, body)
  let scheme = call_607070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607070.url(scheme.get, call_607070.host, call_607070.base,
                         call_607070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607070, url, valid)

proc call*(call_607071: Call_GetLoggerDefinition_607059; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_607072 = newJObject()
  add(path_607072, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_607071.call(path_607072, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_607059(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_607060, base: "/",
    url: url_GetLoggerDefinition_607061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_607089 = ref object of OpenApiRestCall_605573
proc url_DeleteLoggerDefinition_607091(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoggerDefinition_607090(path: JsonNode; query: JsonNode;
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
  var valid_607092 = path.getOrDefault("LoggerDefinitionId")
  valid_607092 = validateParameter(valid_607092, JString, required = true,
                                 default = nil)
  if valid_607092 != nil:
    section.add "LoggerDefinitionId", valid_607092
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
  var valid_607093 = header.getOrDefault("X-Amz-Signature")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Signature", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Content-Sha256", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Date")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Date", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Credential")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Credential", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Security-Token")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Security-Token", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Algorithm")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Algorithm", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-SignedHeaders", valid_607099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607100: Call_DeleteLoggerDefinition_607089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_607100.validator(path, query, header, formData, body)
  let scheme = call_607100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607100.url(scheme.get, call_607100.host, call_607100.base,
                         call_607100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607100, url, valid)

proc call*(call_607101: Call_DeleteLoggerDefinition_607089;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_607102 = newJObject()
  add(path_607102, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_607101.call(path_607102, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_607089(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_607090, base: "/",
    url: url_DeleteLoggerDefinition_607091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_607117 = ref object of OpenApiRestCall_605573
proc url_UpdateResourceDefinition_607119(protocol: Scheme; host: string;
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

proc validate_UpdateResourceDefinition_607118(path: JsonNode; query: JsonNode;
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
  var valid_607120 = path.getOrDefault("ResourceDefinitionId")
  valid_607120 = validateParameter(valid_607120, JString, required = true,
                                 default = nil)
  if valid_607120 != nil:
    section.add "ResourceDefinitionId", valid_607120
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
  var valid_607121 = header.getOrDefault("X-Amz-Signature")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Signature", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Content-Sha256", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Date")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Date", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Credential")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Credential", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Security-Token")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Security-Token", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Algorithm")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Algorithm", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-SignedHeaders", valid_607127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607129: Call_UpdateResourceDefinition_607117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_607129.validator(path, query, header, formData, body)
  let scheme = call_607129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607129.url(scheme.get, call_607129.host, call_607129.base,
                         call_607129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607129, url, valid)

proc call*(call_607130: Call_UpdateResourceDefinition_607117; body: JsonNode;
          ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_607131 = newJObject()
  var body_607132 = newJObject()
  if body != nil:
    body_607132 = body
  add(path_607131, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_607130.call(path_607131, nil, nil, nil, body_607132)

var updateResourceDefinition* = Call_UpdateResourceDefinition_607117(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_607118, base: "/",
    url: url_UpdateResourceDefinition_607119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_607103 = ref object of OpenApiRestCall_605573
proc url_GetResourceDefinition_607105(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceDefinition_607104(path: JsonNode; query: JsonNode;
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
  var valid_607106 = path.getOrDefault("ResourceDefinitionId")
  valid_607106 = validateParameter(valid_607106, JString, required = true,
                                 default = nil)
  if valid_607106 != nil:
    section.add "ResourceDefinitionId", valid_607106
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
  var valid_607107 = header.getOrDefault("X-Amz-Signature")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Signature", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Content-Sha256", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Date")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Date", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Credential")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Credential", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Security-Token")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Security-Token", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Algorithm")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Algorithm", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-SignedHeaders", valid_607113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607114: Call_GetResourceDefinition_607103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_607114.validator(path, query, header, formData, body)
  let scheme = call_607114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607114.url(scheme.get, call_607114.host, call_607114.base,
                         call_607114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607114, url, valid)

proc call*(call_607115: Call_GetResourceDefinition_607103;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_607116 = newJObject()
  add(path_607116, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_607115.call(path_607116, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_607103(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_607104, base: "/",
    url: url_GetResourceDefinition_607105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_607133 = ref object of OpenApiRestCall_605573
proc url_DeleteResourceDefinition_607135(protocol: Scheme; host: string;
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

proc validate_DeleteResourceDefinition_607134(path: JsonNode; query: JsonNode;
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
  var valid_607136 = path.getOrDefault("ResourceDefinitionId")
  valid_607136 = validateParameter(valid_607136, JString, required = true,
                                 default = nil)
  if valid_607136 != nil:
    section.add "ResourceDefinitionId", valid_607136
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
  var valid_607137 = header.getOrDefault("X-Amz-Signature")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-Signature", valid_607137
  var valid_607138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Content-Sha256", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Date")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Date", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Credential")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Credential", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Security-Token")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Security-Token", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Algorithm")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Algorithm", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-SignedHeaders", valid_607143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607144: Call_DeleteResourceDefinition_607133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_607144.validator(path, query, header, formData, body)
  let scheme = call_607144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607144.url(scheme.get, call_607144.host, call_607144.base,
                         call_607144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607144, url, valid)

proc call*(call_607145: Call_DeleteResourceDefinition_607133;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_607146 = newJObject()
  add(path_607146, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_607145.call(path_607146, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_607133(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_607134, base: "/",
    url: url_DeleteResourceDefinition_607135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_607161 = ref object of OpenApiRestCall_605573
proc url_UpdateSubscriptionDefinition_607163(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_607162(path: JsonNode; query: JsonNode;
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
  var valid_607164 = path.getOrDefault("SubscriptionDefinitionId")
  valid_607164 = validateParameter(valid_607164, JString, required = true,
                                 default = nil)
  if valid_607164 != nil:
    section.add "SubscriptionDefinitionId", valid_607164
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
  var valid_607165 = header.getOrDefault("X-Amz-Signature")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Signature", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-Content-Sha256", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-Date")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Date", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-Credential")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Credential", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Security-Token")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Security-Token", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Algorithm")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Algorithm", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-SignedHeaders", valid_607171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607173: Call_UpdateSubscriptionDefinition_607161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_607173.validator(path, query, header, formData, body)
  let scheme = call_607173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607173.url(scheme.get, call_607173.host, call_607173.base,
                         call_607173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607173, url, valid)

proc call*(call_607174: Call_UpdateSubscriptionDefinition_607161;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_607175 = newJObject()
  var body_607176 = newJObject()
  add(path_607175, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_607176 = body
  result = call_607174.call(path_607175, nil, nil, nil, body_607176)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_607161(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_607162, base: "/",
    url: url_UpdateSubscriptionDefinition_607163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_607147 = ref object of OpenApiRestCall_605573
proc url_GetSubscriptionDefinition_607149(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_607148(path: JsonNode; query: JsonNode;
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
  var valid_607150 = path.getOrDefault("SubscriptionDefinitionId")
  valid_607150 = validateParameter(valid_607150, JString, required = true,
                                 default = nil)
  if valid_607150 != nil:
    section.add "SubscriptionDefinitionId", valid_607150
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
  var valid_607151 = header.getOrDefault("X-Amz-Signature")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Signature", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Content-Sha256", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Date")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Date", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Credential")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Credential", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Security-Token")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Security-Token", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-Algorithm")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Algorithm", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-SignedHeaders", valid_607157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607158: Call_GetSubscriptionDefinition_607147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_607158.validator(path, query, header, formData, body)
  let scheme = call_607158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607158.url(scheme.get, call_607158.host, call_607158.base,
                         call_607158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607158, url, valid)

proc call*(call_607159: Call_GetSubscriptionDefinition_607147;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_607160 = newJObject()
  add(path_607160, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_607159.call(path_607160, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_607147(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_607148, base: "/",
    url: url_GetSubscriptionDefinition_607149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_607177 = ref object of OpenApiRestCall_605573
proc url_DeleteSubscriptionDefinition_607179(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_607178(path: JsonNode; query: JsonNode;
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
  var valid_607180 = path.getOrDefault("SubscriptionDefinitionId")
  valid_607180 = validateParameter(valid_607180, JString, required = true,
                                 default = nil)
  if valid_607180 != nil:
    section.add "SubscriptionDefinitionId", valid_607180
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
  var valid_607181 = header.getOrDefault("X-Amz-Signature")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-Signature", valid_607181
  var valid_607182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Content-Sha256", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Date")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Date", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Credential")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Credential", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Security-Token")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Security-Token", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Algorithm")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Algorithm", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-SignedHeaders", valid_607187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607188: Call_DeleteSubscriptionDefinition_607177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_607188.validator(path, query, header, formData, body)
  let scheme = call_607188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607188.url(scheme.get, call_607188.host, call_607188.base,
                         call_607188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607188, url, valid)

proc call*(call_607189: Call_DeleteSubscriptionDefinition_607177;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_607190 = newJObject()
  add(path_607190, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_607189.call(path_607190, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_607177(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_607178, base: "/",
    url: url_DeleteSubscriptionDefinition_607179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_607191 = ref object of OpenApiRestCall_605573
proc url_GetBulkDeploymentStatus_607193(protocol: Scheme; host: string; base: string;
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

proc validate_GetBulkDeploymentStatus_607192(path: JsonNode; query: JsonNode;
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
  var valid_607194 = path.getOrDefault("BulkDeploymentId")
  valid_607194 = validateParameter(valid_607194, JString, required = true,
                                 default = nil)
  if valid_607194 != nil:
    section.add "BulkDeploymentId", valid_607194
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
  var valid_607195 = header.getOrDefault("X-Amz-Signature")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Signature", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Content-Sha256", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-Date")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Date", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Credential")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Credential", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Security-Token")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Security-Token", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Algorithm")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Algorithm", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-SignedHeaders", valid_607201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607202: Call_GetBulkDeploymentStatus_607191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_607202.validator(path, query, header, formData, body)
  let scheme = call_607202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607202.url(scheme.get, call_607202.host, call_607202.base,
                         call_607202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607202, url, valid)

proc call*(call_607203: Call_GetBulkDeploymentStatus_607191;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_607204 = newJObject()
  add(path_607204, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_607203.call(path_607204, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_607191(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_607192, base: "/",
    url: url_GetBulkDeploymentStatus_607193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_607219 = ref object of OpenApiRestCall_605573
proc url_UpdateConnectivityInfo_607221(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnectivityInfo_607220(path: JsonNode; query: JsonNode;
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
  var valid_607222 = path.getOrDefault("ThingName")
  valid_607222 = validateParameter(valid_607222, JString, required = true,
                                 default = nil)
  if valid_607222 != nil:
    section.add "ThingName", valid_607222
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
  var valid_607223 = header.getOrDefault("X-Amz-Signature")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Signature", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Content-Sha256", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Date")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Date", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Credential")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Credential", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-Security-Token")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Security-Token", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Algorithm")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Algorithm", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-SignedHeaders", valid_607229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607231: Call_UpdateConnectivityInfo_607219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_607231.validator(path, query, header, formData, body)
  let scheme = call_607231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607231.url(scheme.get, call_607231.host, call_607231.base,
                         call_607231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607231, url, valid)

proc call*(call_607232: Call_UpdateConnectivityInfo_607219; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_607233 = newJObject()
  var body_607234 = newJObject()
  add(path_607233, "ThingName", newJString(ThingName))
  if body != nil:
    body_607234 = body
  result = call_607232.call(path_607233, nil, nil, nil, body_607234)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_607219(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_607220, base: "/",
    url: url_UpdateConnectivityInfo_607221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_607205 = ref object of OpenApiRestCall_605573
proc url_GetConnectivityInfo_607207(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectivityInfo_607206(path: JsonNode; query: JsonNode;
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
  var valid_607208 = path.getOrDefault("ThingName")
  valid_607208 = validateParameter(valid_607208, JString, required = true,
                                 default = nil)
  if valid_607208 != nil:
    section.add "ThingName", valid_607208
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
  var valid_607209 = header.getOrDefault("X-Amz-Signature")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-Signature", valid_607209
  var valid_607210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Content-Sha256", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-Date")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-Date", valid_607211
  var valid_607212 = header.getOrDefault("X-Amz-Credential")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-Credential", valid_607212
  var valid_607213 = header.getOrDefault("X-Amz-Security-Token")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "X-Amz-Security-Token", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Algorithm")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Algorithm", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-SignedHeaders", valid_607215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607216: Call_GetConnectivityInfo_607205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_607216.validator(path, query, header, formData, body)
  let scheme = call_607216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607216.url(scheme.get, call_607216.host, call_607216.base,
                         call_607216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607216, url, valid)

proc call*(call_607217: Call_GetConnectivityInfo_607205; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_607218 = newJObject()
  add(path_607218, "ThingName", newJString(ThingName))
  result = call_607217.call(path_607218, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_607205(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_607206, base: "/",
    url: url_GetConnectivityInfo_607207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_607235 = ref object of OpenApiRestCall_605573
proc url_GetConnectorDefinitionVersion_607237(protocol: Scheme; host: string;
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

proc validate_GetConnectorDefinitionVersion_607236(path: JsonNode; query: JsonNode;
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
  var valid_607238 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_607238 = validateParameter(valid_607238, JString, required = true,
                                 default = nil)
  if valid_607238 != nil:
    section.add "ConnectorDefinitionVersionId", valid_607238
  var valid_607239 = path.getOrDefault("ConnectorDefinitionId")
  valid_607239 = validateParameter(valid_607239, JString, required = true,
                                 default = nil)
  if valid_607239 != nil:
    section.add "ConnectorDefinitionId", valid_607239
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607240 = query.getOrDefault("NextToken")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "NextToken", valid_607240
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
  var valid_607241 = header.getOrDefault("X-Amz-Signature")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Signature", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Content-Sha256", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Date")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Date", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Credential")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Credential", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Security-Token")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Security-Token", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Algorithm")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Algorithm", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-SignedHeaders", valid_607247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607248: Call_GetConnectorDefinitionVersion_607235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_607248.validator(path, query, header, formData, body)
  let scheme = call_607248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607248.url(scheme.get, call_607248.host, call_607248.base,
                         call_607248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607248, url, valid)

proc call*(call_607249: Call_GetConnectorDefinitionVersion_607235;
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
  var path_607250 = newJObject()
  var query_607251 = newJObject()
  add(path_607250, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_607251, "NextToken", newJString(NextToken))
  add(path_607250, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_607249.call(path_607250, query_607251, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_607235(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_607236, base: "/",
    url: url_GetConnectorDefinitionVersion_607237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_607252 = ref object of OpenApiRestCall_605573
proc url_GetCoreDefinitionVersion_607254(protocol: Scheme; host: string;
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

proc validate_GetCoreDefinitionVersion_607253(path: JsonNode; query: JsonNode;
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
  var valid_607255 = path.getOrDefault("CoreDefinitionVersionId")
  valid_607255 = validateParameter(valid_607255, JString, required = true,
                                 default = nil)
  if valid_607255 != nil:
    section.add "CoreDefinitionVersionId", valid_607255
  var valid_607256 = path.getOrDefault("CoreDefinitionId")
  valid_607256 = validateParameter(valid_607256, JString, required = true,
                                 default = nil)
  if valid_607256 != nil:
    section.add "CoreDefinitionId", valid_607256
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
  var valid_607257 = header.getOrDefault("X-Amz-Signature")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "X-Amz-Signature", valid_607257
  var valid_607258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "X-Amz-Content-Sha256", valid_607258
  var valid_607259 = header.getOrDefault("X-Amz-Date")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "X-Amz-Date", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Credential")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Credential", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Security-Token")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Security-Token", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Algorithm")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Algorithm", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-SignedHeaders", valid_607263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607264: Call_GetCoreDefinitionVersion_607252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_607264.validator(path, query, header, formData, body)
  let scheme = call_607264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607264.url(scheme.get, call_607264.host, call_607264.base,
                         call_607264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607264, url, valid)

proc call*(call_607265: Call_GetCoreDefinitionVersion_607252;
          CoreDefinitionVersionId: string; CoreDefinitionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_607266 = newJObject()
  add(path_607266, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  add(path_607266, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_607265.call(path_607266, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_607252(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_607253, base: "/",
    url: url_GetCoreDefinitionVersion_607254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_607267 = ref object of OpenApiRestCall_605573
proc url_GetDeploymentStatus_607269(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStatus_607268(path: JsonNode; query: JsonNode;
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
  var valid_607270 = path.getOrDefault("GroupId")
  valid_607270 = validateParameter(valid_607270, JString, required = true,
                                 default = nil)
  if valid_607270 != nil:
    section.add "GroupId", valid_607270
  var valid_607271 = path.getOrDefault("DeploymentId")
  valid_607271 = validateParameter(valid_607271, JString, required = true,
                                 default = nil)
  if valid_607271 != nil:
    section.add "DeploymentId", valid_607271
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
  var valid_607272 = header.getOrDefault("X-Amz-Signature")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-Signature", valid_607272
  var valid_607273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607273 = validateParameter(valid_607273, JString, required = false,
                                 default = nil)
  if valid_607273 != nil:
    section.add "X-Amz-Content-Sha256", valid_607273
  var valid_607274 = header.getOrDefault("X-Amz-Date")
  valid_607274 = validateParameter(valid_607274, JString, required = false,
                                 default = nil)
  if valid_607274 != nil:
    section.add "X-Amz-Date", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Credential")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Credential", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Security-Token")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Security-Token", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Algorithm")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Algorithm", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-SignedHeaders", valid_607278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607279: Call_GetDeploymentStatus_607267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_607279.validator(path, query, header, formData, body)
  let scheme = call_607279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607279.url(scheme.get, call_607279.host, call_607279.base,
                         call_607279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607279, url, valid)

proc call*(call_607280: Call_GetDeploymentStatus_607267; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_607281 = newJObject()
  add(path_607281, "GroupId", newJString(GroupId))
  add(path_607281, "DeploymentId", newJString(DeploymentId))
  result = call_607280.call(path_607281, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_607267(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_607268, base: "/",
    url: url_GetDeploymentStatus_607269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_607282 = ref object of OpenApiRestCall_605573
proc url_GetDeviceDefinitionVersion_607284(protocol: Scheme; host: string;
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

proc validate_GetDeviceDefinitionVersion_607283(path: JsonNode; query: JsonNode;
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
  var valid_607285 = path.getOrDefault("DeviceDefinitionId")
  valid_607285 = validateParameter(valid_607285, JString, required = true,
                                 default = nil)
  if valid_607285 != nil:
    section.add "DeviceDefinitionId", valid_607285
  var valid_607286 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_607286 = validateParameter(valid_607286, JString, required = true,
                                 default = nil)
  if valid_607286 != nil:
    section.add "DeviceDefinitionVersionId", valid_607286
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607287 = query.getOrDefault("NextToken")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "NextToken", valid_607287
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
  var valid_607288 = header.getOrDefault("X-Amz-Signature")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "X-Amz-Signature", valid_607288
  var valid_607289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "X-Amz-Content-Sha256", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Date")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Date", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Credential")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Credential", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Security-Token")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Security-Token", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Algorithm")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Algorithm", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-SignedHeaders", valid_607294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607295: Call_GetDeviceDefinitionVersion_607282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_607295.validator(path, query, header, formData, body)
  let scheme = call_607295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607295.url(scheme.get, call_607295.host, call_607295.base,
                         call_607295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607295, url, valid)

proc call*(call_607296: Call_GetDeviceDefinitionVersion_607282;
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
  var path_607297 = newJObject()
  var query_607298 = newJObject()
  add(path_607297, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_607298, "NextToken", newJString(NextToken))
  add(path_607297, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_607296.call(path_607297, query_607298, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_607282(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_607283, base: "/",
    url: url_GetDeviceDefinitionVersion_607284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_607299 = ref object of OpenApiRestCall_605573
proc url_GetFunctionDefinitionVersion_607301(protocol: Scheme; host: string;
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

proc validate_GetFunctionDefinitionVersion_607300(path: JsonNode; query: JsonNode;
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
  var valid_607302 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_607302 = validateParameter(valid_607302, JString, required = true,
                                 default = nil)
  if valid_607302 != nil:
    section.add "FunctionDefinitionVersionId", valid_607302
  var valid_607303 = path.getOrDefault("FunctionDefinitionId")
  valid_607303 = validateParameter(valid_607303, JString, required = true,
                                 default = nil)
  if valid_607303 != nil:
    section.add "FunctionDefinitionId", valid_607303
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607304 = query.getOrDefault("NextToken")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "NextToken", valid_607304
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
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607312: Call_GetFunctionDefinitionVersion_607299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_607312.validator(path, query, header, formData, body)
  let scheme = call_607312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607312.url(scheme.get, call_607312.host, call_607312.base,
                         call_607312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607312, url, valid)

proc call*(call_607313: Call_GetFunctionDefinitionVersion_607299;
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
  var path_607314 = newJObject()
  var query_607315 = newJObject()
  add(path_607314, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_607315, "NextToken", newJString(NextToken))
  add(path_607314, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_607313.call(path_607314, query_607315, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_607299(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_607300, base: "/",
    url: url_GetFunctionDefinitionVersion_607301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_607316 = ref object of OpenApiRestCall_605573
proc url_GetGroupCertificateAuthority_607318(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_607317(path: JsonNode; query: JsonNode;
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
  var valid_607319 = path.getOrDefault("GroupId")
  valid_607319 = validateParameter(valid_607319, JString, required = true,
                                 default = nil)
  if valid_607319 != nil:
    section.add "GroupId", valid_607319
  var valid_607320 = path.getOrDefault("CertificateAuthorityId")
  valid_607320 = validateParameter(valid_607320, JString, required = true,
                                 default = nil)
  if valid_607320 != nil:
    section.add "CertificateAuthorityId", valid_607320
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
  var valid_607321 = header.getOrDefault("X-Amz-Signature")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Signature", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Content-Sha256", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Date")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Date", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Credential")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Credential", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Security-Token")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Security-Token", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Algorithm")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Algorithm", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-SignedHeaders", valid_607327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_GetGroupCertificateAuthority_607316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_GetGroupCertificateAuthority_607316; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_607330 = newJObject()
  add(path_607330, "GroupId", newJString(GroupId))
  add(path_607330, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_607329.call(path_607330, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_607316(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_607317, base: "/",
    url: url_GetGroupCertificateAuthority_607318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_607345 = ref object of OpenApiRestCall_605573
proc url_UpdateGroupCertificateConfiguration_607347(protocol: Scheme; host: string;
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

proc validate_UpdateGroupCertificateConfiguration_607346(path: JsonNode;
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
  var valid_607348 = path.getOrDefault("GroupId")
  valid_607348 = validateParameter(valid_607348, JString, required = true,
                                 default = nil)
  if valid_607348 != nil:
    section.add "GroupId", valid_607348
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
  var valid_607349 = header.getOrDefault("X-Amz-Signature")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Signature", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Content-Sha256", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Date")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Date", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Credential")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Credential", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Security-Token")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Security-Token", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Algorithm")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Algorithm", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-SignedHeaders", valid_607355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607357: Call_UpdateGroupCertificateConfiguration_607345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_607357.validator(path, query, header, formData, body)
  let scheme = call_607357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607357.url(scheme.get, call_607357.host, call_607357.base,
                         call_607357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607357, url, valid)

proc call*(call_607358: Call_UpdateGroupCertificateConfiguration_607345;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_607359 = newJObject()
  var body_607360 = newJObject()
  add(path_607359, "GroupId", newJString(GroupId))
  if body != nil:
    body_607360 = body
  result = call_607358.call(path_607359, nil, nil, nil, body_607360)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_607345(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_607346, base: "/",
    url: url_UpdateGroupCertificateConfiguration_607347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_607331 = ref object of OpenApiRestCall_605573
proc url_GetGroupCertificateConfiguration_607333(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateConfiguration_607332(path: JsonNode;
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
  var valid_607334 = path.getOrDefault("GroupId")
  valid_607334 = validateParameter(valid_607334, JString, required = true,
                                 default = nil)
  if valid_607334 != nil:
    section.add "GroupId", valid_607334
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
  var valid_607335 = header.getOrDefault("X-Amz-Signature")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Signature", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Content-Sha256", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Date")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Date", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Credential")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Credential", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Security-Token")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Security-Token", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Algorithm")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Algorithm", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-SignedHeaders", valid_607341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607342: Call_GetGroupCertificateConfiguration_607331;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_607342.validator(path, query, header, formData, body)
  let scheme = call_607342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607342.url(scheme.get, call_607342.host, call_607342.base,
                         call_607342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607342, url, valid)

proc call*(call_607343: Call_GetGroupCertificateConfiguration_607331;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_607344 = newJObject()
  add(path_607344, "GroupId", newJString(GroupId))
  result = call_607343.call(path_607344, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_607331(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_607332, base: "/",
    url: url_GetGroupCertificateConfiguration_607333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_607361 = ref object of OpenApiRestCall_605573
proc url_GetGroupVersion_607363(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupVersion_607362(path: JsonNode; query: JsonNode;
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
  var valid_607364 = path.getOrDefault("GroupVersionId")
  valid_607364 = validateParameter(valid_607364, JString, required = true,
                                 default = nil)
  if valid_607364 != nil:
    section.add "GroupVersionId", valid_607364
  var valid_607365 = path.getOrDefault("GroupId")
  valid_607365 = validateParameter(valid_607365, JString, required = true,
                                 default = nil)
  if valid_607365 != nil:
    section.add "GroupId", valid_607365
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
  var valid_607366 = header.getOrDefault("X-Amz-Signature")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Signature", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Content-Sha256", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Date")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Date", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Credential")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Credential", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Security-Token")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Security-Token", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Algorithm")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Algorithm", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-SignedHeaders", valid_607372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607373: Call_GetGroupVersion_607361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_607373.validator(path, query, header, formData, body)
  let scheme = call_607373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607373.url(scheme.get, call_607373.host, call_607373.base,
                         call_607373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607373, url, valid)

proc call*(call_607374: Call_GetGroupVersion_607361; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_607375 = newJObject()
  add(path_607375, "GroupVersionId", newJString(GroupVersionId))
  add(path_607375, "GroupId", newJString(GroupId))
  result = call_607374.call(path_607375, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_607361(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_607362, base: "/", url: url_GetGroupVersion_607363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_607376 = ref object of OpenApiRestCall_605573
proc url_GetLoggerDefinitionVersion_607378(protocol: Scheme; host: string;
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

proc validate_GetLoggerDefinitionVersion_607377(path: JsonNode; query: JsonNode;
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
  var valid_607379 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_607379 = validateParameter(valid_607379, JString, required = true,
                                 default = nil)
  if valid_607379 != nil:
    section.add "LoggerDefinitionVersionId", valid_607379
  var valid_607380 = path.getOrDefault("LoggerDefinitionId")
  valid_607380 = validateParameter(valid_607380, JString, required = true,
                                 default = nil)
  if valid_607380 != nil:
    section.add "LoggerDefinitionId", valid_607380
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607381 = query.getOrDefault("NextToken")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "NextToken", valid_607381
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
  var valid_607382 = header.getOrDefault("X-Amz-Signature")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Signature", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Content-Sha256", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Date")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Date", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Credential")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Credential", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Security-Token")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Security-Token", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Algorithm")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Algorithm", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-SignedHeaders", valid_607388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607389: Call_GetLoggerDefinitionVersion_607376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_607389.validator(path, query, header, formData, body)
  let scheme = call_607389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607389.url(scheme.get, call_607389.host, call_607389.base,
                         call_607389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607389, url, valid)

proc call*(call_607390: Call_GetLoggerDefinitionVersion_607376;
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
  var path_607391 = newJObject()
  var query_607392 = newJObject()
  add(path_607391, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_607392, "NextToken", newJString(NextToken))
  add(path_607391, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_607390.call(path_607391, query_607392, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_607376(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_607377, base: "/",
    url: url_GetLoggerDefinitionVersion_607378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_607393 = ref object of OpenApiRestCall_605573
proc url_GetResourceDefinitionVersion_607395(protocol: Scheme; host: string;
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

proc validate_GetResourceDefinitionVersion_607394(path: JsonNode; query: JsonNode;
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
  var valid_607396 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_607396 = validateParameter(valid_607396, JString, required = true,
                                 default = nil)
  if valid_607396 != nil:
    section.add "ResourceDefinitionVersionId", valid_607396
  var valid_607397 = path.getOrDefault("ResourceDefinitionId")
  valid_607397 = validateParameter(valid_607397, JString, required = true,
                                 default = nil)
  if valid_607397 != nil:
    section.add "ResourceDefinitionId", valid_607397
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
  var valid_607398 = header.getOrDefault("X-Amz-Signature")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Signature", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Content-Sha256", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Date")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Date", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Credential")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Credential", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Security-Token")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Security-Token", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Algorithm")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Algorithm", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-SignedHeaders", valid_607404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607405: Call_GetResourceDefinitionVersion_607393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_607405.validator(path, query, header, formData, body)
  let scheme = call_607405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607405.url(scheme.get, call_607405.host, call_607405.base,
                         call_607405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607405, url, valid)

proc call*(call_607406: Call_GetResourceDefinitionVersion_607393;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_607407 = newJObject()
  add(path_607407, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_607407, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_607406.call(path_607407, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_607393(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_607394, base: "/",
    url: url_GetResourceDefinitionVersion_607395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_607408 = ref object of OpenApiRestCall_605573
proc url_GetSubscriptionDefinitionVersion_607410(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinitionVersion_607409(path: JsonNode;
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
  var valid_607411 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_607411 = validateParameter(valid_607411, JString, required = true,
                                 default = nil)
  if valid_607411 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_607411
  var valid_607412 = path.getOrDefault("SubscriptionDefinitionId")
  valid_607412 = validateParameter(valid_607412, JString, required = true,
                                 default = nil)
  if valid_607412 != nil:
    section.add "SubscriptionDefinitionId", valid_607412
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607413 = query.getOrDefault("NextToken")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "NextToken", valid_607413
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
  var valid_607414 = header.getOrDefault("X-Amz-Signature")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Signature", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-Content-Sha256", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-Date")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Date", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Credential")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Credential", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Security-Token")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Security-Token", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Algorithm")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Algorithm", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-SignedHeaders", valid_607420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607421: Call_GetSubscriptionDefinitionVersion_607408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_607421.validator(path, query, header, formData, body)
  let scheme = call_607421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607421.url(scheme.get, call_607421.host, call_607421.base,
                         call_607421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607421, url, valid)

proc call*(call_607422: Call_GetSubscriptionDefinitionVersion_607408;
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
  var path_607423 = newJObject()
  var query_607424 = newJObject()
  add(path_607423, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_607424, "NextToken", newJString(NextToken))
  add(path_607423, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_607422.call(path_607423, query_607424, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_607408(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_607409, base: "/",
    url: url_GetSubscriptionDefinitionVersion_607410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_607425 = ref object of OpenApiRestCall_605573
proc url_ListBulkDeploymentDetailedReports_607427(protocol: Scheme; host: string;
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

proc validate_ListBulkDeploymentDetailedReports_607426(path: JsonNode;
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
  var valid_607428 = path.getOrDefault("BulkDeploymentId")
  valid_607428 = validateParameter(valid_607428, JString, required = true,
                                 default = nil)
  if valid_607428 != nil:
    section.add "BulkDeploymentId", valid_607428
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_607429 = query.getOrDefault("MaxResults")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "MaxResults", valid_607429
  var valid_607430 = query.getOrDefault("NextToken")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "NextToken", valid_607430
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
  var valid_607431 = header.getOrDefault("X-Amz-Signature")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-Signature", valid_607431
  var valid_607432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "X-Amz-Content-Sha256", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Date")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Date", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Credential")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Credential", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Security-Token")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Security-Token", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-Algorithm")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-Algorithm", valid_607436
  var valid_607437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-SignedHeaders", valid_607437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607438: Call_ListBulkDeploymentDetailedReports_607425;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_607438.validator(path, query, header, formData, body)
  let scheme = call_607438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607438.url(scheme.get, call_607438.host, call_607438.base,
                         call_607438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607438, url, valid)

proc call*(call_607439: Call_ListBulkDeploymentDetailedReports_607425;
          BulkDeploymentId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_607440 = newJObject()
  var query_607441 = newJObject()
  add(query_607441, "MaxResults", newJString(MaxResults))
  add(query_607441, "NextToken", newJString(NextToken))
  add(path_607440, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_607439.call(path_607440, query_607441, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_607425(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_607426, base: "/",
    url: url_ListBulkDeploymentDetailedReports_607427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_607457 = ref object of OpenApiRestCall_605573
proc url_StartBulkDeployment_607459(protocol: Scheme; host: string; base: string;
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

proc validate_StartBulkDeployment_607458(path: JsonNode; query: JsonNode;
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
  var valid_607460 = header.getOrDefault("X-Amz-Signature")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Signature", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-Content-Sha256", valid_607461
  var valid_607462 = header.getOrDefault("X-Amz-Date")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "X-Amz-Date", valid_607462
  var valid_607463 = header.getOrDefault("X-Amz-Credential")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-Credential", valid_607463
  var valid_607464 = header.getOrDefault("X-Amzn-Client-Token")
  valid_607464 = validateParameter(valid_607464, JString, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "X-Amzn-Client-Token", valid_607464
  var valid_607465 = header.getOrDefault("X-Amz-Security-Token")
  valid_607465 = validateParameter(valid_607465, JString, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "X-Amz-Security-Token", valid_607465
  var valid_607466 = header.getOrDefault("X-Amz-Algorithm")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Algorithm", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-SignedHeaders", valid_607467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607469: Call_StartBulkDeployment_607457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_607469.validator(path, query, header, formData, body)
  let scheme = call_607469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607469.url(scheme.get, call_607469.host, call_607469.base,
                         call_607469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607469, url, valid)

proc call*(call_607470: Call_StartBulkDeployment_607457; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_607471 = newJObject()
  if body != nil:
    body_607471 = body
  result = call_607470.call(nil, nil, nil, nil, body_607471)

var startBulkDeployment* = Call_StartBulkDeployment_607457(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_607458, base: "/",
    url: url_StartBulkDeployment_607459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_607442 = ref object of OpenApiRestCall_605573
proc url_ListBulkDeployments_607444(protocol: Scheme; host: string; base: string;
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

proc validate_ListBulkDeployments_607443(path: JsonNode; query: JsonNode;
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
  var valid_607445 = query.getOrDefault("MaxResults")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "MaxResults", valid_607445
  var valid_607446 = query.getOrDefault("NextToken")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "NextToken", valid_607446
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
  var valid_607447 = header.getOrDefault("X-Amz-Signature")
  valid_607447 = validateParameter(valid_607447, JString, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "X-Amz-Signature", valid_607447
  var valid_607448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "X-Amz-Content-Sha256", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-Date")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-Date", valid_607449
  var valid_607450 = header.getOrDefault("X-Amz-Credential")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "X-Amz-Credential", valid_607450
  var valid_607451 = header.getOrDefault("X-Amz-Security-Token")
  valid_607451 = validateParameter(valid_607451, JString, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "X-Amz-Security-Token", valid_607451
  var valid_607452 = header.getOrDefault("X-Amz-Algorithm")
  valid_607452 = validateParameter(valid_607452, JString, required = false,
                                 default = nil)
  if valid_607452 != nil:
    section.add "X-Amz-Algorithm", valid_607452
  var valid_607453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-SignedHeaders", valid_607453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607454: Call_ListBulkDeployments_607442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_607454.validator(path, query, header, formData, body)
  let scheme = call_607454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607454.url(scheme.get, call_607454.host, call_607454.base,
                         call_607454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607454, url, valid)

proc call*(call_607455: Call_ListBulkDeployments_607442; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_607456 = newJObject()
  add(query_607456, "MaxResults", newJString(MaxResults))
  add(query_607456, "NextToken", newJString(NextToken))
  result = call_607455.call(nil, query_607456, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_607442(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_607443, base: "/",
    url: url_ListBulkDeployments_607444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607486 = ref object of OpenApiRestCall_605573
proc url_TagResource_607488(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607489 = path.getOrDefault("resource-arn")
  valid_607489 = validateParameter(valid_607489, JString, required = true,
                                 default = nil)
  if valid_607489 != nil:
    section.add "resource-arn", valid_607489
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
  var valid_607490 = header.getOrDefault("X-Amz-Signature")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Signature", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-Content-Sha256", valid_607491
  var valid_607492 = header.getOrDefault("X-Amz-Date")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-Date", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Credential")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Credential", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-Security-Token")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-Security-Token", valid_607494
  var valid_607495 = header.getOrDefault("X-Amz-Algorithm")
  valid_607495 = validateParameter(valid_607495, JString, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "X-Amz-Algorithm", valid_607495
  var valid_607496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "X-Amz-SignedHeaders", valid_607496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607498: Call_TagResource_607486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_607498.validator(path, query, header, formData, body)
  let scheme = call_607498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607498.url(scheme.get, call_607498.host, call_607498.base,
                         call_607498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607498, url, valid)

proc call*(call_607499: Call_TagResource_607486; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_607500 = newJObject()
  var body_607501 = newJObject()
  add(path_607500, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_607501 = body
  result = call_607499.call(path_607500, nil, nil, nil, body_607501)

var tagResource* = Call_TagResource_607486(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_607487,
                                        base: "/", url: url_TagResource_607488,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607472 = ref object of OpenApiRestCall_605573
proc url_ListTagsForResource_607474(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_607473(path: JsonNode; query: JsonNode;
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
  var valid_607475 = path.getOrDefault("resource-arn")
  valid_607475 = validateParameter(valid_607475, JString, required = true,
                                 default = nil)
  if valid_607475 != nil:
    section.add "resource-arn", valid_607475
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
  var valid_607476 = header.getOrDefault("X-Amz-Signature")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Signature", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Content-Sha256", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Date")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Date", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Credential")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Credential", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Security-Token")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Security-Token", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-Algorithm")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Algorithm", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-SignedHeaders", valid_607482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607483: Call_ListTagsForResource_607472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_607483.validator(path, query, header, formData, body)
  let scheme = call_607483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607483.url(scheme.get, call_607483.host, call_607483.base,
                         call_607483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607483, url, valid)

proc call*(call_607484: Call_ListTagsForResource_607472; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_607485 = newJObject()
  add(path_607485, "resource-arn", newJString(resourceArn))
  result = call_607484.call(path_607485, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_607472(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_607473, base: "/",
    url: url_ListTagsForResource_607474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_607502 = ref object of OpenApiRestCall_605573
proc url_ResetDeployments_607504(protocol: Scheme; host: string; base: string;
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

proc validate_ResetDeployments_607503(path: JsonNode; query: JsonNode;
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
  var valid_607505 = path.getOrDefault("GroupId")
  valid_607505 = validateParameter(valid_607505, JString, required = true,
                                 default = nil)
  if valid_607505 != nil:
    section.add "GroupId", valid_607505
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
  var valid_607506 = header.getOrDefault("X-Amz-Signature")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-Signature", valid_607506
  var valid_607507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "X-Amz-Content-Sha256", valid_607507
  var valid_607508 = header.getOrDefault("X-Amz-Date")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "X-Amz-Date", valid_607508
  var valid_607509 = header.getOrDefault("X-Amz-Credential")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "X-Amz-Credential", valid_607509
  var valid_607510 = header.getOrDefault("X-Amzn-Client-Token")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amzn-Client-Token", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Security-Token")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Security-Token", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Algorithm")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Algorithm", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-SignedHeaders", valid_607513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607515: Call_ResetDeployments_607502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_607515.validator(path, query, header, formData, body)
  let scheme = call_607515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607515.url(scheme.get, call_607515.host, call_607515.base,
                         call_607515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607515, url, valid)

proc call*(call_607516: Call_ResetDeployments_607502; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_607517 = newJObject()
  var body_607518 = newJObject()
  add(path_607517, "GroupId", newJString(GroupId))
  if body != nil:
    body_607518 = body
  result = call_607516.call(path_607517, nil, nil, nil, body_607518)

var resetDeployments* = Call_ResetDeployments_607502(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_607503, base: "/",
    url: url_ResetDeployments_607504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_607519 = ref object of OpenApiRestCall_605573
proc url_StopBulkDeployment_607521(protocol: Scheme; host: string; base: string;
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

proc validate_StopBulkDeployment_607520(path: JsonNode; query: JsonNode;
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
  var valid_607522 = path.getOrDefault("BulkDeploymentId")
  valid_607522 = validateParameter(valid_607522, JString, required = true,
                                 default = nil)
  if valid_607522 != nil:
    section.add "BulkDeploymentId", valid_607522
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
  var valid_607523 = header.getOrDefault("X-Amz-Signature")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-Signature", valid_607523
  var valid_607524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607524 = validateParameter(valid_607524, JString, required = false,
                                 default = nil)
  if valid_607524 != nil:
    section.add "X-Amz-Content-Sha256", valid_607524
  var valid_607525 = header.getOrDefault("X-Amz-Date")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-Date", valid_607525
  var valid_607526 = header.getOrDefault("X-Amz-Credential")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Credential", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Security-Token")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Security-Token", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Algorithm")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Algorithm", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-SignedHeaders", valid_607529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607530: Call_StopBulkDeployment_607519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_607530.validator(path, query, header, formData, body)
  let scheme = call_607530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607530.url(scheme.get, call_607530.host, call_607530.base,
                         call_607530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607530, url, valid)

proc call*(call_607531: Call_StopBulkDeployment_607519; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_607532 = newJObject()
  add(path_607532, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_607531.call(path_607532, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_607519(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_607520, base: "/",
    url: url_StopBulkDeployment_607521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607533 = ref object of OpenApiRestCall_605573
proc url_UntagResource_607535(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607536 = path.getOrDefault("resource-arn")
  valid_607536 = validateParameter(valid_607536, JString, required = true,
                                 default = nil)
  if valid_607536 != nil:
    section.add "resource-arn", valid_607536
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_607537 = query.getOrDefault("tagKeys")
  valid_607537 = validateParameter(valid_607537, JArray, required = true, default = nil)
  if valid_607537 != nil:
    section.add "tagKeys", valid_607537
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
  var valid_607538 = header.getOrDefault("X-Amz-Signature")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Signature", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-Content-Sha256", valid_607539
  var valid_607540 = header.getOrDefault("X-Amz-Date")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "X-Amz-Date", valid_607540
  var valid_607541 = header.getOrDefault("X-Amz-Credential")
  valid_607541 = validateParameter(valid_607541, JString, required = false,
                                 default = nil)
  if valid_607541 != nil:
    section.add "X-Amz-Credential", valid_607541
  var valid_607542 = header.getOrDefault("X-Amz-Security-Token")
  valid_607542 = validateParameter(valid_607542, JString, required = false,
                                 default = nil)
  if valid_607542 != nil:
    section.add "X-Amz-Security-Token", valid_607542
  var valid_607543 = header.getOrDefault("X-Amz-Algorithm")
  valid_607543 = validateParameter(valid_607543, JString, required = false,
                                 default = nil)
  if valid_607543 != nil:
    section.add "X-Amz-Algorithm", valid_607543
  var valid_607544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "X-Amz-SignedHeaders", valid_607544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607545: Call_UntagResource_607533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_607545.validator(path, query, header, formData, body)
  let scheme = call_607545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607545.url(scheme.get, call_607545.host, call_607545.base,
                         call_607545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607545, url, valid)

proc call*(call_607546: Call_UntagResource_607533; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_607547 = newJObject()
  var query_607548 = newJObject()
  add(path_607547, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_607548.add "tagKeys", tagKeys
  result = call_607546.call(path_607547, query_607548, nil, nil, nil)

var untagResource* = Call_UntagResource_607533(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_607534,
    base: "/", url: url_UntagResource_607535, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
