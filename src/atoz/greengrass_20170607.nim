
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRoleToGroup_773187 = ref object of OpenApiRestCall_772581
proc url_AssociateRoleToGroup_773189(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AssociateRoleToGroup_773188(path: JsonNode; query: JsonNode;
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
  var valid_773190 = path.getOrDefault("GroupId")
  valid_773190 = validateParameter(valid_773190, JString, required = true,
                                 default = nil)
  if valid_773190 != nil:
    section.add "GroupId", valid_773190
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
  var valid_773191 = header.getOrDefault("X-Amz-Date")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Date", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Security-Token")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Security-Token", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Content-Sha256", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Algorithm")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Algorithm", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Signature")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Signature", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-SignedHeaders", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Credential")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Credential", valid_773197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773199: Call_AssociateRoleToGroup_773187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_773199.validator(path, query, header, formData, body)
  let scheme = call_773199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773199.url(scheme.get, call_773199.host, call_773199.base,
                         call_773199.route, valid.getOrDefault("path"))
  result = hook(call_773199, url, valid)

proc call*(call_773200: Call_AssociateRoleToGroup_773187; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_773201 = newJObject()
  var body_773202 = newJObject()
  add(path_773201, "GroupId", newJString(GroupId))
  if body != nil:
    body_773202 = body
  result = call_773200.call(path_773201, nil, nil, nil, body_773202)

var associateRoleToGroup* = Call_AssociateRoleToGroup_773187(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_773188, base: "/",
    url: url_AssociateRoleToGroup_773189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_772917 = ref object of OpenApiRestCall_772581
proc url_GetAssociatedRole_772919(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetAssociatedRole_772918(path: JsonNode; query: JsonNode;
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
  var valid_773045 = path.getOrDefault("GroupId")
  valid_773045 = validateParameter(valid_773045, JString, required = true,
                                 default = nil)
  if valid_773045 != nil:
    section.add "GroupId", valid_773045
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
  var valid_773046 = header.getOrDefault("X-Amz-Date")
  valid_773046 = validateParameter(valid_773046, JString, required = false,
                                 default = nil)
  if valid_773046 != nil:
    section.add "X-Amz-Date", valid_773046
  var valid_773047 = header.getOrDefault("X-Amz-Security-Token")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Security-Token", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Content-Sha256", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Algorithm")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Algorithm", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Signature")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Signature", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-SignedHeaders", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Credential")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Credential", valid_773052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773075: Call_GetAssociatedRole_772917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_773075.validator(path, query, header, formData, body)
  let scheme = call_773075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773075.url(scheme.get, call_773075.host, call_773075.base,
                         call_773075.route, valid.getOrDefault("path"))
  result = hook(call_773075, url, valid)

proc call*(call_773146: Call_GetAssociatedRole_772917; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_773147 = newJObject()
  add(path_773147, "GroupId", newJString(GroupId))
  result = call_773146.call(path_773147, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_772917(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_772918, base: "/",
    url: url_GetAssociatedRole_772919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_773203 = ref object of OpenApiRestCall_772581
proc url_DisassociateRoleFromGroup_773205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/role")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociateRoleFromGroup_773204(path: JsonNode; query: JsonNode;
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
  var valid_773206 = path.getOrDefault("GroupId")
  valid_773206 = validateParameter(valid_773206, JString, required = true,
                                 default = nil)
  if valid_773206 != nil:
    section.add "GroupId", valid_773206
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
  var valid_773207 = header.getOrDefault("X-Amz-Date")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Date", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Security-Token")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Security-Token", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Content-Sha256", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Algorithm")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Algorithm", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Signature")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Signature", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-SignedHeaders", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Credential")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Credential", valid_773213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_DisassociateRoleFromGroup_773203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_DisassociateRoleFromGroup_773203; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_773216 = newJObject()
  add(path_773216, "GroupId", newJString(GroupId))
  result = call_773215.call(path_773216, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_773203(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_773204, base: "/",
    url: url_DisassociateRoleFromGroup_773205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_773229 = ref object of OpenApiRestCall_772581
proc url_AssociateServiceRoleToAccount_773231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateServiceRoleToAccount_773230(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773232 = header.getOrDefault("X-Amz-Date")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Date", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Security-Token")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Security-Token", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Content-Sha256", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Algorithm")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Algorithm", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Signature")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Signature", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-SignedHeaders", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Credential")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Credential", valid_773238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_AssociateServiceRoleToAccount_773229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_AssociateServiceRoleToAccount_773229; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_773242 = newJObject()
  if body != nil:
    body_773242 = body
  result = call_773241.call(nil, nil, nil, nil, body_773242)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_773229(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_773230, base: "/",
    url: url_AssociateServiceRoleToAccount_773231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_773217 = ref object of OpenApiRestCall_772581
proc url_GetServiceRoleForAccount_773219(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServiceRoleForAccount_773218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Content-Sha256", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Algorithm")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Algorithm", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Signature")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Signature", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-SignedHeaders", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Credential")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Credential", valid_773226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773227: Call_GetServiceRoleForAccount_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_773227.validator(path, query, header, formData, body)
  let scheme = call_773227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773227.url(scheme.get, call_773227.host, call_773227.base,
                         call_773227.route, valid.getOrDefault("path"))
  result = hook(call_773227, url, valid)

proc call*(call_773228: Call_GetServiceRoleForAccount_773217): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_773228.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_773217(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_773218, base: "/",
    url: url_GetServiceRoleForAccount_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_773243 = ref object of OpenApiRestCall_772581
proc url_DisassociateServiceRoleFromAccount_773245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateServiceRoleFromAccount_773244(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773246 = header.getOrDefault("X-Amz-Date")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Date", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Security-Token")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Security-Token", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Content-Sha256", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Algorithm")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Algorithm", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Signature")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Signature", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-SignedHeaders", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Credential")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Credential", valid_773252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773253: Call_DisassociateServiceRoleFromAccount_773243;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_773253.validator(path, query, header, formData, body)
  let scheme = call_773253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773253.url(scheme.get, call_773253.host, call_773253.base,
                         call_773253.route, valid.getOrDefault("path"))
  result = hook(call_773253, url, valid)

proc call*(call_773254: Call_DisassociateServiceRoleFromAccount_773243): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_773254.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_773243(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_773244, base: "/",
    url: url_DisassociateServiceRoleFromAccount_773245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_773270 = ref object of OpenApiRestCall_772581
proc url_CreateConnectorDefinition_773272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateConnectorDefinition_773271(path: JsonNode; query: JsonNode;
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
  var valid_773273 = header.getOrDefault("X-Amz-Date")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Date", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Security-Token")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Security-Token", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Content-Sha256", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Algorithm")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Algorithm", valid_773276
  var valid_773277 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amzn-Client-Token", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Signature")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Signature", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-SignedHeaders", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Credential")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Credential", valid_773280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773282: Call_CreateConnectorDefinition_773270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_773282.validator(path, query, header, formData, body)
  let scheme = call_773282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773282.url(scheme.get, call_773282.host, call_773282.base,
                         call_773282.route, valid.getOrDefault("path"))
  result = hook(call_773282, url, valid)

proc call*(call_773283: Call_CreateConnectorDefinition_773270; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_773284 = newJObject()
  if body != nil:
    body_773284 = body
  result = call_773283.call(nil, nil, nil, nil, body_773284)

var createConnectorDefinition* = Call_CreateConnectorDefinition_773270(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_773271, base: "/",
    url: url_CreateConnectorDefinition_773272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_773255 = ref object of OpenApiRestCall_772581
proc url_ListConnectorDefinitions_773257(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConnectorDefinitions_773256(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773258 = query.getOrDefault("NextToken")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "NextToken", valid_773258
  var valid_773259 = query.getOrDefault("MaxResults")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "MaxResults", valid_773259
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
  var valid_773260 = header.getOrDefault("X-Amz-Date")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Date", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Security-Token")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Security-Token", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Content-Sha256", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Algorithm")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Algorithm", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Signature")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Signature", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-SignedHeaders", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Credential")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Credential", valid_773266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773267: Call_ListConnectorDefinitions_773255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_773267.validator(path, query, header, formData, body)
  let scheme = call_773267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773267.url(scheme.get, call_773267.host, call_773267.base,
                         call_773267.route, valid.getOrDefault("path"))
  result = hook(call_773267, url, valid)

proc call*(call_773268: Call_ListConnectorDefinitions_773255;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773269 = newJObject()
  add(query_773269, "NextToken", newJString(NextToken))
  add(query_773269, "MaxResults", newJString(MaxResults))
  result = call_773268.call(nil, query_773269, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_773255(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_773256, base: "/",
    url: url_ListConnectorDefinitions_773257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_773302 = ref object of OpenApiRestCall_772581
proc url_CreateConnectorDefinitionVersion_773304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateConnectorDefinitionVersion_773303(path: JsonNode;
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
  var valid_773305 = path.getOrDefault("ConnectorDefinitionId")
  valid_773305 = validateParameter(valid_773305, JString, required = true,
                                 default = nil)
  if valid_773305 != nil:
    section.add "ConnectorDefinitionId", valid_773305
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
  var valid_773306 = header.getOrDefault("X-Amz-Date")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Date", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Security-Token")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Security-Token", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Content-Sha256", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Algorithm")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Algorithm", valid_773309
  var valid_773310 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amzn-Client-Token", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Signature")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Signature", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-SignedHeaders", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Credential")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Credential", valid_773313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773315: Call_CreateConnectorDefinitionVersion_773302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_773315.validator(path, query, header, formData, body)
  let scheme = call_773315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773315.url(scheme.get, call_773315.host, call_773315.base,
                         call_773315.route, valid.getOrDefault("path"))
  result = hook(call_773315, url, valid)

proc call*(call_773316: Call_CreateConnectorDefinitionVersion_773302;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_773317 = newJObject()
  var body_773318 = newJObject()
  add(path_773317, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_773318 = body
  result = call_773316.call(path_773317, nil, nil, nil, body_773318)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_773302(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_773303, base: "/",
    url: url_CreateConnectorDefinitionVersion_773304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_773285 = ref object of OpenApiRestCall_772581
proc url_ListConnectorDefinitionVersions_773287(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListConnectorDefinitionVersions_773286(path: JsonNode;
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
  var valid_773288 = path.getOrDefault("ConnectorDefinitionId")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "ConnectorDefinitionId", valid_773288
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773289 = query.getOrDefault("NextToken")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "NextToken", valid_773289
  var valid_773290 = query.getOrDefault("MaxResults")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "MaxResults", valid_773290
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
  var valid_773291 = header.getOrDefault("X-Amz-Date")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Date", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Security-Token")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Security-Token", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Content-Sha256", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Algorithm")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Algorithm", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Signature")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Signature", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-SignedHeaders", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Credential")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Credential", valid_773297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773298: Call_ListConnectorDefinitionVersions_773285;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_773298.validator(path, query, header, formData, body)
  let scheme = call_773298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773298.url(scheme.get, call_773298.host, call_773298.base,
                         call_773298.route, valid.getOrDefault("path"))
  result = hook(call_773298, url, valid)

proc call*(call_773299: Call_ListConnectorDefinitionVersions_773285;
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
  var path_773300 = newJObject()
  var query_773301 = newJObject()
  add(query_773301, "NextToken", newJString(NextToken))
  add(path_773300, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(query_773301, "MaxResults", newJString(MaxResults))
  result = call_773299.call(path_773300, query_773301, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_773285(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_773286, base: "/",
    url: url_ListConnectorDefinitionVersions_773287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_773334 = ref object of OpenApiRestCall_772581
proc url_CreateCoreDefinition_773336(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCoreDefinition_773335(path: JsonNode; query: JsonNode;
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
  var valid_773337 = header.getOrDefault("X-Amz-Date")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Date", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Security-Token")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Security-Token", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Content-Sha256", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Algorithm")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Algorithm", valid_773340
  var valid_773341 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amzn-Client-Token", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Signature")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Signature", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-SignedHeaders", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Credential")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Credential", valid_773344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773346: Call_CreateCoreDefinition_773334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_773346.validator(path, query, header, formData, body)
  let scheme = call_773346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773346.url(scheme.get, call_773346.host, call_773346.base,
                         call_773346.route, valid.getOrDefault("path"))
  result = hook(call_773346, url, valid)

proc call*(call_773347: Call_CreateCoreDefinition_773334; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_773348 = newJObject()
  if body != nil:
    body_773348 = body
  result = call_773347.call(nil, nil, nil, nil, body_773348)

var createCoreDefinition* = Call_CreateCoreDefinition_773334(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_773335, base: "/",
    url: url_CreateCoreDefinition_773336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_773319 = ref object of OpenApiRestCall_772581
proc url_ListCoreDefinitions_773321(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCoreDefinitions_773320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_773322 = query.getOrDefault("NextToken")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "NextToken", valid_773322
  var valid_773323 = query.getOrDefault("MaxResults")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "MaxResults", valid_773323
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
  var valid_773324 = header.getOrDefault("X-Amz-Date")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Date", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Security-Token")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Security-Token", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Content-Sha256", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Algorithm")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Algorithm", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Signature")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Signature", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-SignedHeaders", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Credential")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Credential", valid_773330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773331: Call_ListCoreDefinitions_773319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_773331.validator(path, query, header, formData, body)
  let scheme = call_773331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773331.url(scheme.get, call_773331.host, call_773331.base,
                         call_773331.route, valid.getOrDefault("path"))
  result = hook(call_773331, url, valid)

proc call*(call_773332: Call_ListCoreDefinitions_773319; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773333 = newJObject()
  add(query_773333, "NextToken", newJString(NextToken))
  add(query_773333, "MaxResults", newJString(MaxResults))
  result = call_773332.call(nil, query_773333, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_773319(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_773320, base: "/",
    url: url_ListCoreDefinitions_773321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_773366 = ref object of OpenApiRestCall_772581
proc url_CreateCoreDefinitionVersion_773368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateCoreDefinitionVersion_773367(path: JsonNode; query: JsonNode;
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
  var valid_773369 = path.getOrDefault("CoreDefinitionId")
  valid_773369 = validateParameter(valid_773369, JString, required = true,
                                 default = nil)
  if valid_773369 != nil:
    section.add "CoreDefinitionId", valid_773369
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Content-Sha256", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Algorithm")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Algorithm", valid_773373
  var valid_773374 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amzn-Client-Token", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_CreateCoreDefinitionVersion_773366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_CreateCoreDefinitionVersion_773366;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_773381 = newJObject()
  var body_773382 = newJObject()
  add(path_773381, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_773382 = body
  result = call_773380.call(path_773381, nil, nil, nil, body_773382)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_773366(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_773367, base: "/",
    url: url_CreateCoreDefinitionVersion_773368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_773349 = ref object of OpenApiRestCall_772581
proc url_ListCoreDefinitionVersions_773351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListCoreDefinitionVersions_773350(path: JsonNode; query: JsonNode;
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
  var valid_773352 = path.getOrDefault("CoreDefinitionId")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = nil)
  if valid_773352 != nil:
    section.add "CoreDefinitionId", valid_773352
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773353 = query.getOrDefault("NextToken")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "NextToken", valid_773353
  var valid_773354 = query.getOrDefault("MaxResults")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "MaxResults", valid_773354
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Content-Sha256", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Algorithm")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Algorithm", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Signature")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Signature", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-SignedHeaders", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Credential")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Credential", valid_773361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773362: Call_ListCoreDefinitionVersions_773349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_773362.validator(path, query, header, formData, body)
  let scheme = call_773362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773362.url(scheme.get, call_773362.host, call_773362.base,
                         call_773362.route, valid.getOrDefault("path"))
  result = hook(call_773362, url, valid)

proc call*(call_773363: Call_ListCoreDefinitionVersions_773349;
          CoreDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_773364 = newJObject()
  var query_773365 = newJObject()
  add(path_773364, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(query_773365, "NextToken", newJString(NextToken))
  add(query_773365, "MaxResults", newJString(MaxResults))
  result = call_773363.call(path_773364, query_773365, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_773349(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_773350, base: "/",
    url: url_ListCoreDefinitionVersions_773351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_773400 = ref object of OpenApiRestCall_772581
proc url_CreateDeployment_773402(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDeployment_773401(path: JsonNode; query: JsonNode;
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
  var valid_773403 = path.getOrDefault("GroupId")
  valid_773403 = validateParameter(valid_773403, JString, required = true,
                                 default = nil)
  if valid_773403 != nil:
    section.add "GroupId", valid_773403
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
  var valid_773404 = header.getOrDefault("X-Amz-Date")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Date", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Security-Token")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Security-Token", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Content-Sha256", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Algorithm")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Algorithm", valid_773407
  var valid_773408 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amzn-Client-Token", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Signature")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Signature", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-SignedHeaders", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Credential")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Credential", valid_773411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773413: Call_CreateDeployment_773400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_773413.validator(path, query, header, formData, body)
  let scheme = call_773413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773413.url(scheme.get, call_773413.host, call_773413.base,
                         call_773413.route, valid.getOrDefault("path"))
  result = hook(call_773413, url, valid)

proc call*(call_773414: Call_CreateDeployment_773400; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_773415 = newJObject()
  var body_773416 = newJObject()
  add(path_773415, "GroupId", newJString(GroupId))
  if body != nil:
    body_773416 = body
  result = call_773414.call(path_773415, nil, nil, nil, body_773416)

var createDeployment* = Call_CreateDeployment_773400(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_773401, base: "/",
    url: url_CreateDeployment_773402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_773383 = ref object of OpenApiRestCall_772581
proc url_ListDeployments_773385(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDeployments_773384(path: JsonNode; query: JsonNode;
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
  var valid_773386 = path.getOrDefault("GroupId")
  valid_773386 = validateParameter(valid_773386, JString, required = true,
                                 default = nil)
  if valid_773386 != nil:
    section.add "GroupId", valid_773386
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773387 = query.getOrDefault("NextToken")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "NextToken", valid_773387
  var valid_773388 = query.getOrDefault("MaxResults")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "MaxResults", valid_773388
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
  var valid_773389 = header.getOrDefault("X-Amz-Date")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Date", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Security-Token")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Security-Token", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Content-Sha256", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Algorithm")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Algorithm", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Signature")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Signature", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-SignedHeaders", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Credential")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Credential", valid_773395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773396: Call_ListDeployments_773383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_773396.validator(path, query, header, formData, body)
  let scheme = call_773396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773396.url(scheme.get, call_773396.host, call_773396.base,
                         call_773396.route, valid.getOrDefault("path"))
  result = hook(call_773396, url, valid)

proc call*(call_773397: Call_ListDeployments_773383; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_773398 = newJObject()
  var query_773399 = newJObject()
  add(path_773398, "GroupId", newJString(GroupId))
  add(query_773399, "NextToken", newJString(NextToken))
  add(query_773399, "MaxResults", newJString(MaxResults))
  result = call_773397.call(path_773398, query_773399, nil, nil, nil)

var listDeployments* = Call_ListDeployments_773383(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_773384, base: "/", url: url_ListDeployments_773385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_773432 = ref object of OpenApiRestCall_772581
proc url_CreateDeviceDefinition_773434(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeviceDefinition_773433(path: JsonNode; query: JsonNode;
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
  var valid_773435 = header.getOrDefault("X-Amz-Date")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Date", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Security-Token")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Security-Token", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Content-Sha256", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Algorithm")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Algorithm", valid_773438
  var valid_773439 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amzn-Client-Token", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Signature")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Signature", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-SignedHeaders", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Credential")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Credential", valid_773442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773444: Call_CreateDeviceDefinition_773432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_773444.validator(path, query, header, formData, body)
  let scheme = call_773444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773444.url(scheme.get, call_773444.host, call_773444.base,
                         call_773444.route, valid.getOrDefault("path"))
  result = hook(call_773444, url, valid)

proc call*(call_773445: Call_CreateDeviceDefinition_773432; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_773446 = newJObject()
  if body != nil:
    body_773446 = body
  result = call_773445.call(nil, nil, nil, nil, body_773446)

var createDeviceDefinition* = Call_CreateDeviceDefinition_773432(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_773433, base: "/",
    url: url_CreateDeviceDefinition_773434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_773417 = ref object of OpenApiRestCall_772581
proc url_ListDeviceDefinitions_773419(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeviceDefinitions_773418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773420 = query.getOrDefault("NextToken")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "NextToken", valid_773420
  var valid_773421 = query.getOrDefault("MaxResults")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "MaxResults", valid_773421
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
  var valid_773422 = header.getOrDefault("X-Amz-Date")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Date", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Security-Token")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Security-Token", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Content-Sha256", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Algorithm")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Algorithm", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Signature")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Signature", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-SignedHeaders", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Credential")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Credential", valid_773428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773429: Call_ListDeviceDefinitions_773417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_773429.validator(path, query, header, formData, body)
  let scheme = call_773429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773429.url(scheme.get, call_773429.host, call_773429.base,
                         call_773429.route, valid.getOrDefault("path"))
  result = hook(call_773429, url, valid)

proc call*(call_773430: Call_ListDeviceDefinitions_773417; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773431 = newJObject()
  add(query_773431, "NextToken", newJString(NextToken))
  add(query_773431, "MaxResults", newJString(MaxResults))
  result = call_773430.call(nil, query_773431, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_773417(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_773418, base: "/",
    url: url_ListDeviceDefinitions_773419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_773464 = ref object of OpenApiRestCall_772581
proc url_CreateDeviceDefinitionVersion_773466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDeviceDefinitionVersion_773465(path: JsonNode; query: JsonNode;
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
  var valid_773467 = path.getOrDefault("DeviceDefinitionId")
  valid_773467 = validateParameter(valid_773467, JString, required = true,
                                 default = nil)
  if valid_773467 != nil:
    section.add "DeviceDefinitionId", valid_773467
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
  var valid_773468 = header.getOrDefault("X-Amz-Date")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Date", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Security-Token")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Security-Token", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Content-Sha256", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Algorithm")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Algorithm", valid_773471
  var valid_773472 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amzn-Client-Token", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Signature")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Signature", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-SignedHeaders", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Credential")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Credential", valid_773475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773477: Call_CreateDeviceDefinitionVersion_773464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_773477.validator(path, query, header, formData, body)
  let scheme = call_773477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773477.url(scheme.get, call_773477.host, call_773477.base,
                         call_773477.route, valid.getOrDefault("path"))
  result = hook(call_773477, url, valid)

proc call*(call_773478: Call_CreateDeviceDefinitionVersion_773464;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_773479 = newJObject()
  var body_773480 = newJObject()
  add(path_773479, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_773480 = body
  result = call_773478.call(path_773479, nil, nil, nil, body_773480)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_773464(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_773465, base: "/",
    url: url_CreateDeviceDefinitionVersion_773466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_773447 = ref object of OpenApiRestCall_772581
proc url_ListDeviceDefinitionVersions_773449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDeviceDefinitionVersions_773448(path: JsonNode; query: JsonNode;
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
  var valid_773450 = path.getOrDefault("DeviceDefinitionId")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "DeviceDefinitionId", valid_773450
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773451 = query.getOrDefault("NextToken")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "NextToken", valid_773451
  var valid_773452 = query.getOrDefault("MaxResults")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "MaxResults", valid_773452
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
  var valid_773453 = header.getOrDefault("X-Amz-Date")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Date", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Security-Token")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Security-Token", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Content-Sha256", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Algorithm")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Algorithm", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Signature")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Signature", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-SignedHeaders", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Credential")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Credential", valid_773459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773460: Call_ListDeviceDefinitionVersions_773447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_773460.validator(path, query, header, formData, body)
  let scheme = call_773460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773460.url(scheme.get, call_773460.host, call_773460.base,
                         call_773460.route, valid.getOrDefault("path"))
  result = hook(call_773460, url, valid)

proc call*(call_773461: Call_ListDeviceDefinitionVersions_773447;
          DeviceDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_773462 = newJObject()
  var query_773463 = newJObject()
  add(path_773462, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_773463, "NextToken", newJString(NextToken))
  add(query_773463, "MaxResults", newJString(MaxResults))
  result = call_773461.call(path_773462, query_773463, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_773447(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_773448, base: "/",
    url: url_ListDeviceDefinitionVersions_773449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_773496 = ref object of OpenApiRestCall_772581
proc url_CreateFunctionDefinition_773498(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFunctionDefinition_773497(path: JsonNode; query: JsonNode;
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
  var valid_773499 = header.getOrDefault("X-Amz-Date")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Date", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Security-Token")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Security-Token", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Content-Sha256", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Algorithm")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Algorithm", valid_773502
  var valid_773503 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amzn-Client-Token", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Signature")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Signature", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-SignedHeaders", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Credential")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Credential", valid_773506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_CreateFunctionDefinition_773496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_CreateFunctionDefinition_773496; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_773510 = newJObject()
  if body != nil:
    body_773510 = body
  result = call_773509.call(nil, nil, nil, nil, body_773510)

var createFunctionDefinition* = Call_CreateFunctionDefinition_773496(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_773497, base: "/",
    url: url_CreateFunctionDefinition_773498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_773481 = ref object of OpenApiRestCall_772581
proc url_ListFunctionDefinitions_773483(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFunctionDefinitions_773482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773484 = query.getOrDefault("NextToken")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "NextToken", valid_773484
  var valid_773485 = query.getOrDefault("MaxResults")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "MaxResults", valid_773485
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
  var valid_773486 = header.getOrDefault("X-Amz-Date")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Date", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Security-Token")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Security-Token", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Content-Sha256", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Algorithm")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Algorithm", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Signature")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Signature", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-SignedHeaders", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Credential")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Credential", valid_773492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773493: Call_ListFunctionDefinitions_773481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_773493.validator(path, query, header, formData, body)
  let scheme = call_773493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773493.url(scheme.get, call_773493.host, call_773493.base,
                         call_773493.route, valid.getOrDefault("path"))
  result = hook(call_773493, url, valid)

proc call*(call_773494: Call_ListFunctionDefinitions_773481;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773495 = newJObject()
  add(query_773495, "NextToken", newJString(NextToken))
  add(query_773495, "MaxResults", newJString(MaxResults))
  result = call_773494.call(nil, query_773495, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_773481(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_773482, base: "/",
    url: url_ListFunctionDefinitions_773483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_773528 = ref object of OpenApiRestCall_772581
proc url_CreateFunctionDefinitionVersion_773530(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateFunctionDefinitionVersion_773529(path: JsonNode;
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
  var valid_773531 = path.getOrDefault("FunctionDefinitionId")
  valid_773531 = validateParameter(valid_773531, JString, required = true,
                                 default = nil)
  if valid_773531 != nil:
    section.add "FunctionDefinitionId", valid_773531
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
  var valid_773532 = header.getOrDefault("X-Amz-Date")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Date", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Security-Token")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Security-Token", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Content-Sha256", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Algorithm")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Algorithm", valid_773535
  var valid_773536 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amzn-Client-Token", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Signature")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Signature", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-SignedHeaders", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Credential")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Credential", valid_773539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773541: Call_CreateFunctionDefinitionVersion_773528;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_773541.validator(path, query, header, formData, body)
  let scheme = call_773541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773541.url(scheme.get, call_773541.host, call_773541.base,
                         call_773541.route, valid.getOrDefault("path"))
  result = hook(call_773541, url, valid)

proc call*(call_773542: Call_CreateFunctionDefinitionVersion_773528;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_773543 = newJObject()
  var body_773544 = newJObject()
  add(path_773543, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_773544 = body
  result = call_773542.call(path_773543, nil, nil, nil, body_773544)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_773528(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_773529, base: "/",
    url: url_CreateFunctionDefinitionVersion_773530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_773511 = ref object of OpenApiRestCall_772581
proc url_ListFunctionDefinitionVersions_773513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListFunctionDefinitionVersions_773512(path: JsonNode;
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
  var valid_773514 = path.getOrDefault("FunctionDefinitionId")
  valid_773514 = validateParameter(valid_773514, JString, required = true,
                                 default = nil)
  if valid_773514 != nil:
    section.add "FunctionDefinitionId", valid_773514
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773515 = query.getOrDefault("NextToken")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "NextToken", valid_773515
  var valid_773516 = query.getOrDefault("MaxResults")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "MaxResults", valid_773516
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
  var valid_773517 = header.getOrDefault("X-Amz-Date")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Date", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Security-Token")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Security-Token", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Content-Sha256", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Algorithm")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Algorithm", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Signature")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Signature", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-SignedHeaders", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Credential")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Credential", valid_773523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773524: Call_ListFunctionDefinitionVersions_773511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_773524.validator(path, query, header, formData, body)
  let scheme = call_773524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773524.url(scheme.get, call_773524.host, call_773524.base,
                         call_773524.route, valid.getOrDefault("path"))
  result = hook(call_773524, url, valid)

proc call*(call_773525: Call_ListFunctionDefinitionVersions_773511;
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
  var path_773526 = newJObject()
  var query_773527 = newJObject()
  add(query_773527, "NextToken", newJString(NextToken))
  add(path_773526, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  add(query_773527, "MaxResults", newJString(MaxResults))
  result = call_773525.call(path_773526, query_773527, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_773511(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_773512, base: "/",
    url: url_ListFunctionDefinitionVersions_773513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_773560 = ref object of OpenApiRestCall_772581
proc url_CreateGroup_773562(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGroup_773561(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773563 = header.getOrDefault("X-Amz-Date")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Date", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Security-Token")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Security-Token", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Content-Sha256", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Algorithm")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Algorithm", valid_773566
  var valid_773567 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amzn-Client-Token", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Signature")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Signature", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-SignedHeaders", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Credential")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Credential", valid_773570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773572: Call_CreateGroup_773560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_773572.validator(path, query, header, formData, body)
  let scheme = call_773572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773572.url(scheme.get, call_773572.host, call_773572.base,
                         call_773572.route, valid.getOrDefault("path"))
  result = hook(call_773572, url, valid)

proc call*(call_773573: Call_CreateGroup_773560; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_773574 = newJObject()
  if body != nil:
    body_773574 = body
  result = call_773573.call(nil, nil, nil, nil, body_773574)

var createGroup* = Call_CreateGroup_773560(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_773561,
                                        base: "/", url: url_CreateGroup_773562,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_773545 = ref object of OpenApiRestCall_772581
proc url_ListGroups_773547(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGroups_773546(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773548 = query.getOrDefault("NextToken")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "NextToken", valid_773548
  var valid_773549 = query.getOrDefault("MaxResults")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "MaxResults", valid_773549
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Content-Sha256", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Algorithm")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Algorithm", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Signature")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Signature", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-SignedHeaders", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Credential")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Credential", valid_773556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773557: Call_ListGroups_773545; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_773557.validator(path, query, header, formData, body)
  let scheme = call_773557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773557.url(scheme.get, call_773557.host, call_773557.base,
                         call_773557.route, valid.getOrDefault("path"))
  result = hook(call_773557, url, valid)

proc call*(call_773558: Call_ListGroups_773545; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773559 = newJObject()
  add(query_773559, "NextToken", newJString(NextToken))
  add(query_773559, "MaxResults", newJString(MaxResults))
  result = call_773558.call(nil, query_773559, nil, nil, nil)

var listGroups* = Call_ListGroups_773545(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_773546,
                                      base: "/", url: url_ListGroups_773547,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_773589 = ref object of OpenApiRestCall_772581
proc url_CreateGroupCertificateAuthority_773591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/certificateauthorities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateGroupCertificateAuthority_773590(path: JsonNode;
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
  var valid_773592 = path.getOrDefault("GroupId")
  valid_773592 = validateParameter(valid_773592, JString, required = true,
                                 default = nil)
  if valid_773592 != nil:
    section.add "GroupId", valid_773592
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
  var valid_773593 = header.getOrDefault("X-Amz-Date")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Date", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Security-Token")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Security-Token", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amzn-Client-Token", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Signature")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Signature", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-SignedHeaders", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Credential")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Credential", valid_773600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_CreateGroupCertificateAuthority_773589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_CreateGroupCertificateAuthority_773589;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_773603 = newJObject()
  add(path_773603, "GroupId", newJString(GroupId))
  result = call_773602.call(path_773603, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_773589(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_773590, base: "/",
    url: url_CreateGroupCertificateAuthority_773591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_773575 = ref object of OpenApiRestCall_772581
proc url_ListGroupCertificateAuthorities_773577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/certificateauthorities")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListGroupCertificateAuthorities_773576(path: JsonNode;
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
  var valid_773578 = path.getOrDefault("GroupId")
  valid_773578 = validateParameter(valid_773578, JString, required = true,
                                 default = nil)
  if valid_773578 != nil:
    section.add "GroupId", valid_773578
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
  var valid_773579 = header.getOrDefault("X-Amz-Date")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Date", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Security-Token")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Security-Token", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Content-Sha256", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Algorithm")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Algorithm", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Signature")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Signature", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-SignedHeaders", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Credential")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Credential", valid_773585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773586: Call_ListGroupCertificateAuthorities_773575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_773586.validator(path, query, header, formData, body)
  let scheme = call_773586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773586.url(scheme.get, call_773586.host, call_773586.base,
                         call_773586.route, valid.getOrDefault("path"))
  result = hook(call_773586, url, valid)

proc call*(call_773587: Call_ListGroupCertificateAuthorities_773575;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_773588 = newJObject()
  add(path_773588, "GroupId", newJString(GroupId))
  result = call_773587.call(path_773588, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_773575(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_773576, base: "/",
    url: url_ListGroupCertificateAuthorities_773577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_773621 = ref object of OpenApiRestCall_772581
proc url_CreateGroupVersion_773623(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateGroupVersion_773622(path: JsonNode; query: JsonNode;
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
  var valid_773624 = path.getOrDefault("GroupId")
  valid_773624 = validateParameter(valid_773624, JString, required = true,
                                 default = nil)
  if valid_773624 != nil:
    section.add "GroupId", valid_773624
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
  var valid_773625 = header.getOrDefault("X-Amz-Date")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Date", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Security-Token")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Security-Token", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Content-Sha256", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Algorithm")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Algorithm", valid_773628
  var valid_773629 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amzn-Client-Token", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Signature")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Signature", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-SignedHeaders", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Credential")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Credential", valid_773632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773634: Call_CreateGroupVersion_773621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_773634.validator(path, query, header, formData, body)
  let scheme = call_773634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773634.url(scheme.get, call_773634.host, call_773634.base,
                         call_773634.route, valid.getOrDefault("path"))
  result = hook(call_773634, url, valid)

proc call*(call_773635: Call_CreateGroupVersion_773621; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_773636 = newJObject()
  var body_773637 = newJObject()
  add(path_773636, "GroupId", newJString(GroupId))
  if body != nil:
    body_773637 = body
  result = call_773635.call(path_773636, nil, nil, nil, body_773637)

var createGroupVersion* = Call_CreateGroupVersion_773621(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_773622, base: "/",
    url: url_CreateGroupVersion_773623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_773604 = ref object of OpenApiRestCall_772581
proc url_ListGroupVersions_773606(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListGroupVersions_773605(path: JsonNode; query: JsonNode;
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
  var valid_773607 = path.getOrDefault("GroupId")
  valid_773607 = validateParameter(valid_773607, JString, required = true,
                                 default = nil)
  if valid_773607 != nil:
    section.add "GroupId", valid_773607
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773608 = query.getOrDefault("NextToken")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "NextToken", valid_773608
  var valid_773609 = query.getOrDefault("MaxResults")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "MaxResults", valid_773609
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
  var valid_773610 = header.getOrDefault("X-Amz-Date")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Date", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Security-Token")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Security-Token", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Content-Sha256", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Algorithm")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Algorithm", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Signature")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Signature", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-SignedHeaders", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Credential")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Credential", valid_773616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773617: Call_ListGroupVersions_773604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_773617.validator(path, query, header, formData, body)
  let scheme = call_773617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773617.url(scheme.get, call_773617.host, call_773617.base,
                         call_773617.route, valid.getOrDefault("path"))
  result = hook(call_773617, url, valid)

proc call*(call_773618: Call_ListGroupVersions_773604; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_773619 = newJObject()
  var query_773620 = newJObject()
  add(path_773619, "GroupId", newJString(GroupId))
  add(query_773620, "NextToken", newJString(NextToken))
  add(query_773620, "MaxResults", newJString(MaxResults))
  result = call_773618.call(path_773619, query_773620, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_773604(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_773605, base: "/",
    url: url_ListGroupVersions_773606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_773653 = ref object of OpenApiRestCall_772581
proc url_CreateLoggerDefinition_773655(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLoggerDefinition_773654(path: JsonNode; query: JsonNode;
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
  var valid_773656 = header.getOrDefault("X-Amz-Date")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Date", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Security-Token")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Security-Token", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amzn-Client-Token", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Signature")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Signature", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-SignedHeaders", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Credential")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Credential", valid_773663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773665: Call_CreateLoggerDefinition_773653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_773665.validator(path, query, header, formData, body)
  let scheme = call_773665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773665.url(scheme.get, call_773665.host, call_773665.base,
                         call_773665.route, valid.getOrDefault("path"))
  result = hook(call_773665, url, valid)

proc call*(call_773666: Call_CreateLoggerDefinition_773653; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_773667 = newJObject()
  if body != nil:
    body_773667 = body
  result = call_773666.call(nil, nil, nil, nil, body_773667)

var createLoggerDefinition* = Call_CreateLoggerDefinition_773653(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_773654, base: "/",
    url: url_CreateLoggerDefinition_773655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_773638 = ref object of OpenApiRestCall_772581
proc url_ListLoggerDefinitions_773640(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLoggerDefinitions_773639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773641 = query.getOrDefault("NextToken")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "NextToken", valid_773641
  var valid_773642 = query.getOrDefault("MaxResults")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "MaxResults", valid_773642
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
  var valid_773643 = header.getOrDefault("X-Amz-Date")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Date", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Security-Token")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Security-Token", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Content-Sha256", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Algorithm")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Algorithm", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Signature")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Signature", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-SignedHeaders", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Credential")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Credential", valid_773649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773650: Call_ListLoggerDefinitions_773638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_773650.validator(path, query, header, formData, body)
  let scheme = call_773650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773650.url(scheme.get, call_773650.host, call_773650.base,
                         call_773650.route, valid.getOrDefault("path"))
  result = hook(call_773650, url, valid)

proc call*(call_773651: Call_ListLoggerDefinitions_773638; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773652 = newJObject()
  add(query_773652, "NextToken", newJString(NextToken))
  add(query_773652, "MaxResults", newJString(MaxResults))
  result = call_773651.call(nil, query_773652, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_773638(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_773639, base: "/",
    url: url_ListLoggerDefinitions_773640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_773685 = ref object of OpenApiRestCall_772581
proc url_CreateLoggerDefinitionVersion_773687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateLoggerDefinitionVersion_773686(path: JsonNode; query: JsonNode;
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
  var valid_773688 = path.getOrDefault("LoggerDefinitionId")
  valid_773688 = validateParameter(valid_773688, JString, required = true,
                                 default = nil)
  if valid_773688 != nil:
    section.add "LoggerDefinitionId", valid_773688
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
  var valid_773689 = header.getOrDefault("X-Amz-Date")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Date", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Security-Token")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Security-Token", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Content-Sha256", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Algorithm")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Algorithm", valid_773692
  var valid_773693 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amzn-Client-Token", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Signature")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Signature", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-SignedHeaders", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Credential")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Credential", valid_773696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_CreateLoggerDefinitionVersion_773685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_CreateLoggerDefinitionVersion_773685;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_773700 = newJObject()
  var body_773701 = newJObject()
  add(path_773700, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_773701 = body
  result = call_773699.call(path_773700, nil, nil, nil, body_773701)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_773685(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_773686, base: "/",
    url: url_CreateLoggerDefinitionVersion_773687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_773668 = ref object of OpenApiRestCall_772581
proc url_ListLoggerDefinitionVersions_773670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListLoggerDefinitionVersions_773669(path: JsonNode; query: JsonNode;
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
  var valid_773671 = path.getOrDefault("LoggerDefinitionId")
  valid_773671 = validateParameter(valid_773671, JString, required = true,
                                 default = nil)
  if valid_773671 != nil:
    section.add "LoggerDefinitionId", valid_773671
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773672 = query.getOrDefault("NextToken")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "NextToken", valid_773672
  var valid_773673 = query.getOrDefault("MaxResults")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "MaxResults", valid_773673
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
  var valid_773674 = header.getOrDefault("X-Amz-Date")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Date", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Security-Token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Security-Token", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Content-Sha256", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Algorithm")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Algorithm", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Signature")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Signature", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-SignedHeaders", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Credential")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Credential", valid_773680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773681: Call_ListLoggerDefinitionVersions_773668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_773681.validator(path, query, header, formData, body)
  let scheme = call_773681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773681.url(scheme.get, call_773681.host, call_773681.base,
                         call_773681.route, valid.getOrDefault("path"))
  result = hook(call_773681, url, valid)

proc call*(call_773682: Call_ListLoggerDefinitionVersions_773668;
          LoggerDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_773683 = newJObject()
  var query_773684 = newJObject()
  add(query_773684, "NextToken", newJString(NextToken))
  add(path_773683, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_773684, "MaxResults", newJString(MaxResults))
  result = call_773682.call(path_773683, query_773684, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_773668(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_773669, base: "/",
    url: url_ListLoggerDefinitionVersions_773670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_773717 = ref object of OpenApiRestCall_772581
proc url_CreateResourceDefinition_773719(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceDefinition_773718(path: JsonNode; query: JsonNode;
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
  var valid_773720 = header.getOrDefault("X-Amz-Date")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Date", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Security-Token")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Security-Token", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Content-Sha256", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Algorithm")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Algorithm", valid_773723
  var valid_773724 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amzn-Client-Token", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Signature")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Signature", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-SignedHeaders", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Credential")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Credential", valid_773727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773729: Call_CreateResourceDefinition_773717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_773729.validator(path, query, header, formData, body)
  let scheme = call_773729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773729.url(scheme.get, call_773729.host, call_773729.base,
                         call_773729.route, valid.getOrDefault("path"))
  result = hook(call_773729, url, valid)

proc call*(call_773730: Call_CreateResourceDefinition_773717; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_773731 = newJObject()
  if body != nil:
    body_773731 = body
  result = call_773730.call(nil, nil, nil, nil, body_773731)

var createResourceDefinition* = Call_CreateResourceDefinition_773717(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_773718, base: "/",
    url: url_CreateResourceDefinition_773719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_773702 = ref object of OpenApiRestCall_772581
proc url_ListResourceDefinitions_773704(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceDefinitions_773703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773705 = query.getOrDefault("NextToken")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "NextToken", valid_773705
  var valid_773706 = query.getOrDefault("MaxResults")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "MaxResults", valid_773706
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
  var valid_773707 = header.getOrDefault("X-Amz-Date")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Date", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Security-Token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Security-Token", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Content-Sha256", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Algorithm")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Algorithm", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Signature")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Signature", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-SignedHeaders", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Credential")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Credential", valid_773713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773714: Call_ListResourceDefinitions_773702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_773714.validator(path, query, header, formData, body)
  let scheme = call_773714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773714.url(scheme.get, call_773714.host, call_773714.base,
                         call_773714.route, valid.getOrDefault("path"))
  result = hook(call_773714, url, valid)

proc call*(call_773715: Call_ListResourceDefinitions_773702;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773716 = newJObject()
  add(query_773716, "NextToken", newJString(NextToken))
  add(query_773716, "MaxResults", newJString(MaxResults))
  result = call_773715.call(nil, query_773716, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_773702(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_773703, base: "/",
    url: url_ListResourceDefinitions_773704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_773749 = ref object of OpenApiRestCall_772581
proc url_CreateResourceDefinitionVersion_773751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateResourceDefinitionVersion_773750(path: JsonNode;
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
  var valid_773752 = path.getOrDefault("ResourceDefinitionId")
  valid_773752 = validateParameter(valid_773752, JString, required = true,
                                 default = nil)
  if valid_773752 != nil:
    section.add "ResourceDefinitionId", valid_773752
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
  var valid_773753 = header.getOrDefault("X-Amz-Date")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Date", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Security-Token")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Security-Token", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Content-Sha256", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Algorithm")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Algorithm", valid_773756
  var valid_773757 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amzn-Client-Token", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-Signature")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Signature", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-SignedHeaders", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Credential")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Credential", valid_773760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773762: Call_CreateResourceDefinitionVersion_773749;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_773762.validator(path, query, header, formData, body)
  let scheme = call_773762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773762.url(scheme.get, call_773762.host, call_773762.base,
                         call_773762.route, valid.getOrDefault("path"))
  result = hook(call_773762, url, valid)

proc call*(call_773763: Call_CreateResourceDefinitionVersion_773749;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_773764 = newJObject()
  var body_773765 = newJObject()
  add(path_773764, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_773765 = body
  result = call_773763.call(path_773764, nil, nil, nil, body_773765)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_773749(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_773750, base: "/",
    url: url_CreateResourceDefinitionVersion_773751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_773732 = ref object of OpenApiRestCall_772581
proc url_ListResourceDefinitionVersions_773734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListResourceDefinitionVersions_773733(path: JsonNode;
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
  var valid_773735 = path.getOrDefault("ResourceDefinitionId")
  valid_773735 = validateParameter(valid_773735, JString, required = true,
                                 default = nil)
  if valid_773735 != nil:
    section.add "ResourceDefinitionId", valid_773735
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773736 = query.getOrDefault("NextToken")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "NextToken", valid_773736
  var valid_773737 = query.getOrDefault("MaxResults")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "MaxResults", valid_773737
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
  var valid_773738 = header.getOrDefault("X-Amz-Date")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Date", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Security-Token")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Security-Token", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Content-Sha256", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-Algorithm")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-Algorithm", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-Signature")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-Signature", valid_773742
  var valid_773743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-SignedHeaders", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Credential")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Credential", valid_773744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773745: Call_ListResourceDefinitionVersions_773732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_773745.validator(path, query, header, formData, body)
  let scheme = call_773745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773745.url(scheme.get, call_773745.host, call_773745.base,
                         call_773745.route, valid.getOrDefault("path"))
  result = hook(call_773745, url, valid)

proc call*(call_773746: Call_ListResourceDefinitionVersions_773732;
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
  var path_773747 = newJObject()
  var query_773748 = newJObject()
  add(query_773748, "NextToken", newJString(NextToken))
  add(path_773747, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  add(query_773748, "MaxResults", newJString(MaxResults))
  result = call_773746.call(path_773747, query_773748, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_773732(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_773733, base: "/",
    url: url_ListResourceDefinitionVersions_773734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_773766 = ref object of OpenApiRestCall_772581
proc url_CreateSoftwareUpdateJob_773768(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSoftwareUpdateJob_773767(path: JsonNode; query: JsonNode;
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
  var valid_773769 = header.getOrDefault("X-Amz-Date")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Date", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Security-Token")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Security-Token", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Content-Sha256", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Algorithm")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Algorithm", valid_773772
  var valid_773773 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amzn-Client-Token", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Signature")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Signature", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-SignedHeaders", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Credential")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Credential", valid_773776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773778: Call_CreateSoftwareUpdateJob_773766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_773778.validator(path, query, header, formData, body)
  let scheme = call_773778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773778.url(scheme.get, call_773778.host, call_773778.base,
                         call_773778.route, valid.getOrDefault("path"))
  result = hook(call_773778, url, valid)

proc call*(call_773779: Call_CreateSoftwareUpdateJob_773766; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_773780 = newJObject()
  if body != nil:
    body_773780 = body
  result = call_773779.call(nil, nil, nil, nil, body_773780)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_773766(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_773767, base: "/",
    url: url_CreateSoftwareUpdateJob_773768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_773796 = ref object of OpenApiRestCall_772581
proc url_CreateSubscriptionDefinition_773798(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSubscriptionDefinition_773797(path: JsonNode; query: JsonNode;
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
  var valid_773799 = header.getOrDefault("X-Amz-Date")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Date", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Security-Token")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Security-Token", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Content-Sha256", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Algorithm")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Algorithm", valid_773802
  var valid_773803 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amzn-Client-Token", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Signature")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Signature", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-SignedHeaders", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Credential")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Credential", valid_773806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773808: Call_CreateSubscriptionDefinition_773796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_773808.validator(path, query, header, formData, body)
  let scheme = call_773808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773808.url(scheme.get, call_773808.host, call_773808.base,
                         call_773808.route, valid.getOrDefault("path"))
  result = hook(call_773808, url, valid)

proc call*(call_773809: Call_CreateSubscriptionDefinition_773796; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_773810 = newJObject()
  if body != nil:
    body_773810 = body
  result = call_773809.call(nil, nil, nil, nil, body_773810)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_773796(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_773797, base: "/",
    url: url_CreateSubscriptionDefinition_773798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_773781 = ref object of OpenApiRestCall_772581
proc url_ListSubscriptionDefinitions_773783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSubscriptionDefinitions_773782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773784 = query.getOrDefault("NextToken")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "NextToken", valid_773784
  var valid_773785 = query.getOrDefault("MaxResults")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "MaxResults", valid_773785
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
  var valid_773786 = header.getOrDefault("X-Amz-Date")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Date", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Security-Token")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Security-Token", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Content-Sha256", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Algorithm")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Algorithm", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Signature")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Signature", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-SignedHeaders", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Credential")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Credential", valid_773792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773793: Call_ListSubscriptionDefinitions_773781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_773793.validator(path, query, header, formData, body)
  let scheme = call_773793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773793.url(scheme.get, call_773793.host, call_773793.base,
                         call_773793.route, valid.getOrDefault("path"))
  result = hook(call_773793, url, valid)

proc call*(call_773794: Call_ListSubscriptionDefinitions_773781;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_773795 = newJObject()
  add(query_773795, "NextToken", newJString(NextToken))
  add(query_773795, "MaxResults", newJString(MaxResults))
  result = call_773794.call(nil, query_773795, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_773781(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_773782, base: "/",
    url: url_ListSubscriptionDefinitions_773783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_773828 = ref object of OpenApiRestCall_772581
proc url_CreateSubscriptionDefinitionVersion_773830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateSubscriptionDefinitionVersion_773829(path: JsonNode;
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
  var valid_773831 = path.getOrDefault("SubscriptionDefinitionId")
  valid_773831 = validateParameter(valid_773831, JString, required = true,
                                 default = nil)
  if valid_773831 != nil:
    section.add "SubscriptionDefinitionId", valid_773831
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
  var valid_773832 = header.getOrDefault("X-Amz-Date")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Date", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-Security-Token")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Security-Token", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Content-Sha256", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Algorithm")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Algorithm", valid_773835
  var valid_773836 = header.getOrDefault("X-Amzn-Client-Token")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amzn-Client-Token", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Signature")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Signature", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-SignedHeaders", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Credential")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Credential", valid_773839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773841: Call_CreateSubscriptionDefinitionVersion_773828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_773841.validator(path, query, header, formData, body)
  let scheme = call_773841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773841.url(scheme.get, call_773841.host, call_773841.base,
                         call_773841.route, valid.getOrDefault("path"))
  result = hook(call_773841, url, valid)

proc call*(call_773842: Call_CreateSubscriptionDefinitionVersion_773828;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_773843 = newJObject()
  var body_773844 = newJObject()
  add(path_773843, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_773844 = body
  result = call_773842.call(path_773843, nil, nil, nil, body_773844)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_773828(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_773829, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_773830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_773811 = ref object of OpenApiRestCall_772581
proc url_ListSubscriptionDefinitionVersions_773813(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListSubscriptionDefinitionVersions_773812(path: JsonNode;
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
  var valid_773814 = path.getOrDefault("SubscriptionDefinitionId")
  valid_773814 = validateParameter(valid_773814, JString, required = true,
                                 default = nil)
  if valid_773814 != nil:
    section.add "SubscriptionDefinitionId", valid_773814
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_773815 = query.getOrDefault("NextToken")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "NextToken", valid_773815
  var valid_773816 = query.getOrDefault("MaxResults")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "MaxResults", valid_773816
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
  var valid_773817 = header.getOrDefault("X-Amz-Date")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Date", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Security-Token")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Security-Token", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Content-Sha256", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Algorithm")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Algorithm", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Signature")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Signature", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-SignedHeaders", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Credential")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Credential", valid_773823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773824: Call_ListSubscriptionDefinitionVersions_773811;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_773824.validator(path, query, header, formData, body)
  let scheme = call_773824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773824.url(scheme.get, call_773824.host, call_773824.base,
                         call_773824.route, valid.getOrDefault("path"))
  result = hook(call_773824, url, valid)

proc call*(call_773825: Call_ListSubscriptionDefinitionVersions_773811;
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
  var path_773826 = newJObject()
  var query_773827 = newJObject()
  add(query_773827, "NextToken", newJString(NextToken))
  add(path_773826, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(query_773827, "MaxResults", newJString(MaxResults))
  result = call_773825.call(path_773826, query_773827, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_773811(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_773812, base: "/",
    url: url_ListSubscriptionDefinitionVersions_773813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_773859 = ref object of OpenApiRestCall_772581
proc url_UpdateConnectorDefinition_773861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateConnectorDefinition_773860(path: JsonNode; query: JsonNode;
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
  var valid_773862 = path.getOrDefault("ConnectorDefinitionId")
  valid_773862 = validateParameter(valid_773862, JString, required = true,
                                 default = nil)
  if valid_773862 != nil:
    section.add "ConnectorDefinitionId", valid_773862
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
  var valid_773863 = header.getOrDefault("X-Amz-Date")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Date", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Security-Token")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Security-Token", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Content-Sha256", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-Algorithm")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Algorithm", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-Signature")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Signature", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-SignedHeaders", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Credential")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Credential", valid_773869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773871: Call_UpdateConnectorDefinition_773859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_773871.validator(path, query, header, formData, body)
  let scheme = call_773871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773871.url(scheme.get, call_773871.host, call_773871.base,
                         call_773871.route, valid.getOrDefault("path"))
  result = hook(call_773871, url, valid)

proc call*(call_773872: Call_UpdateConnectorDefinition_773859;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_773873 = newJObject()
  var body_773874 = newJObject()
  add(path_773873, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_773874 = body
  result = call_773872.call(path_773873, nil, nil, nil, body_773874)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_773859(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_773860, base: "/",
    url: url_UpdateConnectorDefinition_773861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_773845 = ref object of OpenApiRestCall_772581
proc url_GetConnectorDefinition_773847(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConnectorDefinition_773846(path: JsonNode; query: JsonNode;
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
  var valid_773848 = path.getOrDefault("ConnectorDefinitionId")
  valid_773848 = validateParameter(valid_773848, JString, required = true,
                                 default = nil)
  if valid_773848 != nil:
    section.add "ConnectorDefinitionId", valid_773848
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
  var valid_773849 = header.getOrDefault("X-Amz-Date")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Date", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Security-Token")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Security-Token", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Content-Sha256", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Algorithm")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Algorithm", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Signature")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Signature", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-SignedHeaders", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Credential")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Credential", valid_773855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773856: Call_GetConnectorDefinition_773845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_773856.validator(path, query, header, formData, body)
  let scheme = call_773856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773856.url(scheme.get, call_773856.host, call_773856.base,
                         call_773856.route, valid.getOrDefault("path"))
  result = hook(call_773856, url, valid)

proc call*(call_773857: Call_GetConnectorDefinition_773845;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_773858 = newJObject()
  add(path_773858, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_773857.call(path_773858, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_773845(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_773846, base: "/",
    url: url_GetConnectorDefinition_773847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_773875 = ref object of OpenApiRestCall_772581
proc url_DeleteConnectorDefinition_773877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ConnectorDefinitionId" in path,
        "`ConnectorDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/connectors/"),
               (kind: VariableSegment, value: "ConnectorDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteConnectorDefinition_773876(path: JsonNode; query: JsonNode;
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
  var valid_773878 = path.getOrDefault("ConnectorDefinitionId")
  valid_773878 = validateParameter(valid_773878, JString, required = true,
                                 default = nil)
  if valid_773878 != nil:
    section.add "ConnectorDefinitionId", valid_773878
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
  var valid_773879 = header.getOrDefault("X-Amz-Date")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Date", valid_773879
  var valid_773880 = header.getOrDefault("X-Amz-Security-Token")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Security-Token", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Content-Sha256", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Algorithm")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Algorithm", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Signature")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Signature", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-SignedHeaders", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Credential")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Credential", valid_773885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773886: Call_DeleteConnectorDefinition_773875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_773886.validator(path, query, header, formData, body)
  let scheme = call_773886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773886.url(scheme.get, call_773886.host, call_773886.base,
                         call_773886.route, valid.getOrDefault("path"))
  result = hook(call_773886, url, valid)

proc call*(call_773887: Call_DeleteConnectorDefinition_773875;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_773888 = newJObject()
  add(path_773888, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_773887.call(path_773888, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_773875(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_773876, base: "/",
    url: url_DeleteConnectorDefinition_773877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_773903 = ref object of OpenApiRestCall_772581
proc url_UpdateCoreDefinition_773905(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateCoreDefinition_773904(path: JsonNode; query: JsonNode;
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
  var valid_773906 = path.getOrDefault("CoreDefinitionId")
  valid_773906 = validateParameter(valid_773906, JString, required = true,
                                 default = nil)
  if valid_773906 != nil:
    section.add "CoreDefinitionId", valid_773906
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
  var valid_773907 = header.getOrDefault("X-Amz-Date")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Date", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Security-Token")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Security-Token", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Content-Sha256", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-Algorithm")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Algorithm", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Signature")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Signature", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-SignedHeaders", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Credential")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Credential", valid_773913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773915: Call_UpdateCoreDefinition_773903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_773915.validator(path, query, header, formData, body)
  let scheme = call_773915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773915.url(scheme.get, call_773915.host, call_773915.base,
                         call_773915.route, valid.getOrDefault("path"))
  result = hook(call_773915, url, valid)

proc call*(call_773916: Call_UpdateCoreDefinition_773903; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_773917 = newJObject()
  var body_773918 = newJObject()
  add(path_773917, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_773918 = body
  result = call_773916.call(path_773917, nil, nil, nil, body_773918)

var updateCoreDefinition* = Call_UpdateCoreDefinition_773903(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_773904, base: "/",
    url: url_UpdateCoreDefinition_773905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_773889 = ref object of OpenApiRestCall_772581
proc url_GetCoreDefinition_773891(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCoreDefinition_773890(path: JsonNode; query: JsonNode;
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
  var valid_773892 = path.getOrDefault("CoreDefinitionId")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = nil)
  if valid_773892 != nil:
    section.add "CoreDefinitionId", valid_773892
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
  var valid_773893 = header.getOrDefault("X-Amz-Date")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Date", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-Security-Token")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Security-Token", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Content-Sha256", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Algorithm")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Algorithm", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Signature")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Signature", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-SignedHeaders", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Credential")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Credential", valid_773899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773900: Call_GetCoreDefinition_773889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_773900.validator(path, query, header, formData, body)
  let scheme = call_773900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773900.url(scheme.get, call_773900.host, call_773900.base,
                         call_773900.route, valid.getOrDefault("path"))
  result = hook(call_773900, url, valid)

proc call*(call_773901: Call_GetCoreDefinition_773889; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_773902 = newJObject()
  add(path_773902, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_773901.call(path_773902, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_773889(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_773890, base: "/",
    url: url_GetCoreDefinition_773891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_773919 = ref object of OpenApiRestCall_772581
proc url_DeleteCoreDefinition_773921(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "CoreDefinitionId" in path,
        "`CoreDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/cores/"),
               (kind: VariableSegment, value: "CoreDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteCoreDefinition_773920(path: JsonNode; query: JsonNode;
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
  var valid_773922 = path.getOrDefault("CoreDefinitionId")
  valid_773922 = validateParameter(valid_773922, JString, required = true,
                                 default = nil)
  if valid_773922 != nil:
    section.add "CoreDefinitionId", valid_773922
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
  var valid_773923 = header.getOrDefault("X-Amz-Date")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Date", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Security-Token")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Security-Token", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Content-Sha256", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Algorithm")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Algorithm", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-Signature")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Signature", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-SignedHeaders", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Credential")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Credential", valid_773929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773930: Call_DeleteCoreDefinition_773919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_773930.validator(path, query, header, formData, body)
  let scheme = call_773930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773930.url(scheme.get, call_773930.host, call_773930.base,
                         call_773930.route, valid.getOrDefault("path"))
  result = hook(call_773930, url, valid)

proc call*(call_773931: Call_DeleteCoreDefinition_773919; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_773932 = newJObject()
  add(path_773932, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_773931.call(path_773932, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_773919(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_773920, base: "/",
    url: url_DeleteCoreDefinition_773921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_773947 = ref object of OpenApiRestCall_772581
proc url_UpdateDeviceDefinition_773949(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDeviceDefinition_773948(path: JsonNode; query: JsonNode;
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
  var valid_773950 = path.getOrDefault("DeviceDefinitionId")
  valid_773950 = validateParameter(valid_773950, JString, required = true,
                                 default = nil)
  if valid_773950 != nil:
    section.add "DeviceDefinitionId", valid_773950
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
  var valid_773951 = header.getOrDefault("X-Amz-Date")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Date", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Security-Token")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Security-Token", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Content-Sha256", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Algorithm")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Algorithm", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-Signature")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Signature", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-SignedHeaders", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Credential")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Credential", valid_773957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773959: Call_UpdateDeviceDefinition_773947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_773959.validator(path, query, header, formData, body)
  let scheme = call_773959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773959.url(scheme.get, call_773959.host, call_773959.base,
                         call_773959.route, valid.getOrDefault("path"))
  result = hook(call_773959, url, valid)

proc call*(call_773960: Call_UpdateDeviceDefinition_773947;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_773961 = newJObject()
  var body_773962 = newJObject()
  add(path_773961, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_773962 = body
  result = call_773960.call(path_773961, nil, nil, nil, body_773962)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_773947(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_773948, base: "/",
    url: url_UpdateDeviceDefinition_773949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_773933 = ref object of OpenApiRestCall_772581
proc url_GetDeviceDefinition_773935(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeviceDefinition_773934(path: JsonNode; query: JsonNode;
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
  var valid_773936 = path.getOrDefault("DeviceDefinitionId")
  valid_773936 = validateParameter(valid_773936, JString, required = true,
                                 default = nil)
  if valid_773936 != nil:
    section.add "DeviceDefinitionId", valid_773936
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
  var valid_773937 = header.getOrDefault("X-Amz-Date")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Date", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Security-Token")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Security-Token", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Content-Sha256", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Algorithm")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Algorithm", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Signature")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Signature", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-SignedHeaders", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Credential")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Credential", valid_773943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773944: Call_GetDeviceDefinition_773933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_773944.validator(path, query, header, formData, body)
  let scheme = call_773944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773944.url(scheme.get, call_773944.host, call_773944.base,
                         call_773944.route, valid.getOrDefault("path"))
  result = hook(call_773944, url, valid)

proc call*(call_773945: Call_GetDeviceDefinition_773933; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_773946 = newJObject()
  add(path_773946, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_773945.call(path_773946, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_773933(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_773934, base: "/",
    url: url_GetDeviceDefinition_773935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_773963 = ref object of OpenApiRestCall_772581
proc url_DeleteDeviceDefinition_773965(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DeviceDefinitionId" in path,
        "`DeviceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/devices/"),
               (kind: VariableSegment, value: "DeviceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDeviceDefinition_773964(path: JsonNode; query: JsonNode;
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
  var valid_773966 = path.getOrDefault("DeviceDefinitionId")
  valid_773966 = validateParameter(valid_773966, JString, required = true,
                                 default = nil)
  if valid_773966 != nil:
    section.add "DeviceDefinitionId", valid_773966
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
  var valid_773967 = header.getOrDefault("X-Amz-Date")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Date", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Security-Token")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Security-Token", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Content-Sha256", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-Algorithm")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-Algorithm", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Signature")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Signature", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-SignedHeaders", valid_773972
  var valid_773973 = header.getOrDefault("X-Amz-Credential")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "X-Amz-Credential", valid_773973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773974: Call_DeleteDeviceDefinition_773963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_773974.validator(path, query, header, formData, body)
  let scheme = call_773974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773974.url(scheme.get, call_773974.host, call_773974.base,
                         call_773974.route, valid.getOrDefault("path"))
  result = hook(call_773974, url, valid)

proc call*(call_773975: Call_DeleteDeviceDefinition_773963;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_773976 = newJObject()
  add(path_773976, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_773975.call(path_773976, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_773963(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_773964, base: "/",
    url: url_DeleteDeviceDefinition_773965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_773991 = ref object of OpenApiRestCall_772581
proc url_UpdateFunctionDefinition_773993(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFunctionDefinition_773992(path: JsonNode; query: JsonNode;
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
  var valid_773994 = path.getOrDefault("FunctionDefinitionId")
  valid_773994 = validateParameter(valid_773994, JString, required = true,
                                 default = nil)
  if valid_773994 != nil:
    section.add "FunctionDefinitionId", valid_773994
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
  var valid_773995 = header.getOrDefault("X-Amz-Date")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Date", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Security-Token")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Security-Token", valid_773996
  var valid_773997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-Content-Sha256", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Algorithm")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Algorithm", valid_773998
  var valid_773999 = header.getOrDefault("X-Amz-Signature")
  valid_773999 = validateParameter(valid_773999, JString, required = false,
                                 default = nil)
  if valid_773999 != nil:
    section.add "X-Amz-Signature", valid_773999
  var valid_774000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-SignedHeaders", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Credential")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Credential", valid_774001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774003: Call_UpdateFunctionDefinition_773991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_774003.validator(path, query, header, formData, body)
  let scheme = call_774003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774003.url(scheme.get, call_774003.host, call_774003.base,
                         call_774003.route, valid.getOrDefault("path"))
  result = hook(call_774003, url, valid)

proc call*(call_774004: Call_UpdateFunctionDefinition_773991;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_774005 = newJObject()
  var body_774006 = newJObject()
  add(path_774005, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_774006 = body
  result = call_774004.call(path_774005, nil, nil, nil, body_774006)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_773991(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_773992, base: "/",
    url: url_UpdateFunctionDefinition_773993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_773977 = ref object of OpenApiRestCall_772581
proc url_GetFunctionDefinition_773979(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFunctionDefinition_773978(path: JsonNode; query: JsonNode;
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
  var valid_773980 = path.getOrDefault("FunctionDefinitionId")
  valid_773980 = validateParameter(valid_773980, JString, required = true,
                                 default = nil)
  if valid_773980 != nil:
    section.add "FunctionDefinitionId", valid_773980
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
  var valid_773981 = header.getOrDefault("X-Amz-Date")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Date", valid_773981
  var valid_773982 = header.getOrDefault("X-Amz-Security-Token")
  valid_773982 = validateParameter(valid_773982, JString, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "X-Amz-Security-Token", valid_773982
  var valid_773983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "X-Amz-Content-Sha256", valid_773983
  var valid_773984 = header.getOrDefault("X-Amz-Algorithm")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "X-Amz-Algorithm", valid_773984
  var valid_773985 = header.getOrDefault("X-Amz-Signature")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Signature", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-SignedHeaders", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Credential")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Credential", valid_773987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773988: Call_GetFunctionDefinition_773977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_773988.validator(path, query, header, formData, body)
  let scheme = call_773988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773988.url(scheme.get, call_773988.host, call_773988.base,
                         call_773988.route, valid.getOrDefault("path"))
  result = hook(call_773988, url, valid)

proc call*(call_773989: Call_GetFunctionDefinition_773977;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_773990 = newJObject()
  add(path_773990, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_773989.call(path_773990, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_773977(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_773978, base: "/",
    url: url_GetFunctionDefinition_773979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_774007 = ref object of OpenApiRestCall_772581
proc url_DeleteFunctionDefinition_774009(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FunctionDefinitionId" in path,
        "`FunctionDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/functions/"),
               (kind: VariableSegment, value: "FunctionDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFunctionDefinition_774008(path: JsonNode; query: JsonNode;
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
  var valid_774010 = path.getOrDefault("FunctionDefinitionId")
  valid_774010 = validateParameter(valid_774010, JString, required = true,
                                 default = nil)
  if valid_774010 != nil:
    section.add "FunctionDefinitionId", valid_774010
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
  var valid_774011 = header.getOrDefault("X-Amz-Date")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Date", valid_774011
  var valid_774012 = header.getOrDefault("X-Amz-Security-Token")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-Security-Token", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-Content-Sha256", valid_774013
  var valid_774014 = header.getOrDefault("X-Amz-Algorithm")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "X-Amz-Algorithm", valid_774014
  var valid_774015 = header.getOrDefault("X-Amz-Signature")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Signature", valid_774015
  var valid_774016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774016 = validateParameter(valid_774016, JString, required = false,
                                 default = nil)
  if valid_774016 != nil:
    section.add "X-Amz-SignedHeaders", valid_774016
  var valid_774017 = header.getOrDefault("X-Amz-Credential")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "X-Amz-Credential", valid_774017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774018: Call_DeleteFunctionDefinition_774007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_774018.validator(path, query, header, formData, body)
  let scheme = call_774018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774018.url(scheme.get, call_774018.host, call_774018.base,
                         call_774018.route, valid.getOrDefault("path"))
  result = hook(call_774018, url, valid)

proc call*(call_774019: Call_DeleteFunctionDefinition_774007;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_774020 = newJObject()
  add(path_774020, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_774019.call(path_774020, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_774007(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_774008, base: "/",
    url: url_DeleteFunctionDefinition_774009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_774035 = ref object of OpenApiRestCall_772581
proc url_UpdateGroup_774037(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGroup_774036(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774038 = path.getOrDefault("GroupId")
  valid_774038 = validateParameter(valid_774038, JString, required = true,
                                 default = nil)
  if valid_774038 != nil:
    section.add "GroupId", valid_774038
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
  var valid_774039 = header.getOrDefault("X-Amz-Date")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-Date", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Security-Token")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Security-Token", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Content-Sha256", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Algorithm")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Algorithm", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Signature")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Signature", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-SignedHeaders", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Credential")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Credential", valid_774045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774047: Call_UpdateGroup_774035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_774047.validator(path, query, header, formData, body)
  let scheme = call_774047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774047.url(scheme.get, call_774047.host, call_774047.base,
                         call_774047.route, valid.getOrDefault("path"))
  result = hook(call_774047, url, valid)

proc call*(call_774048: Call_UpdateGroup_774035; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_774049 = newJObject()
  var body_774050 = newJObject()
  add(path_774049, "GroupId", newJString(GroupId))
  if body != nil:
    body_774050 = body
  result = call_774048.call(path_774049, nil, nil, nil, body_774050)

var updateGroup* = Call_UpdateGroup_774035(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_774036,
                                        base: "/", url: url_UpdateGroup_774037,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_774021 = ref object of OpenApiRestCall_772581
proc url_GetGroup_774023(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroup_774022(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774024 = path.getOrDefault("GroupId")
  valid_774024 = validateParameter(valid_774024, JString, required = true,
                                 default = nil)
  if valid_774024 != nil:
    section.add "GroupId", valid_774024
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
  var valid_774025 = header.getOrDefault("X-Amz-Date")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Date", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Security-Token")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Security-Token", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Content-Sha256", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Algorithm")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Algorithm", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Signature")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Signature", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-SignedHeaders", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Credential")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Credential", valid_774031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774032: Call_GetGroup_774021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_774032.validator(path, query, header, formData, body)
  let scheme = call_774032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774032.url(scheme.get, call_774032.host, call_774032.base,
                         call_774032.route, valid.getOrDefault("path"))
  result = hook(call_774032, url, valid)

proc call*(call_774033: Call_GetGroup_774021; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_774034 = newJObject()
  add(path_774034, "GroupId", newJString(GroupId))
  result = call_774033.call(path_774034, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_774021(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_774022, base: "/",
                                  url: url_GetGroup_774023,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_774051 = ref object of OpenApiRestCall_772581
proc url_DeleteGroup_774053(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteGroup_774052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774054 = path.getOrDefault("GroupId")
  valid_774054 = validateParameter(valid_774054, JString, required = true,
                                 default = nil)
  if valid_774054 != nil:
    section.add "GroupId", valid_774054
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
  var valid_774055 = header.getOrDefault("X-Amz-Date")
  valid_774055 = validateParameter(valid_774055, JString, required = false,
                                 default = nil)
  if valid_774055 != nil:
    section.add "X-Amz-Date", valid_774055
  var valid_774056 = header.getOrDefault("X-Amz-Security-Token")
  valid_774056 = validateParameter(valid_774056, JString, required = false,
                                 default = nil)
  if valid_774056 != nil:
    section.add "X-Amz-Security-Token", valid_774056
  var valid_774057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774057 = validateParameter(valid_774057, JString, required = false,
                                 default = nil)
  if valid_774057 != nil:
    section.add "X-Amz-Content-Sha256", valid_774057
  var valid_774058 = header.getOrDefault("X-Amz-Algorithm")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = nil)
  if valid_774058 != nil:
    section.add "X-Amz-Algorithm", valid_774058
  var valid_774059 = header.getOrDefault("X-Amz-Signature")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "X-Amz-Signature", valid_774059
  var valid_774060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774060 = validateParameter(valid_774060, JString, required = false,
                                 default = nil)
  if valid_774060 != nil:
    section.add "X-Amz-SignedHeaders", valid_774060
  var valid_774061 = header.getOrDefault("X-Amz-Credential")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Credential", valid_774061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774062: Call_DeleteGroup_774051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_774062.validator(path, query, header, formData, body)
  let scheme = call_774062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774062.url(scheme.get, call_774062.host, call_774062.base,
                         call_774062.route, valid.getOrDefault("path"))
  result = hook(call_774062, url, valid)

proc call*(call_774063: Call_DeleteGroup_774051; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_774064 = newJObject()
  add(path_774064, "GroupId", newJString(GroupId))
  result = call_774063.call(path_774064, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_774051(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_774052,
                                        base: "/", url: url_DeleteGroup_774053,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_774079 = ref object of OpenApiRestCall_772581
proc url_UpdateLoggerDefinition_774081(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateLoggerDefinition_774080(path: JsonNode; query: JsonNode;
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
  var valid_774082 = path.getOrDefault("LoggerDefinitionId")
  valid_774082 = validateParameter(valid_774082, JString, required = true,
                                 default = nil)
  if valid_774082 != nil:
    section.add "LoggerDefinitionId", valid_774082
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
  var valid_774083 = header.getOrDefault("X-Amz-Date")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Date", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Security-Token")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Security-Token", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Content-Sha256", valid_774085
  var valid_774086 = header.getOrDefault("X-Amz-Algorithm")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "X-Amz-Algorithm", valid_774086
  var valid_774087 = header.getOrDefault("X-Amz-Signature")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "X-Amz-Signature", valid_774087
  var valid_774088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774088 = validateParameter(valid_774088, JString, required = false,
                                 default = nil)
  if valid_774088 != nil:
    section.add "X-Amz-SignedHeaders", valid_774088
  var valid_774089 = header.getOrDefault("X-Amz-Credential")
  valid_774089 = validateParameter(valid_774089, JString, required = false,
                                 default = nil)
  if valid_774089 != nil:
    section.add "X-Amz-Credential", valid_774089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774091: Call_UpdateLoggerDefinition_774079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_774091.validator(path, query, header, formData, body)
  let scheme = call_774091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774091.url(scheme.get, call_774091.host, call_774091.base,
                         call_774091.route, valid.getOrDefault("path"))
  result = hook(call_774091, url, valid)

proc call*(call_774092: Call_UpdateLoggerDefinition_774079;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_774093 = newJObject()
  var body_774094 = newJObject()
  add(path_774093, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_774094 = body
  result = call_774092.call(path_774093, nil, nil, nil, body_774094)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_774079(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_774080, base: "/",
    url: url_UpdateLoggerDefinition_774081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_774065 = ref object of OpenApiRestCall_772581
proc url_GetLoggerDefinition_774067(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetLoggerDefinition_774066(path: JsonNode; query: JsonNode;
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
  var valid_774068 = path.getOrDefault("LoggerDefinitionId")
  valid_774068 = validateParameter(valid_774068, JString, required = true,
                                 default = nil)
  if valid_774068 != nil:
    section.add "LoggerDefinitionId", valid_774068
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
  var valid_774069 = header.getOrDefault("X-Amz-Date")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Date", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Security-Token")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Security-Token", valid_774070
  var valid_774071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774071 = validateParameter(valid_774071, JString, required = false,
                                 default = nil)
  if valid_774071 != nil:
    section.add "X-Amz-Content-Sha256", valid_774071
  var valid_774072 = header.getOrDefault("X-Amz-Algorithm")
  valid_774072 = validateParameter(valid_774072, JString, required = false,
                                 default = nil)
  if valid_774072 != nil:
    section.add "X-Amz-Algorithm", valid_774072
  var valid_774073 = header.getOrDefault("X-Amz-Signature")
  valid_774073 = validateParameter(valid_774073, JString, required = false,
                                 default = nil)
  if valid_774073 != nil:
    section.add "X-Amz-Signature", valid_774073
  var valid_774074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774074 = validateParameter(valid_774074, JString, required = false,
                                 default = nil)
  if valid_774074 != nil:
    section.add "X-Amz-SignedHeaders", valid_774074
  var valid_774075 = header.getOrDefault("X-Amz-Credential")
  valid_774075 = validateParameter(valid_774075, JString, required = false,
                                 default = nil)
  if valid_774075 != nil:
    section.add "X-Amz-Credential", valid_774075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774076: Call_GetLoggerDefinition_774065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_774076.validator(path, query, header, formData, body)
  let scheme = call_774076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774076.url(scheme.get, call_774076.host, call_774076.base,
                         call_774076.route, valid.getOrDefault("path"))
  result = hook(call_774076, url, valid)

proc call*(call_774077: Call_GetLoggerDefinition_774065; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_774078 = newJObject()
  add(path_774078, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_774077.call(path_774078, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_774065(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_774066, base: "/",
    url: url_GetLoggerDefinition_774067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_774095 = ref object of OpenApiRestCall_772581
proc url_DeleteLoggerDefinition_774097(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "LoggerDefinitionId" in path,
        "`LoggerDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/loggers/"),
               (kind: VariableSegment, value: "LoggerDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteLoggerDefinition_774096(path: JsonNode; query: JsonNode;
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
  var valid_774098 = path.getOrDefault("LoggerDefinitionId")
  valid_774098 = validateParameter(valid_774098, JString, required = true,
                                 default = nil)
  if valid_774098 != nil:
    section.add "LoggerDefinitionId", valid_774098
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
  var valid_774099 = header.getOrDefault("X-Amz-Date")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Date", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Security-Token")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Security-Token", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Content-Sha256", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Algorithm")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Algorithm", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Signature")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Signature", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-SignedHeaders", valid_774104
  var valid_774105 = header.getOrDefault("X-Amz-Credential")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Credential", valid_774105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774106: Call_DeleteLoggerDefinition_774095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_774106.validator(path, query, header, formData, body)
  let scheme = call_774106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774106.url(scheme.get, call_774106.host, call_774106.base,
                         call_774106.route, valid.getOrDefault("path"))
  result = hook(call_774106, url, valid)

proc call*(call_774107: Call_DeleteLoggerDefinition_774095;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_774108 = newJObject()
  add(path_774108, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_774107.call(path_774108, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_774095(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_774096, base: "/",
    url: url_DeleteLoggerDefinition_774097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_774123 = ref object of OpenApiRestCall_772581
proc url_UpdateResourceDefinition_774125(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateResourceDefinition_774124(path: JsonNode; query: JsonNode;
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
  var valid_774126 = path.getOrDefault("ResourceDefinitionId")
  valid_774126 = validateParameter(valid_774126, JString, required = true,
                                 default = nil)
  if valid_774126 != nil:
    section.add "ResourceDefinitionId", valid_774126
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
  var valid_774127 = header.getOrDefault("X-Amz-Date")
  valid_774127 = validateParameter(valid_774127, JString, required = false,
                                 default = nil)
  if valid_774127 != nil:
    section.add "X-Amz-Date", valid_774127
  var valid_774128 = header.getOrDefault("X-Amz-Security-Token")
  valid_774128 = validateParameter(valid_774128, JString, required = false,
                                 default = nil)
  if valid_774128 != nil:
    section.add "X-Amz-Security-Token", valid_774128
  var valid_774129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774129 = validateParameter(valid_774129, JString, required = false,
                                 default = nil)
  if valid_774129 != nil:
    section.add "X-Amz-Content-Sha256", valid_774129
  var valid_774130 = header.getOrDefault("X-Amz-Algorithm")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "X-Amz-Algorithm", valid_774130
  var valid_774131 = header.getOrDefault("X-Amz-Signature")
  valid_774131 = validateParameter(valid_774131, JString, required = false,
                                 default = nil)
  if valid_774131 != nil:
    section.add "X-Amz-Signature", valid_774131
  var valid_774132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "X-Amz-SignedHeaders", valid_774132
  var valid_774133 = header.getOrDefault("X-Amz-Credential")
  valid_774133 = validateParameter(valid_774133, JString, required = false,
                                 default = nil)
  if valid_774133 != nil:
    section.add "X-Amz-Credential", valid_774133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774135: Call_UpdateResourceDefinition_774123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_774135.validator(path, query, header, formData, body)
  let scheme = call_774135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774135.url(scheme.get, call_774135.host, call_774135.base,
                         call_774135.route, valid.getOrDefault("path"))
  result = hook(call_774135, url, valid)

proc call*(call_774136: Call_UpdateResourceDefinition_774123;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_774137 = newJObject()
  var body_774138 = newJObject()
  add(path_774137, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_774138 = body
  result = call_774136.call(path_774137, nil, nil, nil, body_774138)

var updateResourceDefinition* = Call_UpdateResourceDefinition_774123(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_774124, base: "/",
    url: url_UpdateResourceDefinition_774125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_774109 = ref object of OpenApiRestCall_772581
proc url_GetResourceDefinition_774111(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetResourceDefinition_774110(path: JsonNode; query: JsonNode;
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
  var valid_774112 = path.getOrDefault("ResourceDefinitionId")
  valid_774112 = validateParameter(valid_774112, JString, required = true,
                                 default = nil)
  if valid_774112 != nil:
    section.add "ResourceDefinitionId", valid_774112
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
  var valid_774113 = header.getOrDefault("X-Amz-Date")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Date", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Security-Token")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Security-Token", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Content-Sha256", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Algorithm")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Algorithm", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Signature")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Signature", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-SignedHeaders", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Credential")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Credential", valid_774119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774120: Call_GetResourceDefinition_774109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_774120.validator(path, query, header, formData, body)
  let scheme = call_774120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774120.url(scheme.get, call_774120.host, call_774120.base,
                         call_774120.route, valid.getOrDefault("path"))
  result = hook(call_774120, url, valid)

proc call*(call_774121: Call_GetResourceDefinition_774109;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_774122 = newJObject()
  add(path_774122, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_774121.call(path_774122, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_774109(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_774110, base: "/",
    url: url_GetResourceDefinition_774111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_774139 = ref object of OpenApiRestCall_772581
proc url_DeleteResourceDefinition_774141(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceDefinitionId" in path,
        "`ResourceDefinitionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/definition/resources/"),
               (kind: VariableSegment, value: "ResourceDefinitionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteResourceDefinition_774140(path: JsonNode; query: JsonNode;
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
  var valid_774142 = path.getOrDefault("ResourceDefinitionId")
  valid_774142 = validateParameter(valid_774142, JString, required = true,
                                 default = nil)
  if valid_774142 != nil:
    section.add "ResourceDefinitionId", valid_774142
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
  var valid_774143 = header.getOrDefault("X-Amz-Date")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "X-Amz-Date", valid_774143
  var valid_774144 = header.getOrDefault("X-Amz-Security-Token")
  valid_774144 = validateParameter(valid_774144, JString, required = false,
                                 default = nil)
  if valid_774144 != nil:
    section.add "X-Amz-Security-Token", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-Content-Sha256", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Algorithm")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Algorithm", valid_774146
  var valid_774147 = header.getOrDefault("X-Amz-Signature")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Signature", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-SignedHeaders", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-Credential")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Credential", valid_774149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774150: Call_DeleteResourceDefinition_774139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_774150.validator(path, query, header, formData, body)
  let scheme = call_774150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774150.url(scheme.get, call_774150.host, call_774150.base,
                         call_774150.route, valid.getOrDefault("path"))
  result = hook(call_774150, url, valid)

proc call*(call_774151: Call_DeleteResourceDefinition_774139;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_774152 = newJObject()
  add(path_774152, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_774151.call(path_774152, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_774139(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_774140, base: "/",
    url: url_DeleteResourceDefinition_774141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_774167 = ref object of OpenApiRestCall_772581
proc url_UpdateSubscriptionDefinition_774169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateSubscriptionDefinition_774168(path: JsonNode; query: JsonNode;
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
  var valid_774170 = path.getOrDefault("SubscriptionDefinitionId")
  valid_774170 = validateParameter(valid_774170, JString, required = true,
                                 default = nil)
  if valid_774170 != nil:
    section.add "SubscriptionDefinitionId", valid_774170
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
  var valid_774171 = header.getOrDefault("X-Amz-Date")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-Date", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Security-Token")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Security-Token", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-Content-Sha256", valid_774173
  var valid_774174 = header.getOrDefault("X-Amz-Algorithm")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "X-Amz-Algorithm", valid_774174
  var valid_774175 = header.getOrDefault("X-Amz-Signature")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-Signature", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-SignedHeaders", valid_774176
  var valid_774177 = header.getOrDefault("X-Amz-Credential")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "X-Amz-Credential", valid_774177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774179: Call_UpdateSubscriptionDefinition_774167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_774179.validator(path, query, header, formData, body)
  let scheme = call_774179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774179.url(scheme.get, call_774179.host, call_774179.base,
                         call_774179.route, valid.getOrDefault("path"))
  result = hook(call_774179, url, valid)

proc call*(call_774180: Call_UpdateSubscriptionDefinition_774167;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_774181 = newJObject()
  var body_774182 = newJObject()
  add(path_774181, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_774182 = body
  result = call_774180.call(path_774181, nil, nil, nil, body_774182)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_774167(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_774168, base: "/",
    url: url_UpdateSubscriptionDefinition_774169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_774153 = ref object of OpenApiRestCall_772581
proc url_GetSubscriptionDefinition_774155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSubscriptionDefinition_774154(path: JsonNode; query: JsonNode;
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
  var valid_774156 = path.getOrDefault("SubscriptionDefinitionId")
  valid_774156 = validateParameter(valid_774156, JString, required = true,
                                 default = nil)
  if valid_774156 != nil:
    section.add "SubscriptionDefinitionId", valid_774156
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
  var valid_774157 = header.getOrDefault("X-Amz-Date")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Date", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-Security-Token")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-Security-Token", valid_774158
  var valid_774159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Content-Sha256", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-Algorithm")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-Algorithm", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Signature")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Signature", valid_774161
  var valid_774162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "X-Amz-SignedHeaders", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-Credential")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Credential", valid_774163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774164: Call_GetSubscriptionDefinition_774153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_774164.validator(path, query, header, formData, body)
  let scheme = call_774164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774164.url(scheme.get, call_774164.host, call_774164.base,
                         call_774164.route, valid.getOrDefault("path"))
  result = hook(call_774164, url, valid)

proc call*(call_774165: Call_GetSubscriptionDefinition_774153;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_774166 = newJObject()
  add(path_774166, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_774165.call(path_774166, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_774153(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_774154, base: "/",
    url: url_GetSubscriptionDefinition_774155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_774183 = ref object of OpenApiRestCall_772581
proc url_DeleteSubscriptionDefinition_774185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteSubscriptionDefinition_774184(path: JsonNode; query: JsonNode;
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
  var valid_774186 = path.getOrDefault("SubscriptionDefinitionId")
  valid_774186 = validateParameter(valid_774186, JString, required = true,
                                 default = nil)
  if valid_774186 != nil:
    section.add "SubscriptionDefinitionId", valid_774186
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
  var valid_774187 = header.getOrDefault("X-Amz-Date")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Date", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Security-Token")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Security-Token", valid_774188
  var valid_774189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "X-Amz-Content-Sha256", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Algorithm")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Algorithm", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-Signature")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Signature", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-SignedHeaders", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-Credential")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Credential", valid_774193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774194: Call_DeleteSubscriptionDefinition_774183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_774194.validator(path, query, header, formData, body)
  let scheme = call_774194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774194.url(scheme.get, call_774194.host, call_774194.base,
                         call_774194.route, valid.getOrDefault("path"))
  result = hook(call_774194, url, valid)

proc call*(call_774195: Call_DeleteSubscriptionDefinition_774183;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_774196 = newJObject()
  add(path_774196, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_774195.call(path_774196, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_774183(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_774184, base: "/",
    url: url_DeleteSubscriptionDefinition_774185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_774197 = ref object of OpenApiRestCall_772581
proc url_GetBulkDeploymentStatus_774199(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBulkDeploymentStatus_774198(path: JsonNode; query: JsonNode;
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
  var valid_774200 = path.getOrDefault("BulkDeploymentId")
  valid_774200 = validateParameter(valid_774200, JString, required = true,
                                 default = nil)
  if valid_774200 != nil:
    section.add "BulkDeploymentId", valid_774200
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
  var valid_774201 = header.getOrDefault("X-Amz-Date")
  valid_774201 = validateParameter(valid_774201, JString, required = false,
                                 default = nil)
  if valid_774201 != nil:
    section.add "X-Amz-Date", valid_774201
  var valid_774202 = header.getOrDefault("X-Amz-Security-Token")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Security-Token", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Content-Sha256", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-Algorithm")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-Algorithm", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Signature")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Signature", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-SignedHeaders", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-Credential")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-Credential", valid_774207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774208: Call_GetBulkDeploymentStatus_774197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_774208.validator(path, query, header, formData, body)
  let scheme = call_774208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774208.url(scheme.get, call_774208.host, call_774208.base,
                         call_774208.route, valid.getOrDefault("path"))
  result = hook(call_774208, url, valid)

proc call*(call_774209: Call_GetBulkDeploymentStatus_774197;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_774210 = newJObject()
  add(path_774210, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_774209.call(path_774210, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_774197(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_774198, base: "/",
    url: url_GetBulkDeploymentStatus_774199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_774225 = ref object of OpenApiRestCall_772581
proc url_UpdateConnectivityInfo_774227(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ThingName" in path, "`ThingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/things/"),
               (kind: VariableSegment, value: "ThingName"),
               (kind: ConstantSegment, value: "/connectivityInfo")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateConnectivityInfo_774226(path: JsonNode; query: JsonNode;
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
  var valid_774228 = path.getOrDefault("ThingName")
  valid_774228 = validateParameter(valid_774228, JString, required = true,
                                 default = nil)
  if valid_774228 != nil:
    section.add "ThingName", valid_774228
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
  var valid_774229 = header.getOrDefault("X-Amz-Date")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Date", valid_774229
  var valid_774230 = header.getOrDefault("X-Amz-Security-Token")
  valid_774230 = validateParameter(valid_774230, JString, required = false,
                                 default = nil)
  if valid_774230 != nil:
    section.add "X-Amz-Security-Token", valid_774230
  var valid_774231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774231 = validateParameter(valid_774231, JString, required = false,
                                 default = nil)
  if valid_774231 != nil:
    section.add "X-Amz-Content-Sha256", valid_774231
  var valid_774232 = header.getOrDefault("X-Amz-Algorithm")
  valid_774232 = validateParameter(valid_774232, JString, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "X-Amz-Algorithm", valid_774232
  var valid_774233 = header.getOrDefault("X-Amz-Signature")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "X-Amz-Signature", valid_774233
  var valid_774234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "X-Amz-SignedHeaders", valid_774234
  var valid_774235 = header.getOrDefault("X-Amz-Credential")
  valid_774235 = validateParameter(valid_774235, JString, required = false,
                                 default = nil)
  if valid_774235 != nil:
    section.add "X-Amz-Credential", valid_774235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774237: Call_UpdateConnectivityInfo_774225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_774237.validator(path, query, header, formData, body)
  let scheme = call_774237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774237.url(scheme.get, call_774237.host, call_774237.base,
                         call_774237.route, valid.getOrDefault("path"))
  result = hook(call_774237, url, valid)

proc call*(call_774238: Call_UpdateConnectivityInfo_774225; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_774239 = newJObject()
  var body_774240 = newJObject()
  add(path_774239, "ThingName", newJString(ThingName))
  if body != nil:
    body_774240 = body
  result = call_774238.call(path_774239, nil, nil, nil, body_774240)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_774225(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_774226, base: "/",
    url: url_UpdateConnectivityInfo_774227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_774211 = ref object of OpenApiRestCall_772581
proc url_GetConnectivityInfo_774213(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ThingName" in path, "`ThingName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/things/"),
               (kind: VariableSegment, value: "ThingName"),
               (kind: ConstantSegment, value: "/connectivityInfo")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConnectivityInfo_774212(path: JsonNode; query: JsonNode;
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
  var valid_774214 = path.getOrDefault("ThingName")
  valid_774214 = validateParameter(valid_774214, JString, required = true,
                                 default = nil)
  if valid_774214 != nil:
    section.add "ThingName", valid_774214
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
  var valid_774215 = header.getOrDefault("X-Amz-Date")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = nil)
  if valid_774215 != nil:
    section.add "X-Amz-Date", valid_774215
  var valid_774216 = header.getOrDefault("X-Amz-Security-Token")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "X-Amz-Security-Token", valid_774216
  var valid_774217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "X-Amz-Content-Sha256", valid_774217
  var valid_774218 = header.getOrDefault("X-Amz-Algorithm")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "X-Amz-Algorithm", valid_774218
  var valid_774219 = header.getOrDefault("X-Amz-Signature")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "X-Amz-Signature", valid_774219
  var valid_774220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "X-Amz-SignedHeaders", valid_774220
  var valid_774221 = header.getOrDefault("X-Amz-Credential")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "X-Amz-Credential", valid_774221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774222: Call_GetConnectivityInfo_774211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_774222.validator(path, query, header, formData, body)
  let scheme = call_774222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774222.url(scheme.get, call_774222.host, call_774222.base,
                         call_774222.route, valid.getOrDefault("path"))
  result = hook(call_774222, url, valid)

proc call*(call_774223: Call_GetConnectivityInfo_774211; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_774224 = newJObject()
  add(path_774224, "ThingName", newJString(ThingName))
  result = call_774223.call(path_774224, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_774211(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_774212, base: "/",
    url: url_GetConnectivityInfo_774213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_774241 = ref object of OpenApiRestCall_772581
proc url_GetConnectorDefinitionVersion_774243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetConnectorDefinitionVersion_774242(path: JsonNode; query: JsonNode;
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
  var valid_774244 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_774244 = validateParameter(valid_774244, JString, required = true,
                                 default = nil)
  if valid_774244 != nil:
    section.add "ConnectorDefinitionVersionId", valid_774244
  var valid_774245 = path.getOrDefault("ConnectorDefinitionId")
  valid_774245 = validateParameter(valid_774245, JString, required = true,
                                 default = nil)
  if valid_774245 != nil:
    section.add "ConnectorDefinitionId", valid_774245
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_774246 = query.getOrDefault("NextToken")
  valid_774246 = validateParameter(valid_774246, JString, required = false,
                                 default = nil)
  if valid_774246 != nil:
    section.add "NextToken", valid_774246
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
  var valid_774247 = header.getOrDefault("X-Amz-Date")
  valid_774247 = validateParameter(valid_774247, JString, required = false,
                                 default = nil)
  if valid_774247 != nil:
    section.add "X-Amz-Date", valid_774247
  var valid_774248 = header.getOrDefault("X-Amz-Security-Token")
  valid_774248 = validateParameter(valid_774248, JString, required = false,
                                 default = nil)
  if valid_774248 != nil:
    section.add "X-Amz-Security-Token", valid_774248
  var valid_774249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774249 = validateParameter(valid_774249, JString, required = false,
                                 default = nil)
  if valid_774249 != nil:
    section.add "X-Amz-Content-Sha256", valid_774249
  var valid_774250 = header.getOrDefault("X-Amz-Algorithm")
  valid_774250 = validateParameter(valid_774250, JString, required = false,
                                 default = nil)
  if valid_774250 != nil:
    section.add "X-Amz-Algorithm", valid_774250
  var valid_774251 = header.getOrDefault("X-Amz-Signature")
  valid_774251 = validateParameter(valid_774251, JString, required = false,
                                 default = nil)
  if valid_774251 != nil:
    section.add "X-Amz-Signature", valid_774251
  var valid_774252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774252 = validateParameter(valid_774252, JString, required = false,
                                 default = nil)
  if valid_774252 != nil:
    section.add "X-Amz-SignedHeaders", valid_774252
  var valid_774253 = header.getOrDefault("X-Amz-Credential")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-Credential", valid_774253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774254: Call_GetConnectorDefinitionVersion_774241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_774254.validator(path, query, header, formData, body)
  let scheme = call_774254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774254.url(scheme.get, call_774254.host, call_774254.base,
                         call_774254.route, valid.getOrDefault("path"))
  result = hook(call_774254, url, valid)

proc call*(call_774255: Call_GetConnectorDefinitionVersion_774241;
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
  var path_774256 = newJObject()
  var query_774257 = newJObject()
  add(query_774257, "NextToken", newJString(NextToken))
  add(path_774256, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(path_774256, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_774255.call(path_774256, query_774257, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_774241(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_774242, base: "/",
    url: url_GetConnectorDefinitionVersion_774243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_774258 = ref object of OpenApiRestCall_772581
proc url_GetCoreDefinitionVersion_774260(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCoreDefinitionVersion_774259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_774261 = path.getOrDefault("CoreDefinitionId")
  valid_774261 = validateParameter(valid_774261, JString, required = true,
                                 default = nil)
  if valid_774261 != nil:
    section.add "CoreDefinitionId", valid_774261
  var valid_774262 = path.getOrDefault("CoreDefinitionVersionId")
  valid_774262 = validateParameter(valid_774262, JString, required = true,
                                 default = nil)
  if valid_774262 != nil:
    section.add "CoreDefinitionVersionId", valid_774262
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
  var valid_774263 = header.getOrDefault("X-Amz-Date")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "X-Amz-Date", valid_774263
  var valid_774264 = header.getOrDefault("X-Amz-Security-Token")
  valid_774264 = validateParameter(valid_774264, JString, required = false,
                                 default = nil)
  if valid_774264 != nil:
    section.add "X-Amz-Security-Token", valid_774264
  var valid_774265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774265 = validateParameter(valid_774265, JString, required = false,
                                 default = nil)
  if valid_774265 != nil:
    section.add "X-Amz-Content-Sha256", valid_774265
  var valid_774266 = header.getOrDefault("X-Amz-Algorithm")
  valid_774266 = validateParameter(valid_774266, JString, required = false,
                                 default = nil)
  if valid_774266 != nil:
    section.add "X-Amz-Algorithm", valid_774266
  var valid_774267 = header.getOrDefault("X-Amz-Signature")
  valid_774267 = validateParameter(valid_774267, JString, required = false,
                                 default = nil)
  if valid_774267 != nil:
    section.add "X-Amz-Signature", valid_774267
  var valid_774268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774268 = validateParameter(valid_774268, JString, required = false,
                                 default = nil)
  if valid_774268 != nil:
    section.add "X-Amz-SignedHeaders", valid_774268
  var valid_774269 = header.getOrDefault("X-Amz-Credential")
  valid_774269 = validateParameter(valid_774269, JString, required = false,
                                 default = nil)
  if valid_774269 != nil:
    section.add "X-Amz-Credential", valid_774269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774270: Call_GetCoreDefinitionVersion_774258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_774270.validator(path, query, header, formData, body)
  let scheme = call_774270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774270.url(scheme.get, call_774270.host, call_774270.base,
                         call_774270.route, valid.getOrDefault("path"))
  result = hook(call_774270, url, valid)

proc call*(call_774271: Call_GetCoreDefinitionVersion_774258;
          CoreDefinitionId: string; CoreDefinitionVersionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_774272 = newJObject()
  add(path_774272, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(path_774272, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  result = call_774271.call(path_774272, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_774258(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_774259, base: "/",
    url: url_GetCoreDefinitionVersion_774260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_774273 = ref object of OpenApiRestCall_772581
proc url_GetDeploymentStatus_774275(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeploymentStatus_774274(path: JsonNode; query: JsonNode;
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
  var valid_774276 = path.getOrDefault("GroupId")
  valid_774276 = validateParameter(valid_774276, JString, required = true,
                                 default = nil)
  if valid_774276 != nil:
    section.add "GroupId", valid_774276
  var valid_774277 = path.getOrDefault("DeploymentId")
  valid_774277 = validateParameter(valid_774277, JString, required = true,
                                 default = nil)
  if valid_774277 != nil:
    section.add "DeploymentId", valid_774277
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
  var valid_774278 = header.getOrDefault("X-Amz-Date")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Date", valid_774278
  var valid_774279 = header.getOrDefault("X-Amz-Security-Token")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-Security-Token", valid_774279
  var valid_774280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-Content-Sha256", valid_774280
  var valid_774281 = header.getOrDefault("X-Amz-Algorithm")
  valid_774281 = validateParameter(valid_774281, JString, required = false,
                                 default = nil)
  if valid_774281 != nil:
    section.add "X-Amz-Algorithm", valid_774281
  var valid_774282 = header.getOrDefault("X-Amz-Signature")
  valid_774282 = validateParameter(valid_774282, JString, required = false,
                                 default = nil)
  if valid_774282 != nil:
    section.add "X-Amz-Signature", valid_774282
  var valid_774283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774283 = validateParameter(valid_774283, JString, required = false,
                                 default = nil)
  if valid_774283 != nil:
    section.add "X-Amz-SignedHeaders", valid_774283
  var valid_774284 = header.getOrDefault("X-Amz-Credential")
  valid_774284 = validateParameter(valid_774284, JString, required = false,
                                 default = nil)
  if valid_774284 != nil:
    section.add "X-Amz-Credential", valid_774284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774285: Call_GetDeploymentStatus_774273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_774285.validator(path, query, header, formData, body)
  let scheme = call_774285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774285.url(scheme.get, call_774285.host, call_774285.base,
                         call_774285.route, valid.getOrDefault("path"))
  result = hook(call_774285, url, valid)

proc call*(call_774286: Call_GetDeploymentStatus_774273; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_774287 = newJObject()
  add(path_774287, "GroupId", newJString(GroupId))
  add(path_774287, "DeploymentId", newJString(DeploymentId))
  result = call_774286.call(path_774287, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_774273(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_774274, base: "/",
    url: url_GetDeploymentStatus_774275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_774288 = ref object of OpenApiRestCall_772581
proc url_GetDeviceDefinitionVersion_774290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDeviceDefinitionVersion_774289(path: JsonNode; query: JsonNode;
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
  var valid_774291 = path.getOrDefault("DeviceDefinitionId")
  valid_774291 = validateParameter(valid_774291, JString, required = true,
                                 default = nil)
  if valid_774291 != nil:
    section.add "DeviceDefinitionId", valid_774291
  var valid_774292 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_774292 = validateParameter(valid_774292, JString, required = true,
                                 default = nil)
  if valid_774292 != nil:
    section.add "DeviceDefinitionVersionId", valid_774292
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_774293 = query.getOrDefault("NextToken")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "NextToken", valid_774293
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
  var valid_774294 = header.getOrDefault("X-Amz-Date")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "X-Amz-Date", valid_774294
  var valid_774295 = header.getOrDefault("X-Amz-Security-Token")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "X-Amz-Security-Token", valid_774295
  var valid_774296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "X-Amz-Content-Sha256", valid_774296
  var valid_774297 = header.getOrDefault("X-Amz-Algorithm")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "X-Amz-Algorithm", valid_774297
  var valid_774298 = header.getOrDefault("X-Amz-Signature")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Signature", valid_774298
  var valid_774299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774299 = validateParameter(valid_774299, JString, required = false,
                                 default = nil)
  if valid_774299 != nil:
    section.add "X-Amz-SignedHeaders", valid_774299
  var valid_774300 = header.getOrDefault("X-Amz-Credential")
  valid_774300 = validateParameter(valid_774300, JString, required = false,
                                 default = nil)
  if valid_774300 != nil:
    section.add "X-Amz-Credential", valid_774300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774301: Call_GetDeviceDefinitionVersion_774288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_774301.validator(path, query, header, formData, body)
  let scheme = call_774301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774301.url(scheme.get, call_774301.host, call_774301.base,
                         call_774301.route, valid.getOrDefault("path"))
  result = hook(call_774301, url, valid)

proc call*(call_774302: Call_GetDeviceDefinitionVersion_774288;
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
  var path_774303 = newJObject()
  var query_774304 = newJObject()
  add(path_774303, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_774304, "NextToken", newJString(NextToken))
  add(path_774303, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_774302.call(path_774303, query_774304, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_774288(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_774289, base: "/",
    url: url_GetDeviceDefinitionVersion_774290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_774305 = ref object of OpenApiRestCall_772581
proc url_GetFunctionDefinitionVersion_774307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFunctionDefinitionVersion_774306(path: JsonNode; query: JsonNode;
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
  var valid_774308 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_774308 = validateParameter(valid_774308, JString, required = true,
                                 default = nil)
  if valid_774308 != nil:
    section.add "FunctionDefinitionVersionId", valid_774308
  var valid_774309 = path.getOrDefault("FunctionDefinitionId")
  valid_774309 = validateParameter(valid_774309, JString, required = true,
                                 default = nil)
  if valid_774309 != nil:
    section.add "FunctionDefinitionId", valid_774309
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_774310 = query.getOrDefault("NextToken")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "NextToken", valid_774310
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
  var valid_774311 = header.getOrDefault("X-Amz-Date")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "X-Amz-Date", valid_774311
  var valid_774312 = header.getOrDefault("X-Amz-Security-Token")
  valid_774312 = validateParameter(valid_774312, JString, required = false,
                                 default = nil)
  if valid_774312 != nil:
    section.add "X-Amz-Security-Token", valid_774312
  var valid_774313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "X-Amz-Content-Sha256", valid_774313
  var valid_774314 = header.getOrDefault("X-Amz-Algorithm")
  valid_774314 = validateParameter(valid_774314, JString, required = false,
                                 default = nil)
  if valid_774314 != nil:
    section.add "X-Amz-Algorithm", valid_774314
  var valid_774315 = header.getOrDefault("X-Amz-Signature")
  valid_774315 = validateParameter(valid_774315, JString, required = false,
                                 default = nil)
  if valid_774315 != nil:
    section.add "X-Amz-Signature", valid_774315
  var valid_774316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774316 = validateParameter(valid_774316, JString, required = false,
                                 default = nil)
  if valid_774316 != nil:
    section.add "X-Amz-SignedHeaders", valid_774316
  var valid_774317 = header.getOrDefault("X-Amz-Credential")
  valid_774317 = validateParameter(valid_774317, JString, required = false,
                                 default = nil)
  if valid_774317 != nil:
    section.add "X-Amz-Credential", valid_774317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774318: Call_GetFunctionDefinitionVersion_774305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_774318.validator(path, query, header, formData, body)
  let scheme = call_774318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774318.url(scheme.get, call_774318.host, call_774318.base,
                         call_774318.route, valid.getOrDefault("path"))
  result = hook(call_774318, url, valid)

proc call*(call_774319: Call_GetFunctionDefinitionVersion_774305;
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
  var path_774320 = newJObject()
  var query_774321 = newJObject()
  add(path_774320, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_774321, "NextToken", newJString(NextToken))
  add(path_774320, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_774319.call(path_774320, query_774321, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_774305(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_774306, base: "/",
    url: url_GetFunctionDefinitionVersion_774307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_774322 = ref object of OpenApiRestCall_772581
proc url_GetGroupCertificateAuthority_774324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroupCertificateAuthority_774323(path: JsonNode; query: JsonNode;
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
  var valid_774325 = path.getOrDefault("GroupId")
  valid_774325 = validateParameter(valid_774325, JString, required = true,
                                 default = nil)
  if valid_774325 != nil:
    section.add "GroupId", valid_774325
  var valid_774326 = path.getOrDefault("CertificateAuthorityId")
  valid_774326 = validateParameter(valid_774326, JString, required = true,
                                 default = nil)
  if valid_774326 != nil:
    section.add "CertificateAuthorityId", valid_774326
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
  var valid_774327 = header.getOrDefault("X-Amz-Date")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-Date", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-Security-Token")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-Security-Token", valid_774328
  var valid_774329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = nil)
  if valid_774329 != nil:
    section.add "X-Amz-Content-Sha256", valid_774329
  var valid_774330 = header.getOrDefault("X-Amz-Algorithm")
  valid_774330 = validateParameter(valid_774330, JString, required = false,
                                 default = nil)
  if valid_774330 != nil:
    section.add "X-Amz-Algorithm", valid_774330
  var valid_774331 = header.getOrDefault("X-Amz-Signature")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "X-Amz-Signature", valid_774331
  var valid_774332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "X-Amz-SignedHeaders", valid_774332
  var valid_774333 = header.getOrDefault("X-Amz-Credential")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Credential", valid_774333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774334: Call_GetGroupCertificateAuthority_774322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_774334.validator(path, query, header, formData, body)
  let scheme = call_774334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774334.url(scheme.get, call_774334.host, call_774334.base,
                         call_774334.route, valid.getOrDefault("path"))
  result = hook(call_774334, url, valid)

proc call*(call_774335: Call_GetGroupCertificateAuthority_774322; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_774336 = newJObject()
  add(path_774336, "GroupId", newJString(GroupId))
  add(path_774336, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_774335.call(path_774336, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_774322(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_774323, base: "/",
    url: url_GetGroupCertificateAuthority_774324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_774351 = ref object of OpenApiRestCall_772581
proc url_UpdateGroupCertificateConfiguration_774353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"), (kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGroupCertificateConfiguration_774352(path: JsonNode;
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
  var valid_774354 = path.getOrDefault("GroupId")
  valid_774354 = validateParameter(valid_774354, JString, required = true,
                                 default = nil)
  if valid_774354 != nil:
    section.add "GroupId", valid_774354
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
  var valid_774355 = header.getOrDefault("X-Amz-Date")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Date", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Security-Token")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Security-Token", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Content-Sha256", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Algorithm")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Algorithm", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-Signature")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-Signature", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-SignedHeaders", valid_774360
  var valid_774361 = header.getOrDefault("X-Amz-Credential")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Credential", valid_774361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774363: Call_UpdateGroupCertificateConfiguration_774351;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_774363.validator(path, query, header, formData, body)
  let scheme = call_774363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774363.url(scheme.get, call_774363.host, call_774363.base,
                         call_774363.route, valid.getOrDefault("path"))
  result = hook(call_774363, url, valid)

proc call*(call_774364: Call_UpdateGroupCertificateConfiguration_774351;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_774365 = newJObject()
  var body_774366 = newJObject()
  add(path_774365, "GroupId", newJString(GroupId))
  if body != nil:
    body_774366 = body
  result = call_774364.call(path_774365, nil, nil, nil, body_774366)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_774351(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_774352, base: "/",
    url: url_UpdateGroupCertificateConfiguration_774353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_774337 = ref object of OpenApiRestCall_772581
proc url_GetGroupCertificateConfiguration_774339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"), (kind: ConstantSegment,
        value: "/certificateauthorities/configuration/expiry")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroupCertificateConfiguration_774338(path: JsonNode;
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
  var valid_774340 = path.getOrDefault("GroupId")
  valid_774340 = validateParameter(valid_774340, JString, required = true,
                                 default = nil)
  if valid_774340 != nil:
    section.add "GroupId", valid_774340
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
  var valid_774341 = header.getOrDefault("X-Amz-Date")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "X-Amz-Date", valid_774341
  var valid_774342 = header.getOrDefault("X-Amz-Security-Token")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Security-Token", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Content-Sha256", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Algorithm")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Algorithm", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Signature")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Signature", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-SignedHeaders", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-Credential")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-Credential", valid_774347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774348: Call_GetGroupCertificateConfiguration_774337;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_774348.validator(path, query, header, formData, body)
  let scheme = call_774348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774348.url(scheme.get, call_774348.host, call_774348.base,
                         call_774348.route, valid.getOrDefault("path"))
  result = hook(call_774348, url, valid)

proc call*(call_774349: Call_GetGroupCertificateConfiguration_774337;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_774350 = newJObject()
  add(path_774350, "GroupId", newJString(GroupId))
  result = call_774349.call(path_774350, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_774337(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_774338, base: "/",
    url: url_GetGroupCertificateConfiguration_774339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_774367 = ref object of OpenApiRestCall_772581
proc url_GetGroupVersion_774369(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGroupVersion_774368(path: JsonNode; query: JsonNode;
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
  var valid_774370 = path.getOrDefault("GroupVersionId")
  valid_774370 = validateParameter(valid_774370, JString, required = true,
                                 default = nil)
  if valid_774370 != nil:
    section.add "GroupVersionId", valid_774370
  var valid_774371 = path.getOrDefault("GroupId")
  valid_774371 = validateParameter(valid_774371, JString, required = true,
                                 default = nil)
  if valid_774371 != nil:
    section.add "GroupId", valid_774371
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
  var valid_774372 = header.getOrDefault("X-Amz-Date")
  valid_774372 = validateParameter(valid_774372, JString, required = false,
                                 default = nil)
  if valid_774372 != nil:
    section.add "X-Amz-Date", valid_774372
  var valid_774373 = header.getOrDefault("X-Amz-Security-Token")
  valid_774373 = validateParameter(valid_774373, JString, required = false,
                                 default = nil)
  if valid_774373 != nil:
    section.add "X-Amz-Security-Token", valid_774373
  var valid_774374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Content-Sha256", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-Algorithm")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-Algorithm", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-Signature")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Signature", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-SignedHeaders", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Credential")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Credential", valid_774378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774379: Call_GetGroupVersion_774367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_774379.validator(path, query, header, formData, body)
  let scheme = call_774379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774379.url(scheme.get, call_774379.host, call_774379.base,
                         call_774379.route, valid.getOrDefault("path"))
  result = hook(call_774379, url, valid)

proc call*(call_774380: Call_GetGroupVersion_774367; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_774381 = newJObject()
  add(path_774381, "GroupVersionId", newJString(GroupVersionId))
  add(path_774381, "GroupId", newJString(GroupId))
  result = call_774380.call(path_774381, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_774367(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_774368, base: "/", url: url_GetGroupVersion_774369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_774382 = ref object of OpenApiRestCall_772581
proc url_GetLoggerDefinitionVersion_774384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetLoggerDefinitionVersion_774383(path: JsonNode; query: JsonNode;
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
  var valid_774385 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_774385 = validateParameter(valid_774385, JString, required = true,
                                 default = nil)
  if valid_774385 != nil:
    section.add "LoggerDefinitionVersionId", valid_774385
  var valid_774386 = path.getOrDefault("LoggerDefinitionId")
  valid_774386 = validateParameter(valid_774386, JString, required = true,
                                 default = nil)
  if valid_774386 != nil:
    section.add "LoggerDefinitionId", valid_774386
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_774387 = query.getOrDefault("NextToken")
  valid_774387 = validateParameter(valid_774387, JString, required = false,
                                 default = nil)
  if valid_774387 != nil:
    section.add "NextToken", valid_774387
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
  var valid_774388 = header.getOrDefault("X-Amz-Date")
  valid_774388 = validateParameter(valid_774388, JString, required = false,
                                 default = nil)
  if valid_774388 != nil:
    section.add "X-Amz-Date", valid_774388
  var valid_774389 = header.getOrDefault("X-Amz-Security-Token")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Security-Token", valid_774389
  var valid_774390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774390 = validateParameter(valid_774390, JString, required = false,
                                 default = nil)
  if valid_774390 != nil:
    section.add "X-Amz-Content-Sha256", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-Algorithm")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-Algorithm", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Signature")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Signature", valid_774392
  var valid_774393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774393 = validateParameter(valid_774393, JString, required = false,
                                 default = nil)
  if valid_774393 != nil:
    section.add "X-Amz-SignedHeaders", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-Credential")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-Credential", valid_774394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774395: Call_GetLoggerDefinitionVersion_774382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_774395.validator(path, query, header, formData, body)
  let scheme = call_774395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774395.url(scheme.get, call_774395.host, call_774395.base,
                         call_774395.route, valid.getOrDefault("path"))
  result = hook(call_774395, url, valid)

proc call*(call_774396: Call_GetLoggerDefinitionVersion_774382;
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
  var path_774397 = newJObject()
  var query_774398 = newJObject()
  add(path_774397, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_774398, "NextToken", newJString(NextToken))
  add(path_774397, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_774396.call(path_774397, query_774398, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_774382(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_774383, base: "/",
    url: url_GetLoggerDefinitionVersion_774384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_774399 = ref object of OpenApiRestCall_772581
proc url_GetResourceDefinitionVersion_774401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetResourceDefinitionVersion_774400(path: JsonNode; query: JsonNode;
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
  var valid_774402 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_774402 = validateParameter(valid_774402, JString, required = true,
                                 default = nil)
  if valid_774402 != nil:
    section.add "ResourceDefinitionVersionId", valid_774402
  var valid_774403 = path.getOrDefault("ResourceDefinitionId")
  valid_774403 = validateParameter(valid_774403, JString, required = true,
                                 default = nil)
  if valid_774403 != nil:
    section.add "ResourceDefinitionId", valid_774403
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
  var valid_774404 = header.getOrDefault("X-Amz-Date")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "X-Amz-Date", valid_774404
  var valid_774405 = header.getOrDefault("X-Amz-Security-Token")
  valid_774405 = validateParameter(valid_774405, JString, required = false,
                                 default = nil)
  if valid_774405 != nil:
    section.add "X-Amz-Security-Token", valid_774405
  var valid_774406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "X-Amz-Content-Sha256", valid_774406
  var valid_774407 = header.getOrDefault("X-Amz-Algorithm")
  valid_774407 = validateParameter(valid_774407, JString, required = false,
                                 default = nil)
  if valid_774407 != nil:
    section.add "X-Amz-Algorithm", valid_774407
  var valid_774408 = header.getOrDefault("X-Amz-Signature")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "X-Amz-Signature", valid_774408
  var valid_774409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-SignedHeaders", valid_774409
  var valid_774410 = header.getOrDefault("X-Amz-Credential")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Credential", valid_774410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774411: Call_GetResourceDefinitionVersion_774399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_774411.validator(path, query, header, formData, body)
  let scheme = call_774411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774411.url(scheme.get, call_774411.host, call_774411.base,
                         call_774411.route, valid.getOrDefault("path"))
  result = hook(call_774411, url, valid)

proc call*(call_774412: Call_GetResourceDefinitionVersion_774399;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_774413 = newJObject()
  add(path_774413, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_774413, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_774412.call(path_774413, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_774399(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_774400, base: "/",
    url: url_GetResourceDefinitionVersion_774401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_774414 = ref object of OpenApiRestCall_772581
proc url_GetSubscriptionDefinitionVersion_774416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSubscriptionDefinitionVersion_774415(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_774417 = path.getOrDefault("SubscriptionDefinitionId")
  valid_774417 = validateParameter(valid_774417, JString, required = true,
                                 default = nil)
  if valid_774417 != nil:
    section.add "SubscriptionDefinitionId", valid_774417
  var valid_774418 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_774418 = validateParameter(valid_774418, JString, required = true,
                                 default = nil)
  if valid_774418 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_774418
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_774419 = query.getOrDefault("NextToken")
  valid_774419 = validateParameter(valid_774419, JString, required = false,
                                 default = nil)
  if valid_774419 != nil:
    section.add "NextToken", valid_774419
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
  var valid_774420 = header.getOrDefault("X-Amz-Date")
  valid_774420 = validateParameter(valid_774420, JString, required = false,
                                 default = nil)
  if valid_774420 != nil:
    section.add "X-Amz-Date", valid_774420
  var valid_774421 = header.getOrDefault("X-Amz-Security-Token")
  valid_774421 = validateParameter(valid_774421, JString, required = false,
                                 default = nil)
  if valid_774421 != nil:
    section.add "X-Amz-Security-Token", valid_774421
  var valid_774422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774422 = validateParameter(valid_774422, JString, required = false,
                                 default = nil)
  if valid_774422 != nil:
    section.add "X-Amz-Content-Sha256", valid_774422
  var valid_774423 = header.getOrDefault("X-Amz-Algorithm")
  valid_774423 = validateParameter(valid_774423, JString, required = false,
                                 default = nil)
  if valid_774423 != nil:
    section.add "X-Amz-Algorithm", valid_774423
  var valid_774424 = header.getOrDefault("X-Amz-Signature")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "X-Amz-Signature", valid_774424
  var valid_774425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "X-Amz-SignedHeaders", valid_774425
  var valid_774426 = header.getOrDefault("X-Amz-Credential")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "X-Amz-Credential", valid_774426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774427: Call_GetSubscriptionDefinitionVersion_774414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_774427.validator(path, query, header, formData, body)
  let scheme = call_774427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774427.url(scheme.get, call_774427.host, call_774427.base,
                         call_774427.route, valid.getOrDefault("path"))
  result = hook(call_774427, url, valid)

proc call*(call_774428: Call_GetSubscriptionDefinitionVersion_774414;
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
  var path_774429 = newJObject()
  var query_774430 = newJObject()
  add(query_774430, "NextToken", newJString(NextToken))
  add(path_774429, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(path_774429, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  result = call_774428.call(path_774429, query_774430, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_774414(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_774415, base: "/",
    url: url_GetSubscriptionDefinitionVersion_774416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_774431 = ref object of OpenApiRestCall_772581
proc url_ListBulkDeploymentDetailedReports_774433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListBulkDeploymentDetailedReports_774432(path: JsonNode;
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
  var valid_774434 = path.getOrDefault("BulkDeploymentId")
  valid_774434 = validateParameter(valid_774434, JString, required = true,
                                 default = nil)
  if valid_774434 != nil:
    section.add "BulkDeploymentId", valid_774434
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_774435 = query.getOrDefault("NextToken")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "NextToken", valid_774435
  var valid_774436 = query.getOrDefault("MaxResults")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "MaxResults", valid_774436
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
  var valid_774437 = header.getOrDefault("X-Amz-Date")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Date", valid_774437
  var valid_774438 = header.getOrDefault("X-Amz-Security-Token")
  valid_774438 = validateParameter(valid_774438, JString, required = false,
                                 default = nil)
  if valid_774438 != nil:
    section.add "X-Amz-Security-Token", valid_774438
  var valid_774439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774439 = validateParameter(valid_774439, JString, required = false,
                                 default = nil)
  if valid_774439 != nil:
    section.add "X-Amz-Content-Sha256", valid_774439
  var valid_774440 = header.getOrDefault("X-Amz-Algorithm")
  valid_774440 = validateParameter(valid_774440, JString, required = false,
                                 default = nil)
  if valid_774440 != nil:
    section.add "X-Amz-Algorithm", valid_774440
  var valid_774441 = header.getOrDefault("X-Amz-Signature")
  valid_774441 = validateParameter(valid_774441, JString, required = false,
                                 default = nil)
  if valid_774441 != nil:
    section.add "X-Amz-Signature", valid_774441
  var valid_774442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "X-Amz-SignedHeaders", valid_774442
  var valid_774443 = header.getOrDefault("X-Amz-Credential")
  valid_774443 = validateParameter(valid_774443, JString, required = false,
                                 default = nil)
  if valid_774443 != nil:
    section.add "X-Amz-Credential", valid_774443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774444: Call_ListBulkDeploymentDetailedReports_774431;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_774444.validator(path, query, header, formData, body)
  let scheme = call_774444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774444.url(scheme.get, call_774444.host, call_774444.base,
                         call_774444.route, valid.getOrDefault("path"))
  result = hook(call_774444, url, valid)

proc call*(call_774445: Call_ListBulkDeploymentDetailedReports_774431;
          BulkDeploymentId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_774446 = newJObject()
  var query_774447 = newJObject()
  add(query_774447, "NextToken", newJString(NextToken))
  add(query_774447, "MaxResults", newJString(MaxResults))
  add(path_774446, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_774445.call(path_774446, query_774447, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_774431(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_774432, base: "/",
    url: url_ListBulkDeploymentDetailedReports_774433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_774463 = ref object of OpenApiRestCall_772581
proc url_StartBulkDeployment_774465(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartBulkDeployment_774464(path: JsonNode; query: JsonNode;
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
  var valid_774466 = header.getOrDefault("X-Amz-Date")
  valid_774466 = validateParameter(valid_774466, JString, required = false,
                                 default = nil)
  if valid_774466 != nil:
    section.add "X-Amz-Date", valid_774466
  var valid_774467 = header.getOrDefault("X-Amz-Security-Token")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "X-Amz-Security-Token", valid_774467
  var valid_774468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774468 = validateParameter(valid_774468, JString, required = false,
                                 default = nil)
  if valid_774468 != nil:
    section.add "X-Amz-Content-Sha256", valid_774468
  var valid_774469 = header.getOrDefault("X-Amz-Algorithm")
  valid_774469 = validateParameter(valid_774469, JString, required = false,
                                 default = nil)
  if valid_774469 != nil:
    section.add "X-Amz-Algorithm", valid_774469
  var valid_774470 = header.getOrDefault("X-Amzn-Client-Token")
  valid_774470 = validateParameter(valid_774470, JString, required = false,
                                 default = nil)
  if valid_774470 != nil:
    section.add "X-Amzn-Client-Token", valid_774470
  var valid_774471 = header.getOrDefault("X-Amz-Signature")
  valid_774471 = validateParameter(valid_774471, JString, required = false,
                                 default = nil)
  if valid_774471 != nil:
    section.add "X-Amz-Signature", valid_774471
  var valid_774472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774472 = validateParameter(valid_774472, JString, required = false,
                                 default = nil)
  if valid_774472 != nil:
    section.add "X-Amz-SignedHeaders", valid_774472
  var valid_774473 = header.getOrDefault("X-Amz-Credential")
  valid_774473 = validateParameter(valid_774473, JString, required = false,
                                 default = nil)
  if valid_774473 != nil:
    section.add "X-Amz-Credential", valid_774473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774475: Call_StartBulkDeployment_774463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_774475.validator(path, query, header, formData, body)
  let scheme = call_774475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774475.url(scheme.get, call_774475.host, call_774475.base,
                         call_774475.route, valid.getOrDefault("path"))
  result = hook(call_774475, url, valid)

proc call*(call_774476: Call_StartBulkDeployment_774463; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_774477 = newJObject()
  if body != nil:
    body_774477 = body
  result = call_774476.call(nil, nil, nil, nil, body_774477)

var startBulkDeployment* = Call_StartBulkDeployment_774463(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_774464, base: "/",
    url: url_StartBulkDeployment_774465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_774448 = ref object of OpenApiRestCall_772581
proc url_ListBulkDeployments_774450(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBulkDeployments_774449(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_774451 = query.getOrDefault("NextToken")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "NextToken", valid_774451
  var valid_774452 = query.getOrDefault("MaxResults")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "MaxResults", valid_774452
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
  var valid_774453 = header.getOrDefault("X-Amz-Date")
  valid_774453 = validateParameter(valid_774453, JString, required = false,
                                 default = nil)
  if valid_774453 != nil:
    section.add "X-Amz-Date", valid_774453
  var valid_774454 = header.getOrDefault("X-Amz-Security-Token")
  valid_774454 = validateParameter(valid_774454, JString, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "X-Amz-Security-Token", valid_774454
  var valid_774455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774455 = validateParameter(valid_774455, JString, required = false,
                                 default = nil)
  if valid_774455 != nil:
    section.add "X-Amz-Content-Sha256", valid_774455
  var valid_774456 = header.getOrDefault("X-Amz-Algorithm")
  valid_774456 = validateParameter(valid_774456, JString, required = false,
                                 default = nil)
  if valid_774456 != nil:
    section.add "X-Amz-Algorithm", valid_774456
  var valid_774457 = header.getOrDefault("X-Amz-Signature")
  valid_774457 = validateParameter(valid_774457, JString, required = false,
                                 default = nil)
  if valid_774457 != nil:
    section.add "X-Amz-Signature", valid_774457
  var valid_774458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774458 = validateParameter(valid_774458, JString, required = false,
                                 default = nil)
  if valid_774458 != nil:
    section.add "X-Amz-SignedHeaders", valid_774458
  var valid_774459 = header.getOrDefault("X-Amz-Credential")
  valid_774459 = validateParameter(valid_774459, JString, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "X-Amz-Credential", valid_774459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774460: Call_ListBulkDeployments_774448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_774460.validator(path, query, header, formData, body)
  let scheme = call_774460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774460.url(scheme.get, call_774460.host, call_774460.base,
                         call_774460.route, valid.getOrDefault("path"))
  result = hook(call_774460, url, valid)

proc call*(call_774461: Call_ListBulkDeployments_774448; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_774462 = newJObject()
  add(query_774462, "NextToken", newJString(NextToken))
  add(query_774462, "MaxResults", newJString(MaxResults))
  result = call_774461.call(nil, query_774462, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_774448(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_774449, base: "/",
    url: url_ListBulkDeployments_774450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774492 = ref object of OpenApiRestCall_772581
proc url_TagResource_774494(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_774493(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Add resource tags to a Greengrass Resource. Valid resources are Group, Connector, Core, Device, Function, Logger, Subscription, and Resource Defintions, and also BulkDeploymentIds.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_774495 = path.getOrDefault("resource-arn")
  valid_774495 = validateParameter(valid_774495, JString, required = true,
                                 default = nil)
  if valid_774495 != nil:
    section.add "resource-arn", valid_774495
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
  var valid_774496 = header.getOrDefault("X-Amz-Date")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-Date", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Security-Token")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Security-Token", valid_774497
  var valid_774498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774498 = validateParameter(valid_774498, JString, required = false,
                                 default = nil)
  if valid_774498 != nil:
    section.add "X-Amz-Content-Sha256", valid_774498
  var valid_774499 = header.getOrDefault("X-Amz-Algorithm")
  valid_774499 = validateParameter(valid_774499, JString, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "X-Amz-Algorithm", valid_774499
  var valid_774500 = header.getOrDefault("X-Amz-Signature")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "X-Amz-Signature", valid_774500
  var valid_774501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774501 = validateParameter(valid_774501, JString, required = false,
                                 default = nil)
  if valid_774501 != nil:
    section.add "X-Amz-SignedHeaders", valid_774501
  var valid_774502 = header.getOrDefault("X-Amz-Credential")
  valid_774502 = validateParameter(valid_774502, JString, required = false,
                                 default = nil)
  if valid_774502 != nil:
    section.add "X-Amz-Credential", valid_774502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774504: Call_TagResource_774492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add resource tags to a Greengrass Resource. Valid resources are Group, Connector, Core, Device, Function, Logger, Subscription, and Resource Defintions, and also BulkDeploymentIds.
  ## 
  let valid = call_774504.validator(path, query, header, formData, body)
  let scheme = call_774504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774504.url(scheme.get, call_774504.host, call_774504.base,
                         call_774504.route, valid.getOrDefault("path"))
  result = hook(call_774504, url, valid)

proc call*(call_774505: Call_TagResource_774492; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add resource tags to a Greengrass Resource. Valid resources are Group, Connector, Core, Device, Function, Logger, Subscription, and Resource Defintions, and also BulkDeploymentIds.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_774506 = newJObject()
  var body_774507 = newJObject()
  add(path_774506, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_774507 = body
  result = call_774505.call(path_774506, nil, nil, nil, body_774507)

var tagResource* = Call_TagResource_774492(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_774493,
                                        base: "/", url: url_TagResource_774494,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_774478 = ref object of OpenApiRestCall_772581
proc url_ListTagsForResource_774480(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_774479(path: JsonNode; query: JsonNode;
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
  var valid_774481 = path.getOrDefault("resource-arn")
  valid_774481 = validateParameter(valid_774481, JString, required = true,
                                 default = nil)
  if valid_774481 != nil:
    section.add "resource-arn", valid_774481
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
  var valid_774482 = header.getOrDefault("X-Amz-Date")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Date", valid_774482
  var valid_774483 = header.getOrDefault("X-Amz-Security-Token")
  valid_774483 = validateParameter(valid_774483, JString, required = false,
                                 default = nil)
  if valid_774483 != nil:
    section.add "X-Amz-Security-Token", valid_774483
  var valid_774484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774484 = validateParameter(valid_774484, JString, required = false,
                                 default = nil)
  if valid_774484 != nil:
    section.add "X-Amz-Content-Sha256", valid_774484
  var valid_774485 = header.getOrDefault("X-Amz-Algorithm")
  valid_774485 = validateParameter(valid_774485, JString, required = false,
                                 default = nil)
  if valid_774485 != nil:
    section.add "X-Amz-Algorithm", valid_774485
  var valid_774486 = header.getOrDefault("X-Amz-Signature")
  valid_774486 = validateParameter(valid_774486, JString, required = false,
                                 default = nil)
  if valid_774486 != nil:
    section.add "X-Amz-Signature", valid_774486
  var valid_774487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774487 = validateParameter(valid_774487, JString, required = false,
                                 default = nil)
  if valid_774487 != nil:
    section.add "X-Amz-SignedHeaders", valid_774487
  var valid_774488 = header.getOrDefault("X-Amz-Credential")
  valid_774488 = validateParameter(valid_774488, JString, required = false,
                                 default = nil)
  if valid_774488 != nil:
    section.add "X-Amz-Credential", valid_774488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774489: Call_ListTagsForResource_774478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_774489.validator(path, query, header, formData, body)
  let scheme = call_774489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774489.url(scheme.get, call_774489.host, call_774489.base,
                         call_774489.route, valid.getOrDefault("path"))
  result = hook(call_774489, url, valid)

proc call*(call_774490: Call_ListTagsForResource_774478; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_774491 = newJObject()
  add(path_774491, "resource-arn", newJString(resourceArn))
  result = call_774490.call(path_774491, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_774478(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_774479, base: "/",
    url: url_ListTagsForResource_774480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_774508 = ref object of OpenApiRestCall_772581
proc url_ResetDeployments_774510(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "GroupId" in path, "`GroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/greengrass/groups/"),
               (kind: VariableSegment, value: "GroupId"),
               (kind: ConstantSegment, value: "/deployments/$reset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ResetDeployments_774509(path: JsonNode; query: JsonNode;
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
  var valid_774511 = path.getOrDefault("GroupId")
  valid_774511 = validateParameter(valid_774511, JString, required = true,
                                 default = nil)
  if valid_774511 != nil:
    section.add "GroupId", valid_774511
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
  var valid_774512 = header.getOrDefault("X-Amz-Date")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "X-Amz-Date", valid_774512
  var valid_774513 = header.getOrDefault("X-Amz-Security-Token")
  valid_774513 = validateParameter(valid_774513, JString, required = false,
                                 default = nil)
  if valid_774513 != nil:
    section.add "X-Amz-Security-Token", valid_774513
  var valid_774514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774514 = validateParameter(valid_774514, JString, required = false,
                                 default = nil)
  if valid_774514 != nil:
    section.add "X-Amz-Content-Sha256", valid_774514
  var valid_774515 = header.getOrDefault("X-Amz-Algorithm")
  valid_774515 = validateParameter(valid_774515, JString, required = false,
                                 default = nil)
  if valid_774515 != nil:
    section.add "X-Amz-Algorithm", valid_774515
  var valid_774516 = header.getOrDefault("X-Amzn-Client-Token")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "X-Amzn-Client-Token", valid_774516
  var valid_774517 = header.getOrDefault("X-Amz-Signature")
  valid_774517 = validateParameter(valid_774517, JString, required = false,
                                 default = nil)
  if valid_774517 != nil:
    section.add "X-Amz-Signature", valid_774517
  var valid_774518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-SignedHeaders", valid_774518
  var valid_774519 = header.getOrDefault("X-Amz-Credential")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "X-Amz-Credential", valid_774519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774521: Call_ResetDeployments_774508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_774521.validator(path, query, header, formData, body)
  let scheme = call_774521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774521.url(scheme.get, call_774521.host, call_774521.base,
                         call_774521.route, valid.getOrDefault("path"))
  result = hook(call_774521, url, valid)

proc call*(call_774522: Call_ResetDeployments_774508; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_774523 = newJObject()
  var body_774524 = newJObject()
  add(path_774523, "GroupId", newJString(GroupId))
  if body != nil:
    body_774524 = body
  result = call_774522.call(path_774523, nil, nil, nil, body_774524)

var resetDeployments* = Call_ResetDeployments_774508(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_774509, base: "/",
    url: url_ResetDeployments_774510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_774525 = ref object of OpenApiRestCall_772581
proc url_StopBulkDeployment_774527(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StopBulkDeployment_774526(path: JsonNode; query: JsonNode;
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
  var valid_774528 = path.getOrDefault("BulkDeploymentId")
  valid_774528 = validateParameter(valid_774528, JString, required = true,
                                 default = nil)
  if valid_774528 != nil:
    section.add "BulkDeploymentId", valid_774528
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
  var valid_774529 = header.getOrDefault("X-Amz-Date")
  valid_774529 = validateParameter(valid_774529, JString, required = false,
                                 default = nil)
  if valid_774529 != nil:
    section.add "X-Amz-Date", valid_774529
  var valid_774530 = header.getOrDefault("X-Amz-Security-Token")
  valid_774530 = validateParameter(valid_774530, JString, required = false,
                                 default = nil)
  if valid_774530 != nil:
    section.add "X-Amz-Security-Token", valid_774530
  var valid_774531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774531 = validateParameter(valid_774531, JString, required = false,
                                 default = nil)
  if valid_774531 != nil:
    section.add "X-Amz-Content-Sha256", valid_774531
  var valid_774532 = header.getOrDefault("X-Amz-Algorithm")
  valid_774532 = validateParameter(valid_774532, JString, required = false,
                                 default = nil)
  if valid_774532 != nil:
    section.add "X-Amz-Algorithm", valid_774532
  var valid_774533 = header.getOrDefault("X-Amz-Signature")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "X-Amz-Signature", valid_774533
  var valid_774534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-SignedHeaders", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Credential")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Credential", valid_774535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774536: Call_StopBulkDeployment_774525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_774536.validator(path, query, header, formData, body)
  let scheme = call_774536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774536.url(scheme.get, call_774536.host, call_774536.base,
                         call_774536.route, valid.getOrDefault("path"))
  result = hook(call_774536, url, valid)

proc call*(call_774537: Call_StopBulkDeployment_774525; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_774538 = newJObject()
  add(path_774538, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_774537.call(path_774538, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_774525(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_774526, base: "/",
    url: url_StopBulkDeployment_774527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774539 = ref object of OpenApiRestCall_772581
proc url_UntagResource_774541(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_774540(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774542 = path.getOrDefault("resource-arn")
  valid_774542 = validateParameter(valid_774542, JString, required = true,
                                 default = nil)
  if valid_774542 != nil:
    section.add "resource-arn", valid_774542
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_774543 = query.getOrDefault("tagKeys")
  valid_774543 = validateParameter(valid_774543, JArray, required = true, default = nil)
  if valid_774543 != nil:
    section.add "tagKeys", valid_774543
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
  var valid_774544 = header.getOrDefault("X-Amz-Date")
  valid_774544 = validateParameter(valid_774544, JString, required = false,
                                 default = nil)
  if valid_774544 != nil:
    section.add "X-Amz-Date", valid_774544
  var valid_774545 = header.getOrDefault("X-Amz-Security-Token")
  valid_774545 = validateParameter(valid_774545, JString, required = false,
                                 default = nil)
  if valid_774545 != nil:
    section.add "X-Amz-Security-Token", valid_774545
  var valid_774546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774546 = validateParameter(valid_774546, JString, required = false,
                                 default = nil)
  if valid_774546 != nil:
    section.add "X-Amz-Content-Sha256", valid_774546
  var valid_774547 = header.getOrDefault("X-Amz-Algorithm")
  valid_774547 = validateParameter(valid_774547, JString, required = false,
                                 default = nil)
  if valid_774547 != nil:
    section.add "X-Amz-Algorithm", valid_774547
  var valid_774548 = header.getOrDefault("X-Amz-Signature")
  valid_774548 = validateParameter(valid_774548, JString, required = false,
                                 default = nil)
  if valid_774548 != nil:
    section.add "X-Amz-Signature", valid_774548
  var valid_774549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774549 = validateParameter(valid_774549, JString, required = false,
                                 default = nil)
  if valid_774549 != nil:
    section.add "X-Amz-SignedHeaders", valid_774549
  var valid_774550 = header.getOrDefault("X-Amz-Credential")
  valid_774550 = validateParameter(valid_774550, JString, required = false,
                                 default = nil)
  if valid_774550 != nil:
    section.add "X-Amz-Credential", valid_774550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774551: Call_UntagResource_774539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_774551.validator(path, query, header, formData, body)
  let scheme = call_774551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774551.url(scheme.get, call_774551.host, call_774551.base,
                         call_774551.route, valid.getOrDefault("path"))
  result = hook(call_774551, url, valid)

proc call*(call_774552: Call_UntagResource_774539; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_774553 = newJObject()
  var query_774554 = newJObject()
  if tagKeys != nil:
    query_774554.add "tagKeys", tagKeys
  add(path_774553, "resource-arn", newJString(resourceArn))
  result = call_774552.call(path_774553, query_774554, nil, nil, nil)

var untagResource* = Call_UntagResource_774539(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_774540,
    base: "/", url: url_UntagResource_774541, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
