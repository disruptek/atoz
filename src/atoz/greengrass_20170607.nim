
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRoleToGroup_603057 = ref object of OpenApiRestCall_602450
proc url_AssociateRoleToGroup_603059(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_AssociateRoleToGroup_603058(path: JsonNode; query: JsonNode;
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
  var valid_603060 = path.getOrDefault("GroupId")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = nil)
  if valid_603060 != nil:
    section.add "GroupId", valid_603060
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
  var valid_603061 = header.getOrDefault("X-Amz-Date")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Date", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Security-Token")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Security-Token", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Content-Sha256", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Algorithm")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Algorithm", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Signature")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Signature", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-SignedHeaders", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Credential")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Credential", valid_603067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603069: Call_AssociateRoleToGroup_603057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_603069.validator(path, query, header, formData, body)
  let scheme = call_603069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603069.url(scheme.get, call_603069.host, call_603069.base,
                         call_603069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603069, url, valid)

proc call*(call_603070: Call_AssociateRoleToGroup_603057; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_603071 = newJObject()
  var body_603072 = newJObject()
  add(path_603071, "GroupId", newJString(GroupId))
  if body != nil:
    body_603072 = body
  result = call_603070.call(path_603071, nil, nil, nil, body_603072)

var associateRoleToGroup* = Call_AssociateRoleToGroup_603057(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_603058, base: "/",
    url: url_AssociateRoleToGroup_603059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_602787 = ref object of OpenApiRestCall_602450
proc url_GetAssociatedRole_602789(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetAssociatedRole_602788(path: JsonNode; query: JsonNode;
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
  var valid_602915 = path.getOrDefault("GroupId")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "GroupId", valid_602915
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
  var valid_602916 = header.getOrDefault("X-Amz-Date")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Date", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Security-Token")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Security-Token", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Content-Sha256", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Algorithm")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Algorithm", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Signature")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Signature", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-SignedHeaders", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Credential")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Credential", valid_602922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_GetAssociatedRole_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602945, url, valid)

proc call*(call_603016: Call_GetAssociatedRole_602787; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603017 = newJObject()
  add(path_603017, "GroupId", newJString(GroupId))
  result = call_603016.call(path_603017, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_602787(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_602788, base: "/",
    url: url_GetAssociatedRole_602789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_603073 = ref object of OpenApiRestCall_602450
proc url_DisassociateRoleFromGroup_603075(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DisassociateRoleFromGroup_603074(path: JsonNode; query: JsonNode;
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
  var valid_603076 = path.getOrDefault("GroupId")
  valid_603076 = validateParameter(valid_603076, JString, required = true,
                                 default = nil)
  if valid_603076 != nil:
    section.add "GroupId", valid_603076
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
  var valid_603077 = header.getOrDefault("X-Amz-Date")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Date", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Security-Token")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Security-Token", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Algorithm")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Algorithm", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Signature", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-SignedHeaders", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_DisassociateRoleFromGroup_603073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_DisassociateRoleFromGroup_603073; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603086 = newJObject()
  add(path_603086, "GroupId", newJString(GroupId))
  result = call_603085.call(path_603086, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_603073(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_603074, base: "/",
    url: url_DisassociateRoleFromGroup_603075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_603099 = ref object of OpenApiRestCall_602450
proc url_AssociateServiceRoleToAccount_603101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateServiceRoleToAccount_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Content-Sha256", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Signature")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Signature", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_AssociateServiceRoleToAccount_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_AssociateServiceRoleToAccount_603099; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_603112 = newJObject()
  if body != nil:
    body_603112 = body
  result = call_603111.call(nil, nil, nil, nil, body_603112)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_603099(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_603100, base: "/",
    url: url_AssociateServiceRoleToAccount_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_603087 = ref object of OpenApiRestCall_602450
proc url_GetServiceRoleForAccount_603089(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceRoleForAccount_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Content-Sha256", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Algorithm")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Algorithm", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-SignedHeaders", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_GetServiceRoleForAccount_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_GetServiceRoleForAccount_603087): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_603098.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_603087(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_603088, base: "/",
    url: url_GetServiceRoleForAccount_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_603113 = ref object of OpenApiRestCall_602450
proc url_DisassociateServiceRoleFromAccount_603115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_603114(path: JsonNode;
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
  var valid_603116 = header.getOrDefault("X-Amz-Date")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Date", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Security-Token")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Security-Token", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Content-Sha256", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Algorithm")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Algorithm", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Signature")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Signature", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-SignedHeaders", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Credential")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Credential", valid_603122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_DisassociateServiceRoleFromAccount_603113;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603123, url, valid)

proc call*(call_603124: Call_DisassociateServiceRoleFromAccount_603113): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_603124.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_603113(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_603114, base: "/",
    url: url_DisassociateServiceRoleFromAccount_603115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_603140 = ref object of OpenApiRestCall_602450
proc url_CreateConnectorDefinition_603142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnectorDefinition_603141(path: JsonNode; query: JsonNode;
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
  var valid_603143 = header.getOrDefault("X-Amz-Date")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Date", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Security-Token")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Security-Token", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Content-Sha256", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Algorithm")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Algorithm", valid_603146
  var valid_603147 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amzn-Client-Token", valid_603147
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

proc call*(call_603152: Call_CreateConnectorDefinition_603140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_603152.validator(path, query, header, formData, body)
  let scheme = call_603152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603152.url(scheme.get, call_603152.host, call_603152.base,
                         call_603152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603152, url, valid)

proc call*(call_603153: Call_CreateConnectorDefinition_603140; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_603154 = newJObject()
  if body != nil:
    body_603154 = body
  result = call_603153.call(nil, nil, nil, nil, body_603154)

var createConnectorDefinition* = Call_CreateConnectorDefinition_603140(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_603141, base: "/",
    url: url_CreateConnectorDefinition_603142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_603125 = ref object of OpenApiRestCall_602450
proc url_ListConnectorDefinitions_603127(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConnectorDefinitions_603126(path: JsonNode; query: JsonNode;
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
  var valid_603128 = query.getOrDefault("NextToken")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "NextToken", valid_603128
  var valid_603129 = query.getOrDefault("MaxResults")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "MaxResults", valid_603129
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
  var valid_603130 = header.getOrDefault("X-Amz-Date")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Date", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Security-Token")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Security-Token", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Content-Sha256", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Algorithm")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Algorithm", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-SignedHeaders", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603137: Call_ListConnectorDefinitions_603125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_603137.validator(path, query, header, formData, body)
  let scheme = call_603137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603137.url(scheme.get, call_603137.host, call_603137.base,
                         call_603137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603137, url, valid)

proc call*(call_603138: Call_ListConnectorDefinitions_603125;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603139 = newJObject()
  add(query_603139, "NextToken", newJString(NextToken))
  add(query_603139, "MaxResults", newJString(MaxResults))
  result = call_603138.call(nil, query_603139, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_603125(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_603126, base: "/",
    url: url_ListConnectorDefinitions_603127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_603172 = ref object of OpenApiRestCall_602450
proc url_CreateConnectorDefinitionVersion_603174(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateConnectorDefinitionVersion_603173(path: JsonNode;
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
  var valid_603175 = path.getOrDefault("ConnectorDefinitionId")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = nil)
  if valid_603175 != nil:
    section.add "ConnectorDefinitionId", valid_603175
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
  var valid_603176 = header.getOrDefault("X-Amz-Date")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Date", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Security-Token")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Security-Token", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Content-Sha256", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Algorithm")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Algorithm", valid_603179
  var valid_603180 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amzn-Client-Token", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Signature")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Signature", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-SignedHeaders", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Credential")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Credential", valid_603183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603185: Call_CreateConnectorDefinitionVersion_603172;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_603185.validator(path, query, header, formData, body)
  let scheme = call_603185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603185.url(scheme.get, call_603185.host, call_603185.base,
                         call_603185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603185, url, valid)

proc call*(call_603186: Call_CreateConnectorDefinitionVersion_603172;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_603187 = newJObject()
  var body_603188 = newJObject()
  add(path_603187, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_603188 = body
  result = call_603186.call(path_603187, nil, nil, nil, body_603188)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_603172(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_603173, base: "/",
    url: url_CreateConnectorDefinitionVersion_603174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_603155 = ref object of OpenApiRestCall_602450
proc url_ListConnectorDefinitionVersions_603157(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListConnectorDefinitionVersions_603156(path: JsonNode;
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
  var valid_603158 = path.getOrDefault("ConnectorDefinitionId")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "ConnectorDefinitionId", valid_603158
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603159 = query.getOrDefault("NextToken")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "NextToken", valid_603159
  var valid_603160 = query.getOrDefault("MaxResults")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "MaxResults", valid_603160
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
  var valid_603161 = header.getOrDefault("X-Amz-Date")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Date", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Security-Token")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Security-Token", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Content-Sha256", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Algorithm")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Algorithm", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Signature")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Signature", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-SignedHeaders", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Credential")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Credential", valid_603167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603168: Call_ListConnectorDefinitionVersions_603155;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_603168.validator(path, query, header, formData, body)
  let scheme = call_603168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603168.url(scheme.get, call_603168.host, call_603168.base,
                         call_603168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603168, url, valid)

proc call*(call_603169: Call_ListConnectorDefinitionVersions_603155;
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
  var path_603170 = newJObject()
  var query_603171 = newJObject()
  add(query_603171, "NextToken", newJString(NextToken))
  add(path_603170, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(query_603171, "MaxResults", newJString(MaxResults))
  result = call_603169.call(path_603170, query_603171, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_603155(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_603156, base: "/",
    url: url_ListConnectorDefinitionVersions_603157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_603204 = ref object of OpenApiRestCall_602450
proc url_CreateCoreDefinition_603206(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCoreDefinition_603205(path: JsonNode; query: JsonNode;
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
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Content-Sha256", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Algorithm")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Algorithm", valid_603210
  var valid_603211 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amzn-Client-Token", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_CreateCoreDefinition_603204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_CreateCoreDefinition_603204; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var createCoreDefinition* = Call_CreateCoreDefinition_603204(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_603205, base: "/",
    url: url_CreateCoreDefinition_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_603189 = ref object of OpenApiRestCall_602450
proc url_ListCoreDefinitions_603191(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCoreDefinitions_603190(path: JsonNode; query: JsonNode;
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
  var valid_603192 = query.getOrDefault("NextToken")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "NextToken", valid_603192
  var valid_603193 = query.getOrDefault("MaxResults")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "MaxResults", valid_603193
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
  var valid_603194 = header.getOrDefault("X-Amz-Date")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Date", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Security-Token")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Security-Token", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Content-Sha256", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Algorithm")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Algorithm", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Signature")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Signature", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-SignedHeaders", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Credential")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Credential", valid_603200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_ListCoreDefinitions_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_ListCoreDefinitions_603189; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603203 = newJObject()
  add(query_603203, "NextToken", newJString(NextToken))
  add(query_603203, "MaxResults", newJString(MaxResults))
  result = call_603202.call(nil, query_603203, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_603189(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_603190, base: "/",
    url: url_ListCoreDefinitions_603191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_603236 = ref object of OpenApiRestCall_602450
proc url_CreateCoreDefinitionVersion_603238(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateCoreDefinitionVersion_603237(path: JsonNode; query: JsonNode;
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
  var valid_603239 = path.getOrDefault("CoreDefinitionId")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = nil)
  if valid_603239 != nil:
    section.add "CoreDefinitionId", valid_603239
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Content-Sha256", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amzn-Client-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_CreateCoreDefinitionVersion_603236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_CreateCoreDefinitionVersion_603236;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_603251 = newJObject()
  var body_603252 = newJObject()
  add(path_603251, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_603252 = body
  result = call_603250.call(path_603251, nil, nil, nil, body_603252)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_603236(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_603237, base: "/",
    url: url_CreateCoreDefinitionVersion_603238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_603219 = ref object of OpenApiRestCall_602450
proc url_ListCoreDefinitionVersions_603221(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListCoreDefinitionVersions_603220(path: JsonNode; query: JsonNode;
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
  var valid_603222 = path.getOrDefault("CoreDefinitionId")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "CoreDefinitionId", valid_603222
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603223 = query.getOrDefault("NextToken")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "NextToken", valid_603223
  var valid_603224 = query.getOrDefault("MaxResults")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "MaxResults", valid_603224
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Content-Sha256", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Algorithm")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Algorithm", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Signature")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Signature", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-SignedHeaders", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Credential")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Credential", valid_603231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_ListCoreDefinitionVersions_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603232, url, valid)

proc call*(call_603233: Call_ListCoreDefinitionVersions_603219;
          CoreDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_603234 = newJObject()
  var query_603235 = newJObject()
  add(path_603234, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(query_603235, "NextToken", newJString(NextToken))
  add(query_603235, "MaxResults", newJString(MaxResults))
  result = call_603233.call(path_603234, query_603235, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_603219(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_603220, base: "/",
    url: url_ListCoreDefinitionVersions_603221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_603270 = ref object of OpenApiRestCall_602450
proc url_CreateDeployment_603272(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateDeployment_603271(path: JsonNode; query: JsonNode;
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
  var valid_603273 = path.getOrDefault("GroupId")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "GroupId", valid_603273
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
  var valid_603274 = header.getOrDefault("X-Amz-Date")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Date", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Security-Token")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Security-Token", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Content-Sha256", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Algorithm")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Algorithm", valid_603277
  var valid_603278 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amzn-Client-Token", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_CreateDeployment_603270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_CreateDeployment_603270; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_603285 = newJObject()
  var body_603286 = newJObject()
  add(path_603285, "GroupId", newJString(GroupId))
  if body != nil:
    body_603286 = body
  result = call_603284.call(path_603285, nil, nil, nil, body_603286)

var createDeployment* = Call_CreateDeployment_603270(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_603271, base: "/",
    url: url_CreateDeployment_603272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_603253 = ref object of OpenApiRestCall_602450
proc url_ListDeployments_603255(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListDeployments_603254(path: JsonNode; query: JsonNode;
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
  var valid_603256 = path.getOrDefault("GroupId")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = nil)
  if valid_603256 != nil:
    section.add "GroupId", valid_603256
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603257 = query.getOrDefault("NextToken")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "NextToken", valid_603257
  var valid_603258 = query.getOrDefault("MaxResults")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "MaxResults", valid_603258
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
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603266: Call_ListDeployments_603253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_603266.validator(path, query, header, formData, body)
  let scheme = call_603266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603266.url(scheme.get, call_603266.host, call_603266.base,
                         call_603266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603266, url, valid)

proc call*(call_603267: Call_ListDeployments_603253; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_603268 = newJObject()
  var query_603269 = newJObject()
  add(path_603268, "GroupId", newJString(GroupId))
  add(query_603269, "NextToken", newJString(NextToken))
  add(query_603269, "MaxResults", newJString(MaxResults))
  result = call_603267.call(path_603268, query_603269, nil, nil, nil)

var listDeployments* = Call_ListDeployments_603253(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_603254, base: "/", url: url_ListDeployments_603255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_603302 = ref object of OpenApiRestCall_602450
proc url_CreateDeviceDefinition_603304(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeviceDefinition_603303(path: JsonNode; query: JsonNode;
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
  var valid_603305 = header.getOrDefault("X-Amz-Date")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Date", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Security-Token")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Security-Token", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Content-Sha256", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Algorithm")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Algorithm", valid_603308
  var valid_603309 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amzn-Client-Token", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-SignedHeaders", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Credential")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Credential", valid_603312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603314: Call_CreateDeviceDefinition_603302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_603314.validator(path, query, header, formData, body)
  let scheme = call_603314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603314.url(scheme.get, call_603314.host, call_603314.base,
                         call_603314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603314, url, valid)

proc call*(call_603315: Call_CreateDeviceDefinition_603302; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_603316 = newJObject()
  if body != nil:
    body_603316 = body
  result = call_603315.call(nil, nil, nil, nil, body_603316)

var createDeviceDefinition* = Call_CreateDeviceDefinition_603302(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_603303, base: "/",
    url: url_CreateDeviceDefinition_603304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_603287 = ref object of OpenApiRestCall_602450
proc url_ListDeviceDefinitions_603289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceDefinitions_603288(path: JsonNode; query: JsonNode;
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
  var valid_603290 = query.getOrDefault("NextToken")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "NextToken", valid_603290
  var valid_603291 = query.getOrDefault("MaxResults")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "MaxResults", valid_603291
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
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Content-Sha256", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-SignedHeaders", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Credential")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Credential", valid_603298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603299: Call_ListDeviceDefinitions_603287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_603299.validator(path, query, header, formData, body)
  let scheme = call_603299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603299.url(scheme.get, call_603299.host, call_603299.base,
                         call_603299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603299, url, valid)

proc call*(call_603300: Call_ListDeviceDefinitions_603287; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603301 = newJObject()
  add(query_603301, "NextToken", newJString(NextToken))
  add(query_603301, "MaxResults", newJString(MaxResults))
  result = call_603300.call(nil, query_603301, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_603287(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_603288, base: "/",
    url: url_ListDeviceDefinitions_603289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_603334 = ref object of OpenApiRestCall_602450
proc url_CreateDeviceDefinitionVersion_603336(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateDeviceDefinitionVersion_603335(path: JsonNode; query: JsonNode;
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
  var valid_603337 = path.getOrDefault("DeviceDefinitionId")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = nil)
  if valid_603337 != nil:
    section.add "DeviceDefinitionId", valid_603337
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
  var valid_603338 = header.getOrDefault("X-Amz-Date")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Date", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Security-Token")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Security-Token", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Content-Sha256", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Algorithm")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Algorithm", valid_603341
  var valid_603342 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amzn-Client-Token", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Signature")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Signature", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-SignedHeaders", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Credential")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Credential", valid_603345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603347: Call_CreateDeviceDefinitionVersion_603334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_603347.validator(path, query, header, formData, body)
  let scheme = call_603347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603347.url(scheme.get, call_603347.host, call_603347.base,
                         call_603347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603347, url, valid)

proc call*(call_603348: Call_CreateDeviceDefinitionVersion_603334;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_603349 = newJObject()
  var body_603350 = newJObject()
  add(path_603349, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_603350 = body
  result = call_603348.call(path_603349, nil, nil, nil, body_603350)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_603334(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_603335, base: "/",
    url: url_CreateDeviceDefinitionVersion_603336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_603317 = ref object of OpenApiRestCall_602450
proc url_ListDeviceDefinitionVersions_603319(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListDeviceDefinitionVersions_603318(path: JsonNode; query: JsonNode;
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
  var valid_603320 = path.getOrDefault("DeviceDefinitionId")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "DeviceDefinitionId", valid_603320
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603321 = query.getOrDefault("NextToken")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "NextToken", valid_603321
  var valid_603322 = query.getOrDefault("MaxResults")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "MaxResults", valid_603322
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
  var valid_603323 = header.getOrDefault("X-Amz-Date")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Date", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Security-Token")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Security-Token", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Content-Sha256", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Algorithm")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Algorithm", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Signature")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Signature", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-SignedHeaders", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Credential")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Credential", valid_603329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603330: Call_ListDeviceDefinitionVersions_603317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_603330.validator(path, query, header, formData, body)
  let scheme = call_603330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603330.url(scheme.get, call_603330.host, call_603330.base,
                         call_603330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603330, url, valid)

proc call*(call_603331: Call_ListDeviceDefinitionVersions_603317;
          DeviceDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_603332 = newJObject()
  var query_603333 = newJObject()
  add(path_603332, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_603333, "NextToken", newJString(NextToken))
  add(query_603333, "MaxResults", newJString(MaxResults))
  result = call_603331.call(path_603332, query_603333, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_603317(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_603318, base: "/",
    url: url_ListDeviceDefinitionVersions_603319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_603366 = ref object of OpenApiRestCall_602450
proc url_CreateFunctionDefinition_603368(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFunctionDefinition_603367(path: JsonNode; query: JsonNode;
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
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Security-Token")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Security-Token", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Content-Sha256", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Algorithm")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Algorithm", valid_603372
  var valid_603373 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amzn-Client-Token", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Signature")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Signature", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-SignedHeaders", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_CreateFunctionDefinition_603366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_CreateFunctionDefinition_603366; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_603380 = newJObject()
  if body != nil:
    body_603380 = body
  result = call_603379.call(nil, nil, nil, nil, body_603380)

var createFunctionDefinition* = Call_CreateFunctionDefinition_603366(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_603367, base: "/",
    url: url_CreateFunctionDefinition_603368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_603351 = ref object of OpenApiRestCall_602450
proc url_ListFunctionDefinitions_603353(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctionDefinitions_603352(path: JsonNode; query: JsonNode;
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
  var valid_603354 = query.getOrDefault("NextToken")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "NextToken", valid_603354
  var valid_603355 = query.getOrDefault("MaxResults")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "MaxResults", valid_603355
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
  var valid_603356 = header.getOrDefault("X-Amz-Date")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Date", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Security-Token")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Security-Token", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Content-Sha256", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Algorithm")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Algorithm", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Signature")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Signature", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-SignedHeaders", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Credential")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Credential", valid_603362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603363: Call_ListFunctionDefinitions_603351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_ListFunctionDefinitions_603351;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603365 = newJObject()
  add(query_603365, "NextToken", newJString(NextToken))
  add(query_603365, "MaxResults", newJString(MaxResults))
  result = call_603364.call(nil, query_603365, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_603351(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_603352, base: "/",
    url: url_ListFunctionDefinitions_603353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_603398 = ref object of OpenApiRestCall_602450
proc url_CreateFunctionDefinitionVersion_603400(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateFunctionDefinitionVersion_603399(path: JsonNode;
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
  var valid_603401 = path.getOrDefault("FunctionDefinitionId")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = nil)
  if valid_603401 != nil:
    section.add "FunctionDefinitionId", valid_603401
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
  var valid_603402 = header.getOrDefault("X-Amz-Date")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Date", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Security-Token")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Security-Token", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Content-Sha256", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Algorithm")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Algorithm", valid_603405
  var valid_603406 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amzn-Client-Token", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Signature")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Signature", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Credential")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Credential", valid_603409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_CreateFunctionDefinitionVersion_603398;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603411, url, valid)

proc call*(call_603412: Call_CreateFunctionDefinitionVersion_603398;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_603413 = newJObject()
  var body_603414 = newJObject()
  add(path_603413, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_603414 = body
  result = call_603412.call(path_603413, nil, nil, nil, body_603414)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_603398(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_603399, base: "/",
    url: url_CreateFunctionDefinitionVersion_603400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_603381 = ref object of OpenApiRestCall_602450
proc url_ListFunctionDefinitionVersions_603383(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListFunctionDefinitionVersions_603382(path: JsonNode;
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
  var valid_603384 = path.getOrDefault("FunctionDefinitionId")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = nil)
  if valid_603384 != nil:
    section.add "FunctionDefinitionId", valid_603384
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603385 = query.getOrDefault("NextToken")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "NextToken", valid_603385
  var valid_603386 = query.getOrDefault("MaxResults")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "MaxResults", valid_603386
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
  var valid_603387 = header.getOrDefault("X-Amz-Date")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Date", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Security-Token")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Security-Token", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Content-Sha256", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Algorithm")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Algorithm", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Signature")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Signature", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-SignedHeaders", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Credential")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Credential", valid_603393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603394: Call_ListFunctionDefinitionVersions_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_603394.validator(path, query, header, formData, body)
  let scheme = call_603394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603394.url(scheme.get, call_603394.host, call_603394.base,
                         call_603394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603394, url, valid)

proc call*(call_603395: Call_ListFunctionDefinitionVersions_603381;
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
  var path_603396 = newJObject()
  var query_603397 = newJObject()
  add(query_603397, "NextToken", newJString(NextToken))
  add(path_603396, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  add(query_603397, "MaxResults", newJString(MaxResults))
  result = call_603395.call(path_603396, query_603397, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_603381(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_603382, base: "/",
    url: url_ListFunctionDefinitionVersions_603383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_603430 = ref object of OpenApiRestCall_602450
proc url_CreateGroup_603432(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGroup_603431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amzn-Client-Token", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_CreateGroup_603430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603442, url, valid)

proc call*(call_603443: Call_CreateGroup_603430; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_603444 = newJObject()
  if body != nil:
    body_603444 = body
  result = call_603443.call(nil, nil, nil, nil, body_603444)

var createGroup* = Call_CreateGroup_603430(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_603431,
                                        base: "/", url: url_CreateGroup_603432,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_603415 = ref object of OpenApiRestCall_602450
proc url_ListGroups_603417(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGroups_603416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603418 = query.getOrDefault("NextToken")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "NextToken", valid_603418
  var valid_603419 = query.getOrDefault("MaxResults")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "MaxResults", valid_603419
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
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Content-Sha256", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Algorithm")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Algorithm", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Signature")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Signature", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-SignedHeaders", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Credential")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Credential", valid_603426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603427: Call_ListGroups_603415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_603427.validator(path, query, header, formData, body)
  let scheme = call_603427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603427.url(scheme.get, call_603427.host, call_603427.base,
                         call_603427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603427, url, valid)

proc call*(call_603428: Call_ListGroups_603415; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603429 = newJObject()
  add(query_603429, "NextToken", newJString(NextToken))
  add(query_603429, "MaxResults", newJString(MaxResults))
  result = call_603428.call(nil, query_603429, nil, nil, nil)

var listGroups* = Call_ListGroups_603415(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_603416,
                                      base: "/", url: url_ListGroups_603417,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_603459 = ref object of OpenApiRestCall_602450
proc url_CreateGroupCertificateAuthority_603461(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateGroupCertificateAuthority_603460(path: JsonNode;
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
  var valid_603462 = path.getOrDefault("GroupId")
  valid_603462 = validateParameter(valid_603462, JString, required = true,
                                 default = nil)
  if valid_603462 != nil:
    section.add "GroupId", valid_603462
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
  var valid_603463 = header.getOrDefault("X-Amz-Date")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Date", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Security-Token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Security-Token", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Content-Sha256", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Algorithm")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Algorithm", valid_603466
  var valid_603467 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amzn-Client-Token", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Signature")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Signature", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-SignedHeaders", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Credential")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Credential", valid_603470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603471: Call_CreateGroupCertificateAuthority_603459;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_603471.validator(path, query, header, formData, body)
  let scheme = call_603471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603471.url(scheme.get, call_603471.host, call_603471.base,
                         call_603471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603471, url, valid)

proc call*(call_603472: Call_CreateGroupCertificateAuthority_603459;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603473 = newJObject()
  add(path_603473, "GroupId", newJString(GroupId))
  result = call_603472.call(path_603473, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_603459(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_603460, base: "/",
    url: url_CreateGroupCertificateAuthority_603461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_603445 = ref object of OpenApiRestCall_602450
proc url_ListGroupCertificateAuthorities_603447(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListGroupCertificateAuthorities_603446(path: JsonNode;
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
  var valid_603448 = path.getOrDefault("GroupId")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = nil)
  if valid_603448 != nil:
    section.add "GroupId", valid_603448
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
  var valid_603449 = header.getOrDefault("X-Amz-Date")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Date", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Security-Token")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Security-Token", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Content-Sha256", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Signature")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Signature", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-SignedHeaders", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Credential")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Credential", valid_603455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_ListGroupCertificateAuthorities_603445;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_ListGroupCertificateAuthorities_603445;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603458 = newJObject()
  add(path_603458, "GroupId", newJString(GroupId))
  result = call_603457.call(path_603458, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_603445(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_603446, base: "/",
    url: url_ListGroupCertificateAuthorities_603447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_603491 = ref object of OpenApiRestCall_602450
proc url_CreateGroupVersion_603493(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateGroupVersion_603492(path: JsonNode; query: JsonNode;
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
  var valid_603494 = path.getOrDefault("GroupId")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = nil)
  if valid_603494 != nil:
    section.add "GroupId", valid_603494
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
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Content-Sha256", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Algorithm")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Algorithm", valid_603498
  var valid_603499 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amzn-Client-Token", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_CreateGroupVersion_603491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_CreateGroupVersion_603491; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_603506 = newJObject()
  var body_603507 = newJObject()
  add(path_603506, "GroupId", newJString(GroupId))
  if body != nil:
    body_603507 = body
  result = call_603505.call(path_603506, nil, nil, nil, body_603507)

var createGroupVersion* = Call_CreateGroupVersion_603491(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_603492, base: "/",
    url: url_CreateGroupVersion_603493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_603474 = ref object of OpenApiRestCall_602450
proc url_ListGroupVersions_603476(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListGroupVersions_603475(path: JsonNode; query: JsonNode;
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
  var valid_603477 = path.getOrDefault("GroupId")
  valid_603477 = validateParameter(valid_603477, JString, required = true,
                                 default = nil)
  if valid_603477 != nil:
    section.add "GroupId", valid_603477
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603478 = query.getOrDefault("NextToken")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "NextToken", valid_603478
  var valid_603479 = query.getOrDefault("MaxResults")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "MaxResults", valid_603479
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
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Content-Sha256", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Algorithm")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Algorithm", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Signature")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Signature", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-SignedHeaders", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Credential")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Credential", valid_603486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603487: Call_ListGroupVersions_603474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_603487.validator(path, query, header, formData, body)
  let scheme = call_603487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603487.url(scheme.get, call_603487.host, call_603487.base,
                         call_603487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603487, url, valid)

proc call*(call_603488: Call_ListGroupVersions_603474; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_603489 = newJObject()
  var query_603490 = newJObject()
  add(path_603489, "GroupId", newJString(GroupId))
  add(query_603490, "NextToken", newJString(NextToken))
  add(query_603490, "MaxResults", newJString(MaxResults))
  result = call_603488.call(path_603489, query_603490, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_603474(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_603475, base: "/",
    url: url_ListGroupVersions_603476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_603523 = ref object of OpenApiRestCall_602450
proc url_CreateLoggerDefinition_603525(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLoggerDefinition_603524(path: JsonNode; query: JsonNode;
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
  var valid_603526 = header.getOrDefault("X-Amz-Date")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Date", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Security-Token")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Security-Token", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amzn-Client-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603535: Call_CreateLoggerDefinition_603523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_CreateLoggerDefinition_603523; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_603537 = newJObject()
  if body != nil:
    body_603537 = body
  result = call_603536.call(nil, nil, nil, nil, body_603537)

var createLoggerDefinition* = Call_CreateLoggerDefinition_603523(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_603524, base: "/",
    url: url_CreateLoggerDefinition_603525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_603508 = ref object of OpenApiRestCall_602450
proc url_ListLoggerDefinitions_603510(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLoggerDefinitions_603509(path: JsonNode; query: JsonNode;
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
  var valid_603511 = query.getOrDefault("NextToken")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "NextToken", valid_603511
  var valid_603512 = query.getOrDefault("MaxResults")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "MaxResults", valid_603512
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
  var valid_603513 = header.getOrDefault("X-Amz-Date")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Date", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Security-Token")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Security-Token", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Content-Sha256", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Algorithm")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Algorithm", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Signature")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Signature", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Credential")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Credential", valid_603519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603520: Call_ListLoggerDefinitions_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_603520.validator(path, query, header, formData, body)
  let scheme = call_603520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603520.url(scheme.get, call_603520.host, call_603520.base,
                         call_603520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603520, url, valid)

proc call*(call_603521: Call_ListLoggerDefinitions_603508; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603522 = newJObject()
  add(query_603522, "NextToken", newJString(NextToken))
  add(query_603522, "MaxResults", newJString(MaxResults))
  result = call_603521.call(nil, query_603522, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_603508(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_603509, base: "/",
    url: url_ListLoggerDefinitions_603510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_603555 = ref object of OpenApiRestCall_602450
proc url_CreateLoggerDefinitionVersion_603557(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateLoggerDefinitionVersion_603556(path: JsonNode; query: JsonNode;
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
  var valid_603558 = path.getOrDefault("LoggerDefinitionId")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = nil)
  if valid_603558 != nil:
    section.add "LoggerDefinitionId", valid_603558
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
  var valid_603559 = header.getOrDefault("X-Amz-Date")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Date", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Content-Sha256", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Algorithm")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Algorithm", valid_603562
  var valid_603563 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amzn-Client-Token", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_CreateLoggerDefinitionVersion_603555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_CreateLoggerDefinitionVersion_603555;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_603570 = newJObject()
  var body_603571 = newJObject()
  add(path_603570, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_603571 = body
  result = call_603569.call(path_603570, nil, nil, nil, body_603571)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_603555(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_603556, base: "/",
    url: url_CreateLoggerDefinitionVersion_603557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_603538 = ref object of OpenApiRestCall_602450
proc url_ListLoggerDefinitionVersions_603540(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListLoggerDefinitionVersions_603539(path: JsonNode; query: JsonNode;
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
  var valid_603541 = path.getOrDefault("LoggerDefinitionId")
  valid_603541 = validateParameter(valid_603541, JString, required = true,
                                 default = nil)
  if valid_603541 != nil:
    section.add "LoggerDefinitionId", valid_603541
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603542 = query.getOrDefault("NextToken")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "NextToken", valid_603542
  var valid_603543 = query.getOrDefault("MaxResults")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "MaxResults", valid_603543
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
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Algorithm")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Algorithm", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Signature")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Signature", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Credential")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Credential", valid_603550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603551: Call_ListLoggerDefinitionVersions_603538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_603551.validator(path, query, header, formData, body)
  let scheme = call_603551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603551.url(scheme.get, call_603551.host, call_603551.base,
                         call_603551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603551, url, valid)

proc call*(call_603552: Call_ListLoggerDefinitionVersions_603538;
          LoggerDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_603553 = newJObject()
  var query_603554 = newJObject()
  add(query_603554, "NextToken", newJString(NextToken))
  add(path_603553, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_603554, "MaxResults", newJString(MaxResults))
  result = call_603552.call(path_603553, query_603554, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_603538(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_603539, base: "/",
    url: url_ListLoggerDefinitionVersions_603540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_603587 = ref object of OpenApiRestCall_602450
proc url_CreateResourceDefinition_603589(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceDefinition_603588(path: JsonNode; query: JsonNode;
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
  var valid_603590 = header.getOrDefault("X-Amz-Date")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Date", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Security-Token")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Security-Token", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Content-Sha256", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Algorithm")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Algorithm", valid_603593
  var valid_603594 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amzn-Client-Token", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Signature")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Signature", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-SignedHeaders", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Credential")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Credential", valid_603597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603599: Call_CreateResourceDefinition_603587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_603599.validator(path, query, header, formData, body)
  let scheme = call_603599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603599.url(scheme.get, call_603599.host, call_603599.base,
                         call_603599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603599, url, valid)

proc call*(call_603600: Call_CreateResourceDefinition_603587; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_603601 = newJObject()
  if body != nil:
    body_603601 = body
  result = call_603600.call(nil, nil, nil, nil, body_603601)

var createResourceDefinition* = Call_CreateResourceDefinition_603587(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_603588, base: "/",
    url: url_CreateResourceDefinition_603589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_603572 = ref object of OpenApiRestCall_602450
proc url_ListResourceDefinitions_603574(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceDefinitions_603573(path: JsonNode; query: JsonNode;
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
  var valid_603575 = query.getOrDefault("NextToken")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "NextToken", valid_603575
  var valid_603576 = query.getOrDefault("MaxResults")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "MaxResults", valid_603576
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
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Content-Sha256", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Algorithm")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Algorithm", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Signature")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Signature", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-SignedHeaders", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Credential")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Credential", valid_603583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603584: Call_ListResourceDefinitions_603572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_603584.validator(path, query, header, formData, body)
  let scheme = call_603584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603584.url(scheme.get, call_603584.host, call_603584.base,
                         call_603584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603584, url, valid)

proc call*(call_603585: Call_ListResourceDefinitions_603572;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603586 = newJObject()
  add(query_603586, "NextToken", newJString(NextToken))
  add(query_603586, "MaxResults", newJString(MaxResults))
  result = call_603585.call(nil, query_603586, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_603572(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_603573, base: "/",
    url: url_ListResourceDefinitions_603574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_603619 = ref object of OpenApiRestCall_602450
proc url_CreateResourceDefinitionVersion_603621(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateResourceDefinitionVersion_603620(path: JsonNode;
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
  var valid_603622 = path.getOrDefault("ResourceDefinitionId")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = nil)
  if valid_603622 != nil:
    section.add "ResourceDefinitionId", valid_603622
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
  var valid_603623 = header.getOrDefault("X-Amz-Date")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Date", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Security-Token")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Security-Token", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amzn-Client-Token", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Signature")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Signature", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-SignedHeaders", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Credential")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Credential", valid_603630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603632: Call_CreateResourceDefinitionVersion_603619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_603632.validator(path, query, header, formData, body)
  let scheme = call_603632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603632.url(scheme.get, call_603632.host, call_603632.base,
                         call_603632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603632, url, valid)

proc call*(call_603633: Call_CreateResourceDefinitionVersion_603619;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_603634 = newJObject()
  var body_603635 = newJObject()
  add(path_603634, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_603635 = body
  result = call_603633.call(path_603634, nil, nil, nil, body_603635)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_603619(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_603620, base: "/",
    url: url_CreateResourceDefinitionVersion_603621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_603602 = ref object of OpenApiRestCall_602450
proc url_ListResourceDefinitionVersions_603604(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListResourceDefinitionVersions_603603(path: JsonNode;
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
  var valid_603605 = path.getOrDefault("ResourceDefinitionId")
  valid_603605 = validateParameter(valid_603605, JString, required = true,
                                 default = nil)
  if valid_603605 != nil:
    section.add "ResourceDefinitionId", valid_603605
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603606 = query.getOrDefault("NextToken")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "NextToken", valid_603606
  var valid_603607 = query.getOrDefault("MaxResults")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "MaxResults", valid_603607
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
  var valid_603608 = header.getOrDefault("X-Amz-Date")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Date", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Security-Token")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Security-Token", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Algorithm")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Algorithm", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Signature")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Signature", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-SignedHeaders", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Credential")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Credential", valid_603614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603615: Call_ListResourceDefinitionVersions_603602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_603615.validator(path, query, header, formData, body)
  let scheme = call_603615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603615.url(scheme.get, call_603615.host, call_603615.base,
                         call_603615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603615, url, valid)

proc call*(call_603616: Call_ListResourceDefinitionVersions_603602;
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
  var path_603617 = newJObject()
  var query_603618 = newJObject()
  add(query_603618, "NextToken", newJString(NextToken))
  add(path_603617, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  add(query_603618, "MaxResults", newJString(MaxResults))
  result = call_603616.call(path_603617, query_603618, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_603602(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_603603, base: "/",
    url: url_ListResourceDefinitionVersions_603604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_603636 = ref object of OpenApiRestCall_602450
proc url_CreateSoftwareUpdateJob_603638(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSoftwareUpdateJob_603637(path: JsonNode; query: JsonNode;
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
  var valid_603639 = header.getOrDefault("X-Amz-Date")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Date", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Security-Token")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Security-Token", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Content-Sha256", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Algorithm")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Algorithm", valid_603642
  var valid_603643 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amzn-Client-Token", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Signature")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Signature", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-SignedHeaders", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Credential")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Credential", valid_603646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_CreateSoftwareUpdateJob_603636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_CreateSoftwareUpdateJob_603636; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_603650 = newJObject()
  if body != nil:
    body_603650 = body
  result = call_603649.call(nil, nil, nil, nil, body_603650)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_603636(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_603637, base: "/",
    url: url_CreateSoftwareUpdateJob_603638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_603666 = ref object of OpenApiRestCall_602450
proc url_CreateSubscriptionDefinition_603668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSubscriptionDefinition_603667(path: JsonNode; query: JsonNode;
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
  var valid_603669 = header.getOrDefault("X-Amz-Date")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Date", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Security-Token")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Security-Token", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Content-Sha256", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Algorithm")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Algorithm", valid_603672
  var valid_603673 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amzn-Client-Token", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Signature")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Signature", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-SignedHeaders", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Credential")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Credential", valid_603676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603678: Call_CreateSubscriptionDefinition_603666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_603678.validator(path, query, header, formData, body)
  let scheme = call_603678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603678.url(scheme.get, call_603678.host, call_603678.base,
                         call_603678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603678, url, valid)

proc call*(call_603679: Call_CreateSubscriptionDefinition_603666; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_603680 = newJObject()
  if body != nil:
    body_603680 = body
  result = call_603679.call(nil, nil, nil, nil, body_603680)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_603666(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_603667, base: "/",
    url: url_CreateSubscriptionDefinition_603668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_603651 = ref object of OpenApiRestCall_602450
proc url_ListSubscriptionDefinitions_603653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscriptionDefinitions_603652(path: JsonNode; query: JsonNode;
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
  var valid_603654 = query.getOrDefault("NextToken")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "NextToken", valid_603654
  var valid_603655 = query.getOrDefault("MaxResults")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "MaxResults", valid_603655
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
  var valid_603656 = header.getOrDefault("X-Amz-Date")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Date", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Content-Sha256", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Algorithm")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Algorithm", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Signature")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Signature", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-SignedHeaders", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Credential")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Credential", valid_603662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603663: Call_ListSubscriptionDefinitions_603651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_603663.validator(path, query, header, formData, body)
  let scheme = call_603663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603663.url(scheme.get, call_603663.host, call_603663.base,
                         call_603663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603663, url, valid)

proc call*(call_603664: Call_ListSubscriptionDefinitions_603651;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_603665 = newJObject()
  add(query_603665, "NextToken", newJString(NextToken))
  add(query_603665, "MaxResults", newJString(MaxResults))
  result = call_603664.call(nil, query_603665, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_603651(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_603652, base: "/",
    url: url_ListSubscriptionDefinitions_603653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_603698 = ref object of OpenApiRestCall_602450
proc url_CreateSubscriptionDefinitionVersion_603700(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateSubscriptionDefinitionVersion_603699(path: JsonNode;
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
  var valid_603701 = path.getOrDefault("SubscriptionDefinitionId")
  valid_603701 = validateParameter(valid_603701, JString, required = true,
                                 default = nil)
  if valid_603701 != nil:
    section.add "SubscriptionDefinitionId", valid_603701
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
  var valid_603702 = header.getOrDefault("X-Amz-Date")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Date", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Security-Token")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Security-Token", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Content-Sha256", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Algorithm")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Algorithm", valid_603705
  var valid_603706 = header.getOrDefault("X-Amzn-Client-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amzn-Client-Token", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Signature")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Signature", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-SignedHeaders", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Credential")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Credential", valid_603709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603711: Call_CreateSubscriptionDefinitionVersion_603698;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_603711.validator(path, query, header, formData, body)
  let scheme = call_603711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603711.url(scheme.get, call_603711.host, call_603711.base,
                         call_603711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603711, url, valid)

proc call*(call_603712: Call_CreateSubscriptionDefinitionVersion_603698;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_603713 = newJObject()
  var body_603714 = newJObject()
  add(path_603713, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_603714 = body
  result = call_603712.call(path_603713, nil, nil, nil, body_603714)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_603698(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_603699, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_603700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_603681 = ref object of OpenApiRestCall_602450
proc url_ListSubscriptionDefinitionVersions_603683(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListSubscriptionDefinitionVersions_603682(path: JsonNode;
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
  var valid_603684 = path.getOrDefault("SubscriptionDefinitionId")
  valid_603684 = validateParameter(valid_603684, JString, required = true,
                                 default = nil)
  if valid_603684 != nil:
    section.add "SubscriptionDefinitionId", valid_603684
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_603685 = query.getOrDefault("NextToken")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "NextToken", valid_603685
  var valid_603686 = query.getOrDefault("MaxResults")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "MaxResults", valid_603686
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
  var valid_603687 = header.getOrDefault("X-Amz-Date")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Date", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Security-Token")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Security-Token", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Content-Sha256", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Algorithm")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Algorithm", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Signature")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Signature", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-SignedHeaders", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Credential")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Credential", valid_603693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603694: Call_ListSubscriptionDefinitionVersions_603681;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_603694.validator(path, query, header, formData, body)
  let scheme = call_603694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603694.url(scheme.get, call_603694.host, call_603694.base,
                         call_603694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603694, url, valid)

proc call*(call_603695: Call_ListSubscriptionDefinitionVersions_603681;
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
  var path_603696 = newJObject()
  var query_603697 = newJObject()
  add(query_603697, "NextToken", newJString(NextToken))
  add(path_603696, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(query_603697, "MaxResults", newJString(MaxResults))
  result = call_603695.call(path_603696, query_603697, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_603681(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_603682, base: "/",
    url: url_ListSubscriptionDefinitionVersions_603683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_603729 = ref object of OpenApiRestCall_602450
proc url_UpdateConnectorDefinition_603731(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateConnectorDefinition_603730(path: JsonNode; query: JsonNode;
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
  var valid_603732 = path.getOrDefault("ConnectorDefinitionId")
  valid_603732 = validateParameter(valid_603732, JString, required = true,
                                 default = nil)
  if valid_603732 != nil:
    section.add "ConnectorDefinitionId", valid_603732
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
  var valid_603733 = header.getOrDefault("X-Amz-Date")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Date", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Security-Token")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Security-Token", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Content-Sha256", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Algorithm")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Algorithm", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Signature")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Signature", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-SignedHeaders", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Credential")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Credential", valid_603739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603741: Call_UpdateConnectorDefinition_603729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_603741.validator(path, query, header, formData, body)
  let scheme = call_603741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603741.url(scheme.get, call_603741.host, call_603741.base,
                         call_603741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603741, url, valid)

proc call*(call_603742: Call_UpdateConnectorDefinition_603729;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_603743 = newJObject()
  var body_603744 = newJObject()
  add(path_603743, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_603744 = body
  result = call_603742.call(path_603743, nil, nil, nil, body_603744)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_603729(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_603730, base: "/",
    url: url_UpdateConnectorDefinition_603731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_603715 = ref object of OpenApiRestCall_602450
proc url_GetConnectorDefinition_603717(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetConnectorDefinition_603716(path: JsonNode; query: JsonNode;
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
  var valid_603718 = path.getOrDefault("ConnectorDefinitionId")
  valid_603718 = validateParameter(valid_603718, JString, required = true,
                                 default = nil)
  if valid_603718 != nil:
    section.add "ConnectorDefinitionId", valid_603718
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
  var valid_603719 = header.getOrDefault("X-Amz-Date")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Date", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Security-Token")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Security-Token", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Content-Sha256", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Algorithm")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Algorithm", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Signature")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Signature", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-SignedHeaders", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Credential")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Credential", valid_603725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603726: Call_GetConnectorDefinition_603715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_603726.validator(path, query, header, formData, body)
  let scheme = call_603726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603726.url(scheme.get, call_603726.host, call_603726.base,
                         call_603726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603726, url, valid)

proc call*(call_603727: Call_GetConnectorDefinition_603715;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_603728 = newJObject()
  add(path_603728, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_603727.call(path_603728, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_603715(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_603716, base: "/",
    url: url_GetConnectorDefinition_603717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_603745 = ref object of OpenApiRestCall_602450
proc url_DeleteConnectorDefinition_603747(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteConnectorDefinition_603746(path: JsonNode; query: JsonNode;
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
  var valid_603748 = path.getOrDefault("ConnectorDefinitionId")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = nil)
  if valid_603748 != nil:
    section.add "ConnectorDefinitionId", valid_603748
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
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Security-Token")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Security-Token", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_DeleteConnectorDefinition_603745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_DeleteConnectorDefinition_603745;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_603758 = newJObject()
  add(path_603758, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_603757.call(path_603758, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_603745(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_603746, base: "/",
    url: url_DeleteConnectorDefinition_603747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_603773 = ref object of OpenApiRestCall_602450
proc url_UpdateCoreDefinition_603775(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateCoreDefinition_603774(path: JsonNode; query: JsonNode;
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
  var valid_603776 = path.getOrDefault("CoreDefinitionId")
  valid_603776 = validateParameter(valid_603776, JString, required = true,
                                 default = nil)
  if valid_603776 != nil:
    section.add "CoreDefinitionId", valid_603776
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
  var valid_603777 = header.getOrDefault("X-Amz-Date")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Date", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Security-Token")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Security-Token", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Content-Sha256", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Algorithm")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Algorithm", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Signature")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Signature", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-SignedHeaders", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Credential")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Credential", valid_603783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603785: Call_UpdateCoreDefinition_603773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_603785.validator(path, query, header, formData, body)
  let scheme = call_603785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603785.url(scheme.get, call_603785.host, call_603785.base,
                         call_603785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603785, url, valid)

proc call*(call_603786: Call_UpdateCoreDefinition_603773; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_603787 = newJObject()
  var body_603788 = newJObject()
  add(path_603787, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_603788 = body
  result = call_603786.call(path_603787, nil, nil, nil, body_603788)

var updateCoreDefinition* = Call_UpdateCoreDefinition_603773(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_603774, base: "/",
    url: url_UpdateCoreDefinition_603775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_603759 = ref object of OpenApiRestCall_602450
proc url_GetCoreDefinition_603761(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCoreDefinition_603760(path: JsonNode; query: JsonNode;
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
  var valid_603762 = path.getOrDefault("CoreDefinitionId")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = nil)
  if valid_603762 != nil:
    section.add "CoreDefinitionId", valid_603762
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
  var valid_603763 = header.getOrDefault("X-Amz-Date")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Date", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Security-Token")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Security-Token", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Content-Sha256", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Algorithm")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Algorithm", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Signature")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Signature", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-SignedHeaders", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Credential")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Credential", valid_603769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603770: Call_GetCoreDefinition_603759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_603770.validator(path, query, header, formData, body)
  let scheme = call_603770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603770.url(scheme.get, call_603770.host, call_603770.base,
                         call_603770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603770, url, valid)

proc call*(call_603771: Call_GetCoreDefinition_603759; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_603772 = newJObject()
  add(path_603772, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_603771.call(path_603772, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_603759(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_603760, base: "/",
    url: url_GetCoreDefinition_603761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_603789 = ref object of OpenApiRestCall_602450
proc url_DeleteCoreDefinition_603791(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteCoreDefinition_603790(path: JsonNode; query: JsonNode;
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
  var valid_603792 = path.getOrDefault("CoreDefinitionId")
  valid_603792 = validateParameter(valid_603792, JString, required = true,
                                 default = nil)
  if valid_603792 != nil:
    section.add "CoreDefinitionId", valid_603792
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
  var valid_603793 = header.getOrDefault("X-Amz-Date")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Date", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Security-Token")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Security-Token", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Content-Sha256", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Algorithm")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Algorithm", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Signature")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Signature", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-SignedHeaders", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Credential")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Credential", valid_603799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603800: Call_DeleteCoreDefinition_603789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_603800.validator(path, query, header, formData, body)
  let scheme = call_603800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603800.url(scheme.get, call_603800.host, call_603800.base,
                         call_603800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603800, url, valid)

proc call*(call_603801: Call_DeleteCoreDefinition_603789; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_603802 = newJObject()
  add(path_603802, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_603801.call(path_603802, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_603789(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_603790, base: "/",
    url: url_DeleteCoreDefinition_603791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_603817 = ref object of OpenApiRestCall_602450
proc url_UpdateDeviceDefinition_603819(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDeviceDefinition_603818(path: JsonNode; query: JsonNode;
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
  var valid_603820 = path.getOrDefault("DeviceDefinitionId")
  valid_603820 = validateParameter(valid_603820, JString, required = true,
                                 default = nil)
  if valid_603820 != nil:
    section.add "DeviceDefinitionId", valid_603820
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
  var valid_603821 = header.getOrDefault("X-Amz-Date")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Date", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Security-Token")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Security-Token", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Content-Sha256", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Algorithm")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Algorithm", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Signature")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Signature", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-SignedHeaders", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Credential")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Credential", valid_603827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603829: Call_UpdateDeviceDefinition_603817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_603829.validator(path, query, header, formData, body)
  let scheme = call_603829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603829.url(scheme.get, call_603829.host, call_603829.base,
                         call_603829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603829, url, valid)

proc call*(call_603830: Call_UpdateDeviceDefinition_603817;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_603831 = newJObject()
  var body_603832 = newJObject()
  add(path_603831, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_603832 = body
  result = call_603830.call(path_603831, nil, nil, nil, body_603832)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_603817(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_603818, base: "/",
    url: url_UpdateDeviceDefinition_603819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_603803 = ref object of OpenApiRestCall_602450
proc url_GetDeviceDefinition_603805(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeviceDefinition_603804(path: JsonNode; query: JsonNode;
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
  var valid_603806 = path.getOrDefault("DeviceDefinitionId")
  valid_603806 = validateParameter(valid_603806, JString, required = true,
                                 default = nil)
  if valid_603806 != nil:
    section.add "DeviceDefinitionId", valid_603806
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
  var valid_603807 = header.getOrDefault("X-Amz-Date")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Date", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Security-Token")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Security-Token", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Content-Sha256", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Algorithm")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Algorithm", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Signature")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Signature", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-SignedHeaders", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Credential")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Credential", valid_603813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603814: Call_GetDeviceDefinition_603803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_603814.validator(path, query, header, formData, body)
  let scheme = call_603814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603814.url(scheme.get, call_603814.host, call_603814.base,
                         call_603814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603814, url, valid)

proc call*(call_603815: Call_GetDeviceDefinition_603803; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_603816 = newJObject()
  add(path_603816, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_603815.call(path_603816, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_603803(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_603804, base: "/",
    url: url_GetDeviceDefinition_603805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_603833 = ref object of OpenApiRestCall_602450
proc url_DeleteDeviceDefinition_603835(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDeviceDefinition_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = path.getOrDefault("DeviceDefinitionId")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = nil)
  if valid_603836 != nil:
    section.add "DeviceDefinitionId", valid_603836
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
  var valid_603837 = header.getOrDefault("X-Amz-Date")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Date", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Security-Token")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Security-Token", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Content-Sha256", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Algorithm")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Algorithm", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Signature")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Signature", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603844: Call_DeleteDeviceDefinition_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_603844.validator(path, query, header, formData, body)
  let scheme = call_603844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603844.url(scheme.get, call_603844.host, call_603844.base,
                         call_603844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603844, url, valid)

proc call*(call_603845: Call_DeleteDeviceDefinition_603833;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_603846 = newJObject()
  add(path_603846, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_603845.call(path_603846, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_603833(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_603834, base: "/",
    url: url_DeleteDeviceDefinition_603835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_603861 = ref object of OpenApiRestCall_602450
proc url_UpdateFunctionDefinition_603863(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFunctionDefinition_603862(path: JsonNode; query: JsonNode;
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
  var valid_603864 = path.getOrDefault("FunctionDefinitionId")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = nil)
  if valid_603864 != nil:
    section.add "FunctionDefinitionId", valid_603864
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
  var valid_603865 = header.getOrDefault("X-Amz-Date")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Date", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Security-Token")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Security-Token", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Content-Sha256", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Algorithm")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Algorithm", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Signature")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Signature", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-SignedHeaders", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Credential")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Credential", valid_603871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603873: Call_UpdateFunctionDefinition_603861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_603873.validator(path, query, header, formData, body)
  let scheme = call_603873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603873.url(scheme.get, call_603873.host, call_603873.base,
                         call_603873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603873, url, valid)

proc call*(call_603874: Call_UpdateFunctionDefinition_603861;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_603875 = newJObject()
  var body_603876 = newJObject()
  add(path_603875, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_603876 = body
  result = call_603874.call(path_603875, nil, nil, nil, body_603876)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_603861(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_603862, base: "/",
    url: url_UpdateFunctionDefinition_603863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_603847 = ref object of OpenApiRestCall_602450
proc url_GetFunctionDefinition_603849(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetFunctionDefinition_603848(path: JsonNode; query: JsonNode;
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
  var valid_603850 = path.getOrDefault("FunctionDefinitionId")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = nil)
  if valid_603850 != nil:
    section.add "FunctionDefinitionId", valid_603850
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
  var valid_603851 = header.getOrDefault("X-Amz-Date")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Date", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Security-Token")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Security-Token", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Content-Sha256", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Algorithm")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Algorithm", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-SignedHeaders", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Credential")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Credential", valid_603857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603858: Call_GetFunctionDefinition_603847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_603858.validator(path, query, header, formData, body)
  let scheme = call_603858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603858.url(scheme.get, call_603858.host, call_603858.base,
                         call_603858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603858, url, valid)

proc call*(call_603859: Call_GetFunctionDefinition_603847;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_603860 = newJObject()
  add(path_603860, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_603859.call(path_603860, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_603847(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_603848, base: "/",
    url: url_GetFunctionDefinition_603849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_603877 = ref object of OpenApiRestCall_602450
proc url_DeleteFunctionDefinition_603879(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteFunctionDefinition_603878(path: JsonNode; query: JsonNode;
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
  var valid_603880 = path.getOrDefault("FunctionDefinitionId")
  valid_603880 = validateParameter(valid_603880, JString, required = true,
                                 default = nil)
  if valid_603880 != nil:
    section.add "FunctionDefinitionId", valid_603880
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
  var valid_603881 = header.getOrDefault("X-Amz-Date")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Date", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Security-Token")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Security-Token", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Content-Sha256", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Algorithm")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Algorithm", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Signature")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Signature", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-SignedHeaders", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Credential")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Credential", valid_603887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603888: Call_DeleteFunctionDefinition_603877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_603888.validator(path, query, header, formData, body)
  let scheme = call_603888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603888.url(scheme.get, call_603888.host, call_603888.base,
                         call_603888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603888, url, valid)

proc call*(call_603889: Call_DeleteFunctionDefinition_603877;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_603890 = newJObject()
  add(path_603890, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_603889.call(path_603890, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_603877(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_603878, base: "/",
    url: url_DeleteFunctionDefinition_603879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_603905 = ref object of OpenApiRestCall_602450
proc url_UpdateGroup_603907(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateGroup_603906(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603908 = path.getOrDefault("GroupId")
  valid_603908 = validateParameter(valid_603908, JString, required = true,
                                 default = nil)
  if valid_603908 != nil:
    section.add "GroupId", valid_603908
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
  var valid_603909 = header.getOrDefault("X-Amz-Date")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Date", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Security-Token")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Security-Token", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Content-Sha256", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Algorithm")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Algorithm", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Signature")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Signature", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-SignedHeaders", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Credential")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Credential", valid_603915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603917: Call_UpdateGroup_603905; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_603917.validator(path, query, header, formData, body)
  let scheme = call_603917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603917.url(scheme.get, call_603917.host, call_603917.base,
                         call_603917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603917, url, valid)

proc call*(call_603918: Call_UpdateGroup_603905; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_603919 = newJObject()
  var body_603920 = newJObject()
  add(path_603919, "GroupId", newJString(GroupId))
  if body != nil:
    body_603920 = body
  result = call_603918.call(path_603919, nil, nil, nil, body_603920)

var updateGroup* = Call_UpdateGroup_603905(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_603906,
                                        base: "/", url: url_UpdateGroup_603907,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_603891 = ref object of OpenApiRestCall_602450
proc url_GetGroup_603893(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetGroup_603892(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603894 = path.getOrDefault("GroupId")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = nil)
  if valid_603894 != nil:
    section.add "GroupId", valid_603894
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
  var valid_603895 = header.getOrDefault("X-Amz-Date")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Date", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Content-Sha256", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Algorithm")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Algorithm", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Signature")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Signature", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-SignedHeaders", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Credential")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Credential", valid_603901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_GetGroup_603891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_GetGroup_603891; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603904 = newJObject()
  add(path_603904, "GroupId", newJString(GroupId))
  result = call_603903.call(path_603904, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_603891(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_603892, base: "/",
                                  url: url_GetGroup_603893,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_603921 = ref object of OpenApiRestCall_602450
proc url_DeleteGroup_603923(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteGroup_603922(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603924 = path.getOrDefault("GroupId")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = nil)
  if valid_603924 != nil:
    section.add "GroupId", valid_603924
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
  var valid_603925 = header.getOrDefault("X-Amz-Date")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Date", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Security-Token")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Security-Token", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Content-Sha256", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Algorithm")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Algorithm", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Signature")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Signature", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-SignedHeaders", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Credential")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Credential", valid_603931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603932: Call_DeleteGroup_603921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_603932.validator(path, query, header, formData, body)
  let scheme = call_603932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603932.url(scheme.get, call_603932.host, call_603932.base,
                         call_603932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603932, url, valid)

proc call*(call_603933: Call_DeleteGroup_603921; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_603934 = newJObject()
  add(path_603934, "GroupId", newJString(GroupId))
  result = call_603933.call(path_603934, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_603921(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_603922,
                                        base: "/", url: url_DeleteGroup_603923,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_603949 = ref object of OpenApiRestCall_602450
proc url_UpdateLoggerDefinition_603951(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateLoggerDefinition_603950(path: JsonNode; query: JsonNode;
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
  var valid_603952 = path.getOrDefault("LoggerDefinitionId")
  valid_603952 = validateParameter(valid_603952, JString, required = true,
                                 default = nil)
  if valid_603952 != nil:
    section.add "LoggerDefinitionId", valid_603952
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
  var valid_603953 = header.getOrDefault("X-Amz-Date")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Date", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Security-Token")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Security-Token", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Content-Sha256", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Algorithm")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Algorithm", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Signature")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Signature", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-SignedHeaders", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Credential")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Credential", valid_603959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603961: Call_UpdateLoggerDefinition_603949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_603961.validator(path, query, header, formData, body)
  let scheme = call_603961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603961.url(scheme.get, call_603961.host, call_603961.base,
                         call_603961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603961, url, valid)

proc call*(call_603962: Call_UpdateLoggerDefinition_603949;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_603963 = newJObject()
  var body_603964 = newJObject()
  add(path_603963, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_603964 = body
  result = call_603962.call(path_603963, nil, nil, nil, body_603964)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_603949(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_603950, base: "/",
    url: url_UpdateLoggerDefinition_603951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_603935 = ref object of OpenApiRestCall_602450
proc url_GetLoggerDefinition_603937(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetLoggerDefinition_603936(path: JsonNode; query: JsonNode;
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
  var valid_603938 = path.getOrDefault("LoggerDefinitionId")
  valid_603938 = validateParameter(valid_603938, JString, required = true,
                                 default = nil)
  if valid_603938 != nil:
    section.add "LoggerDefinitionId", valid_603938
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
  var valid_603939 = header.getOrDefault("X-Amz-Date")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Date", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Security-Token")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Security-Token", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Content-Sha256", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Algorithm")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Algorithm", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Signature")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Signature", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-SignedHeaders", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Credential")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Credential", valid_603945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603946: Call_GetLoggerDefinition_603935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_603946.validator(path, query, header, formData, body)
  let scheme = call_603946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603946.url(scheme.get, call_603946.host, call_603946.base,
                         call_603946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603946, url, valid)

proc call*(call_603947: Call_GetLoggerDefinition_603935; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_603948 = newJObject()
  add(path_603948, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_603947.call(path_603948, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_603935(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_603936, base: "/",
    url: url_GetLoggerDefinition_603937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_603965 = ref object of OpenApiRestCall_602450
proc url_DeleteLoggerDefinition_603967(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteLoggerDefinition_603966(path: JsonNode; query: JsonNode;
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
  var valid_603968 = path.getOrDefault("LoggerDefinitionId")
  valid_603968 = validateParameter(valid_603968, JString, required = true,
                                 default = nil)
  if valid_603968 != nil:
    section.add "LoggerDefinitionId", valid_603968
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
  var valid_603969 = header.getOrDefault("X-Amz-Date")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Date", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Security-Token")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Security-Token", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Content-Sha256", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Algorithm")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Algorithm", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Signature")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Signature", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-SignedHeaders", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Credential")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Credential", valid_603975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603976: Call_DeleteLoggerDefinition_603965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_603976.validator(path, query, header, formData, body)
  let scheme = call_603976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603976.url(scheme.get, call_603976.host, call_603976.base,
                         call_603976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603976, url, valid)

proc call*(call_603977: Call_DeleteLoggerDefinition_603965;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_603978 = newJObject()
  add(path_603978, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_603977.call(path_603978, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_603965(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_603966, base: "/",
    url: url_DeleteLoggerDefinition_603967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_603993 = ref object of OpenApiRestCall_602450
proc url_UpdateResourceDefinition_603995(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateResourceDefinition_603994(path: JsonNode; query: JsonNode;
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
  var valid_603996 = path.getOrDefault("ResourceDefinitionId")
  valid_603996 = validateParameter(valid_603996, JString, required = true,
                                 default = nil)
  if valid_603996 != nil:
    section.add "ResourceDefinitionId", valid_603996
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
  var valid_603997 = header.getOrDefault("X-Amz-Date")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Date", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Security-Token")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Security-Token", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Content-Sha256", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Algorithm")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Algorithm", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Signature")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Signature", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-SignedHeaders", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Credential")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Credential", valid_604003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604005: Call_UpdateResourceDefinition_603993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_604005.validator(path, query, header, formData, body)
  let scheme = call_604005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604005.url(scheme.get, call_604005.host, call_604005.base,
                         call_604005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604005, url, valid)

proc call*(call_604006: Call_UpdateResourceDefinition_603993;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_604007 = newJObject()
  var body_604008 = newJObject()
  add(path_604007, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_604008 = body
  result = call_604006.call(path_604007, nil, nil, nil, body_604008)

var updateResourceDefinition* = Call_UpdateResourceDefinition_603993(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_603994, base: "/",
    url: url_UpdateResourceDefinition_603995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_603979 = ref object of OpenApiRestCall_602450
proc url_GetResourceDefinition_603981(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetResourceDefinition_603980(path: JsonNode; query: JsonNode;
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
  var valid_603982 = path.getOrDefault("ResourceDefinitionId")
  valid_603982 = validateParameter(valid_603982, JString, required = true,
                                 default = nil)
  if valid_603982 != nil:
    section.add "ResourceDefinitionId", valid_603982
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
  var valid_603983 = header.getOrDefault("X-Amz-Date")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Date", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Security-Token")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Security-Token", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Content-Sha256", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Algorithm")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Algorithm", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Signature")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Signature", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-SignedHeaders", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Credential")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Credential", valid_603989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603990: Call_GetResourceDefinition_603979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_603990.validator(path, query, header, formData, body)
  let scheme = call_603990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603990.url(scheme.get, call_603990.host, call_603990.base,
                         call_603990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603990, url, valid)

proc call*(call_603991: Call_GetResourceDefinition_603979;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_603992 = newJObject()
  add(path_603992, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_603991.call(path_603992, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_603979(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_603980, base: "/",
    url: url_GetResourceDefinition_603981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_604009 = ref object of OpenApiRestCall_602450
proc url_DeleteResourceDefinition_604011(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteResourceDefinition_604010(path: JsonNode; query: JsonNode;
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
  var valid_604012 = path.getOrDefault("ResourceDefinitionId")
  valid_604012 = validateParameter(valid_604012, JString, required = true,
                                 default = nil)
  if valid_604012 != nil:
    section.add "ResourceDefinitionId", valid_604012
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
  var valid_604013 = header.getOrDefault("X-Amz-Date")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Date", valid_604013
  var valid_604014 = header.getOrDefault("X-Amz-Security-Token")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Security-Token", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Content-Sha256", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Algorithm")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Algorithm", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Signature")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Signature", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-SignedHeaders", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Credential")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Credential", valid_604019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604020: Call_DeleteResourceDefinition_604009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_604020.validator(path, query, header, formData, body)
  let scheme = call_604020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604020.url(scheme.get, call_604020.host, call_604020.base,
                         call_604020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604020, url, valid)

proc call*(call_604021: Call_DeleteResourceDefinition_604009;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_604022 = newJObject()
  add(path_604022, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_604021.call(path_604022, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_604009(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_604010, base: "/",
    url: url_DeleteResourceDefinition_604011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_604037 = ref object of OpenApiRestCall_602450
proc url_UpdateSubscriptionDefinition_604039(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateSubscriptionDefinition_604038(path: JsonNode; query: JsonNode;
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
  var valid_604040 = path.getOrDefault("SubscriptionDefinitionId")
  valid_604040 = validateParameter(valid_604040, JString, required = true,
                                 default = nil)
  if valid_604040 != nil:
    section.add "SubscriptionDefinitionId", valid_604040
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
  var valid_604041 = header.getOrDefault("X-Amz-Date")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Date", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Security-Token")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Security-Token", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Content-Sha256", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Algorithm")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Algorithm", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Signature")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Signature", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-SignedHeaders", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Credential")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Credential", valid_604047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604049: Call_UpdateSubscriptionDefinition_604037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_604049.validator(path, query, header, formData, body)
  let scheme = call_604049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604049.url(scheme.get, call_604049.host, call_604049.base,
                         call_604049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604049, url, valid)

proc call*(call_604050: Call_UpdateSubscriptionDefinition_604037;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_604051 = newJObject()
  var body_604052 = newJObject()
  add(path_604051, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_604052 = body
  result = call_604050.call(path_604051, nil, nil, nil, body_604052)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_604037(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_604038, base: "/",
    url: url_UpdateSubscriptionDefinition_604039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_604023 = ref object of OpenApiRestCall_602450
proc url_GetSubscriptionDefinition_604025(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetSubscriptionDefinition_604024(path: JsonNode; query: JsonNode;
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
  var valid_604026 = path.getOrDefault("SubscriptionDefinitionId")
  valid_604026 = validateParameter(valid_604026, JString, required = true,
                                 default = nil)
  if valid_604026 != nil:
    section.add "SubscriptionDefinitionId", valid_604026
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
  var valid_604027 = header.getOrDefault("X-Amz-Date")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Date", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Security-Token")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Security-Token", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Content-Sha256", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Algorithm")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Algorithm", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Signature")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Signature", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-SignedHeaders", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Credential")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Credential", valid_604033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604034: Call_GetSubscriptionDefinition_604023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_604034.validator(path, query, header, formData, body)
  let scheme = call_604034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604034.url(scheme.get, call_604034.host, call_604034.base,
                         call_604034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604034, url, valid)

proc call*(call_604035: Call_GetSubscriptionDefinition_604023;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_604036 = newJObject()
  add(path_604036, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_604035.call(path_604036, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_604023(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_604024, base: "/",
    url: url_GetSubscriptionDefinition_604025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_604053 = ref object of OpenApiRestCall_602450
proc url_DeleteSubscriptionDefinition_604055(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteSubscriptionDefinition_604054(path: JsonNode; query: JsonNode;
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
  var valid_604056 = path.getOrDefault("SubscriptionDefinitionId")
  valid_604056 = validateParameter(valid_604056, JString, required = true,
                                 default = nil)
  if valid_604056 != nil:
    section.add "SubscriptionDefinitionId", valid_604056
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
  var valid_604057 = header.getOrDefault("X-Amz-Date")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Date", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Security-Token")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Security-Token", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Content-Sha256", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Algorithm")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Algorithm", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Signature")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Signature", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-SignedHeaders", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Credential")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Credential", valid_604063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604064: Call_DeleteSubscriptionDefinition_604053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_604064.validator(path, query, header, formData, body)
  let scheme = call_604064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604064.url(scheme.get, call_604064.host, call_604064.base,
                         call_604064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604064, url, valid)

proc call*(call_604065: Call_DeleteSubscriptionDefinition_604053;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_604066 = newJObject()
  add(path_604066, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_604065.call(path_604066, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_604053(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_604054, base: "/",
    url: url_DeleteSubscriptionDefinition_604055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_604067 = ref object of OpenApiRestCall_602450
proc url_GetBulkDeploymentStatus_604069(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetBulkDeploymentStatus_604068(path: JsonNode; query: JsonNode;
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
  var valid_604070 = path.getOrDefault("BulkDeploymentId")
  valid_604070 = validateParameter(valid_604070, JString, required = true,
                                 default = nil)
  if valid_604070 != nil:
    section.add "BulkDeploymentId", valid_604070
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
  var valid_604071 = header.getOrDefault("X-Amz-Date")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Date", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Security-Token")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Security-Token", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Content-Sha256", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Algorithm")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Algorithm", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Signature")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Signature", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-SignedHeaders", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Credential")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Credential", valid_604077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604078: Call_GetBulkDeploymentStatus_604067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_604078.validator(path, query, header, formData, body)
  let scheme = call_604078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604078.url(scheme.get, call_604078.host, call_604078.base,
                         call_604078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604078, url, valid)

proc call*(call_604079: Call_GetBulkDeploymentStatus_604067;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_604080 = newJObject()
  add(path_604080, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_604079.call(path_604080, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_604067(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_604068, base: "/",
    url: url_GetBulkDeploymentStatus_604069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_604095 = ref object of OpenApiRestCall_602450
proc url_UpdateConnectivityInfo_604097(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateConnectivityInfo_604096(path: JsonNode; query: JsonNode;
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
  var valid_604098 = path.getOrDefault("ThingName")
  valid_604098 = validateParameter(valid_604098, JString, required = true,
                                 default = nil)
  if valid_604098 != nil:
    section.add "ThingName", valid_604098
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
  var valid_604099 = header.getOrDefault("X-Amz-Date")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Date", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Security-Token")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Security-Token", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Content-Sha256", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Algorithm")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Algorithm", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Signature")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Signature", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-SignedHeaders", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Credential")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Credential", valid_604105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604107: Call_UpdateConnectivityInfo_604095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_604107.validator(path, query, header, formData, body)
  let scheme = call_604107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604107.url(scheme.get, call_604107.host, call_604107.base,
                         call_604107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604107, url, valid)

proc call*(call_604108: Call_UpdateConnectivityInfo_604095; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_604109 = newJObject()
  var body_604110 = newJObject()
  add(path_604109, "ThingName", newJString(ThingName))
  if body != nil:
    body_604110 = body
  result = call_604108.call(path_604109, nil, nil, nil, body_604110)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_604095(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_604096, base: "/",
    url: url_UpdateConnectivityInfo_604097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_604081 = ref object of OpenApiRestCall_602450
proc url_GetConnectivityInfo_604083(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetConnectivityInfo_604082(path: JsonNode; query: JsonNode;
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
  var valid_604084 = path.getOrDefault("ThingName")
  valid_604084 = validateParameter(valid_604084, JString, required = true,
                                 default = nil)
  if valid_604084 != nil:
    section.add "ThingName", valid_604084
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
  var valid_604085 = header.getOrDefault("X-Amz-Date")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Date", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Security-Token")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Security-Token", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Content-Sha256", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Algorithm")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Algorithm", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Signature")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Signature", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-SignedHeaders", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Credential")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Credential", valid_604091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604092: Call_GetConnectivityInfo_604081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_604092.validator(path, query, header, formData, body)
  let scheme = call_604092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604092.url(scheme.get, call_604092.host, call_604092.base,
                         call_604092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604092, url, valid)

proc call*(call_604093: Call_GetConnectivityInfo_604081; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_604094 = newJObject()
  add(path_604094, "ThingName", newJString(ThingName))
  result = call_604093.call(path_604094, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_604081(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_604082, base: "/",
    url: url_GetConnectivityInfo_604083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_604111 = ref object of OpenApiRestCall_602450
proc url_GetConnectorDefinitionVersion_604113(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetConnectorDefinitionVersion_604112(path: JsonNode; query: JsonNode;
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
  var valid_604114 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_604114 = validateParameter(valid_604114, JString, required = true,
                                 default = nil)
  if valid_604114 != nil:
    section.add "ConnectorDefinitionVersionId", valid_604114
  var valid_604115 = path.getOrDefault("ConnectorDefinitionId")
  valid_604115 = validateParameter(valid_604115, JString, required = true,
                                 default = nil)
  if valid_604115 != nil:
    section.add "ConnectorDefinitionId", valid_604115
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_604116 = query.getOrDefault("NextToken")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "NextToken", valid_604116
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
  var valid_604117 = header.getOrDefault("X-Amz-Date")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Date", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Security-Token")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Security-Token", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Content-Sha256", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Algorithm")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Algorithm", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Signature")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Signature", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-SignedHeaders", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Credential")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Credential", valid_604123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604124: Call_GetConnectorDefinitionVersion_604111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_604124.validator(path, query, header, formData, body)
  let scheme = call_604124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604124.url(scheme.get, call_604124.host, call_604124.base,
                         call_604124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604124, url, valid)

proc call*(call_604125: Call_GetConnectorDefinitionVersion_604111;
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
  var path_604126 = newJObject()
  var query_604127 = newJObject()
  add(query_604127, "NextToken", newJString(NextToken))
  add(path_604126, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(path_604126, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_604125.call(path_604126, query_604127, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_604111(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_604112, base: "/",
    url: url_GetConnectorDefinitionVersion_604113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_604128 = ref object of OpenApiRestCall_602450
proc url_GetCoreDefinitionVersion_604130(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetCoreDefinitionVersion_604129(path: JsonNode; query: JsonNode;
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
  var valid_604131 = path.getOrDefault("CoreDefinitionId")
  valid_604131 = validateParameter(valid_604131, JString, required = true,
                                 default = nil)
  if valid_604131 != nil:
    section.add "CoreDefinitionId", valid_604131
  var valid_604132 = path.getOrDefault("CoreDefinitionVersionId")
  valid_604132 = validateParameter(valid_604132, JString, required = true,
                                 default = nil)
  if valid_604132 != nil:
    section.add "CoreDefinitionVersionId", valid_604132
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
  var valid_604133 = header.getOrDefault("X-Amz-Date")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Date", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Security-Token")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Security-Token", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Content-Sha256", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Algorithm")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Algorithm", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-Signature")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-Signature", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-SignedHeaders", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Credential")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Credential", valid_604139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604140: Call_GetCoreDefinitionVersion_604128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_604140.validator(path, query, header, formData, body)
  let scheme = call_604140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604140.url(scheme.get, call_604140.host, call_604140.base,
                         call_604140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604140, url, valid)

proc call*(call_604141: Call_GetCoreDefinitionVersion_604128;
          CoreDefinitionId: string; CoreDefinitionVersionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_604142 = newJObject()
  add(path_604142, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(path_604142, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  result = call_604141.call(path_604142, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_604128(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_604129, base: "/",
    url: url_GetCoreDefinitionVersion_604130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_604143 = ref object of OpenApiRestCall_602450
proc url_GetDeploymentStatus_604145(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeploymentStatus_604144(path: JsonNode; query: JsonNode;
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
  var valid_604146 = path.getOrDefault("GroupId")
  valid_604146 = validateParameter(valid_604146, JString, required = true,
                                 default = nil)
  if valid_604146 != nil:
    section.add "GroupId", valid_604146
  var valid_604147 = path.getOrDefault("DeploymentId")
  valid_604147 = validateParameter(valid_604147, JString, required = true,
                                 default = nil)
  if valid_604147 != nil:
    section.add "DeploymentId", valid_604147
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
  var valid_604148 = header.getOrDefault("X-Amz-Date")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Date", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Security-Token")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Security-Token", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Content-Sha256", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-Algorithm")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Algorithm", valid_604151
  var valid_604152 = header.getOrDefault("X-Amz-Signature")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Signature", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-SignedHeaders", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Credential")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Credential", valid_604154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604155: Call_GetDeploymentStatus_604143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_604155.validator(path, query, header, formData, body)
  let scheme = call_604155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604155.url(scheme.get, call_604155.host, call_604155.base,
                         call_604155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604155, url, valid)

proc call*(call_604156: Call_GetDeploymentStatus_604143; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_604157 = newJObject()
  add(path_604157, "GroupId", newJString(GroupId))
  add(path_604157, "DeploymentId", newJString(DeploymentId))
  result = call_604156.call(path_604157, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_604143(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_604144, base: "/",
    url: url_GetDeploymentStatus_604145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_604158 = ref object of OpenApiRestCall_602450
proc url_GetDeviceDefinitionVersion_604160(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetDeviceDefinitionVersion_604159(path: JsonNode; query: JsonNode;
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
  var valid_604161 = path.getOrDefault("DeviceDefinitionId")
  valid_604161 = validateParameter(valid_604161, JString, required = true,
                                 default = nil)
  if valid_604161 != nil:
    section.add "DeviceDefinitionId", valid_604161
  var valid_604162 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_604162 = validateParameter(valid_604162, JString, required = true,
                                 default = nil)
  if valid_604162 != nil:
    section.add "DeviceDefinitionVersionId", valid_604162
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_604163 = query.getOrDefault("NextToken")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "NextToken", valid_604163
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
  var valid_604164 = header.getOrDefault("X-Amz-Date")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Date", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Security-Token")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Security-Token", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Content-Sha256", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Algorithm")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Algorithm", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Signature")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Signature", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-SignedHeaders", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Credential")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Credential", valid_604170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604171: Call_GetDeviceDefinitionVersion_604158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_604171.validator(path, query, header, formData, body)
  let scheme = call_604171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604171.url(scheme.get, call_604171.host, call_604171.base,
                         call_604171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604171, url, valid)

proc call*(call_604172: Call_GetDeviceDefinitionVersion_604158;
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
  var path_604173 = newJObject()
  var query_604174 = newJObject()
  add(path_604173, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_604174, "NextToken", newJString(NextToken))
  add(path_604173, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_604172.call(path_604173, query_604174, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_604158(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_604159, base: "/",
    url: url_GetDeviceDefinitionVersion_604160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_604175 = ref object of OpenApiRestCall_602450
proc url_GetFunctionDefinitionVersion_604177(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetFunctionDefinitionVersion_604176(path: JsonNode; query: JsonNode;
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
  var valid_604178 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_604178 = validateParameter(valid_604178, JString, required = true,
                                 default = nil)
  if valid_604178 != nil:
    section.add "FunctionDefinitionVersionId", valid_604178
  var valid_604179 = path.getOrDefault("FunctionDefinitionId")
  valid_604179 = validateParameter(valid_604179, JString, required = true,
                                 default = nil)
  if valid_604179 != nil:
    section.add "FunctionDefinitionId", valid_604179
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_604180 = query.getOrDefault("NextToken")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "NextToken", valid_604180
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
  var valid_604181 = header.getOrDefault("X-Amz-Date")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Date", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Security-Token")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Security-Token", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Content-Sha256", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Algorithm")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Algorithm", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Signature")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Signature", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-SignedHeaders", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Credential")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Credential", valid_604187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604188: Call_GetFunctionDefinitionVersion_604175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_604188.validator(path, query, header, formData, body)
  let scheme = call_604188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604188.url(scheme.get, call_604188.host, call_604188.base,
                         call_604188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604188, url, valid)

proc call*(call_604189: Call_GetFunctionDefinitionVersion_604175;
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
  var path_604190 = newJObject()
  var query_604191 = newJObject()
  add(path_604190, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_604191, "NextToken", newJString(NextToken))
  add(path_604190, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_604189.call(path_604190, query_604191, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_604175(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_604176, base: "/",
    url: url_GetFunctionDefinitionVersion_604177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_604192 = ref object of OpenApiRestCall_602450
proc url_GetGroupCertificateAuthority_604194(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetGroupCertificateAuthority_604193(path: JsonNode; query: JsonNode;
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
  var valid_604195 = path.getOrDefault("GroupId")
  valid_604195 = validateParameter(valid_604195, JString, required = true,
                                 default = nil)
  if valid_604195 != nil:
    section.add "GroupId", valid_604195
  var valid_604196 = path.getOrDefault("CertificateAuthorityId")
  valid_604196 = validateParameter(valid_604196, JString, required = true,
                                 default = nil)
  if valid_604196 != nil:
    section.add "CertificateAuthorityId", valid_604196
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
  var valid_604197 = header.getOrDefault("X-Amz-Date")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Date", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Security-Token")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Security-Token", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Content-Sha256", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Algorithm")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Algorithm", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Signature")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Signature", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-SignedHeaders", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Credential")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Credential", valid_604203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604204: Call_GetGroupCertificateAuthority_604192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_604204.validator(path, query, header, formData, body)
  let scheme = call_604204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604204.url(scheme.get, call_604204.host, call_604204.base,
                         call_604204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604204, url, valid)

proc call*(call_604205: Call_GetGroupCertificateAuthority_604192; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_604206 = newJObject()
  add(path_604206, "GroupId", newJString(GroupId))
  add(path_604206, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_604205.call(path_604206, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_604192(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_604193, base: "/",
    url: url_GetGroupCertificateAuthority_604194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_604221 = ref object of OpenApiRestCall_602450
proc url_UpdateGroupCertificateConfiguration_604223(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateGroupCertificateConfiguration_604222(path: JsonNode;
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
  var valid_604224 = path.getOrDefault("GroupId")
  valid_604224 = validateParameter(valid_604224, JString, required = true,
                                 default = nil)
  if valid_604224 != nil:
    section.add "GroupId", valid_604224
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
  var valid_604225 = header.getOrDefault("X-Amz-Date")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Date", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Security-Token")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Security-Token", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Content-Sha256", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Algorithm")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Algorithm", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Signature")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Signature", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-SignedHeaders", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Credential")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Credential", valid_604231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604233: Call_UpdateGroupCertificateConfiguration_604221;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_604233.validator(path, query, header, formData, body)
  let scheme = call_604233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604233.url(scheme.get, call_604233.host, call_604233.base,
                         call_604233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604233, url, valid)

proc call*(call_604234: Call_UpdateGroupCertificateConfiguration_604221;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_604235 = newJObject()
  var body_604236 = newJObject()
  add(path_604235, "GroupId", newJString(GroupId))
  if body != nil:
    body_604236 = body
  result = call_604234.call(path_604235, nil, nil, nil, body_604236)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_604221(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_604222, base: "/",
    url: url_UpdateGroupCertificateConfiguration_604223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_604207 = ref object of OpenApiRestCall_602450
proc url_GetGroupCertificateConfiguration_604209(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetGroupCertificateConfiguration_604208(path: JsonNode;
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
  var valid_604210 = path.getOrDefault("GroupId")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = nil)
  if valid_604210 != nil:
    section.add "GroupId", valid_604210
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
  var valid_604211 = header.getOrDefault("X-Amz-Date")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Date", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Security-Token")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Security-Token", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Content-Sha256", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Algorithm")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Algorithm", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Signature")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Signature", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-SignedHeaders", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Credential")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Credential", valid_604217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604218: Call_GetGroupCertificateConfiguration_604207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_604218.validator(path, query, header, formData, body)
  let scheme = call_604218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604218.url(scheme.get, call_604218.host, call_604218.base,
                         call_604218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604218, url, valid)

proc call*(call_604219: Call_GetGroupCertificateConfiguration_604207;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_604220 = newJObject()
  add(path_604220, "GroupId", newJString(GroupId))
  result = call_604219.call(path_604220, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_604207(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_604208, base: "/",
    url: url_GetGroupCertificateConfiguration_604209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_604237 = ref object of OpenApiRestCall_602450
proc url_GetGroupVersion_604239(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetGroupVersion_604238(path: JsonNode; query: JsonNode;
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
  var valid_604240 = path.getOrDefault("GroupVersionId")
  valid_604240 = validateParameter(valid_604240, JString, required = true,
                                 default = nil)
  if valid_604240 != nil:
    section.add "GroupVersionId", valid_604240
  var valid_604241 = path.getOrDefault("GroupId")
  valid_604241 = validateParameter(valid_604241, JString, required = true,
                                 default = nil)
  if valid_604241 != nil:
    section.add "GroupId", valid_604241
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
  var valid_604242 = header.getOrDefault("X-Amz-Date")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Date", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-Security-Token")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Security-Token", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Content-Sha256", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Algorithm")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Algorithm", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Signature")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Signature", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-SignedHeaders", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Credential")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Credential", valid_604248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604249: Call_GetGroupVersion_604237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_604249.validator(path, query, header, formData, body)
  let scheme = call_604249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604249.url(scheme.get, call_604249.host, call_604249.base,
                         call_604249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604249, url, valid)

proc call*(call_604250: Call_GetGroupVersion_604237; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_604251 = newJObject()
  add(path_604251, "GroupVersionId", newJString(GroupVersionId))
  add(path_604251, "GroupId", newJString(GroupId))
  result = call_604250.call(path_604251, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_604237(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_604238, base: "/", url: url_GetGroupVersion_604239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_604252 = ref object of OpenApiRestCall_602450
proc url_GetLoggerDefinitionVersion_604254(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetLoggerDefinitionVersion_604253(path: JsonNode; query: JsonNode;
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
  var valid_604255 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_604255 = validateParameter(valid_604255, JString, required = true,
                                 default = nil)
  if valid_604255 != nil:
    section.add "LoggerDefinitionVersionId", valid_604255
  var valid_604256 = path.getOrDefault("LoggerDefinitionId")
  valid_604256 = validateParameter(valid_604256, JString, required = true,
                                 default = nil)
  if valid_604256 != nil:
    section.add "LoggerDefinitionId", valid_604256
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_604257 = query.getOrDefault("NextToken")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "NextToken", valid_604257
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
  var valid_604258 = header.getOrDefault("X-Amz-Date")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-Date", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Security-Token")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Security-Token", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Content-Sha256", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Algorithm")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Algorithm", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Signature")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Signature", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-SignedHeaders", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Credential")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Credential", valid_604264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604265: Call_GetLoggerDefinitionVersion_604252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_604265.validator(path, query, header, formData, body)
  let scheme = call_604265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604265.url(scheme.get, call_604265.host, call_604265.base,
                         call_604265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604265, url, valid)

proc call*(call_604266: Call_GetLoggerDefinitionVersion_604252;
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
  var path_604267 = newJObject()
  var query_604268 = newJObject()
  add(path_604267, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_604268, "NextToken", newJString(NextToken))
  add(path_604267, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_604266.call(path_604267, query_604268, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_604252(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_604253, base: "/",
    url: url_GetLoggerDefinitionVersion_604254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_604269 = ref object of OpenApiRestCall_602450
proc url_GetResourceDefinitionVersion_604271(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetResourceDefinitionVersion_604270(path: JsonNode; query: JsonNode;
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
  var valid_604272 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_604272 = validateParameter(valid_604272, JString, required = true,
                                 default = nil)
  if valid_604272 != nil:
    section.add "ResourceDefinitionVersionId", valid_604272
  var valid_604273 = path.getOrDefault("ResourceDefinitionId")
  valid_604273 = validateParameter(valid_604273, JString, required = true,
                                 default = nil)
  if valid_604273 != nil:
    section.add "ResourceDefinitionId", valid_604273
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
  var valid_604274 = header.getOrDefault("X-Amz-Date")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Date", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Security-Token")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Security-Token", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-Content-Sha256", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Algorithm")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Algorithm", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Signature")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Signature", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-SignedHeaders", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Credential")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Credential", valid_604280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604281: Call_GetResourceDefinitionVersion_604269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_604281.validator(path, query, header, formData, body)
  let scheme = call_604281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604281.url(scheme.get, call_604281.host, call_604281.base,
                         call_604281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604281, url, valid)

proc call*(call_604282: Call_GetResourceDefinitionVersion_604269;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_604283 = newJObject()
  add(path_604283, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_604283, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_604282.call(path_604283, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_604269(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_604270, base: "/",
    url: url_GetResourceDefinitionVersion_604271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_604284 = ref object of OpenApiRestCall_602450
proc url_GetSubscriptionDefinitionVersion_604286(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetSubscriptionDefinitionVersion_604285(path: JsonNode;
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
  var valid_604287 = path.getOrDefault("SubscriptionDefinitionId")
  valid_604287 = validateParameter(valid_604287, JString, required = true,
                                 default = nil)
  if valid_604287 != nil:
    section.add "SubscriptionDefinitionId", valid_604287
  var valid_604288 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_604288 = validateParameter(valid_604288, JString, required = true,
                                 default = nil)
  if valid_604288 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_604288
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_604289 = query.getOrDefault("NextToken")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "NextToken", valid_604289
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
  var valid_604290 = header.getOrDefault("X-Amz-Date")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Date", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-Security-Token")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-Security-Token", valid_604291
  var valid_604292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "X-Amz-Content-Sha256", valid_604292
  var valid_604293 = header.getOrDefault("X-Amz-Algorithm")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "X-Amz-Algorithm", valid_604293
  var valid_604294 = header.getOrDefault("X-Amz-Signature")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "X-Amz-Signature", valid_604294
  var valid_604295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "X-Amz-SignedHeaders", valid_604295
  var valid_604296 = header.getOrDefault("X-Amz-Credential")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Credential", valid_604296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604297: Call_GetSubscriptionDefinitionVersion_604284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_604297.validator(path, query, header, formData, body)
  let scheme = call_604297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604297.url(scheme.get, call_604297.host, call_604297.base,
                         call_604297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604297, url, valid)

proc call*(call_604298: Call_GetSubscriptionDefinitionVersion_604284;
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
  var path_604299 = newJObject()
  var query_604300 = newJObject()
  add(query_604300, "NextToken", newJString(NextToken))
  add(path_604299, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(path_604299, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  result = call_604298.call(path_604299, query_604300, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_604284(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_604285, base: "/",
    url: url_GetSubscriptionDefinitionVersion_604286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_604301 = ref object of OpenApiRestCall_602450
proc url_ListBulkDeploymentDetailedReports_604303(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListBulkDeploymentDetailedReports_604302(path: JsonNode;
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
  var valid_604304 = path.getOrDefault("BulkDeploymentId")
  valid_604304 = validateParameter(valid_604304, JString, required = true,
                                 default = nil)
  if valid_604304 != nil:
    section.add "BulkDeploymentId", valid_604304
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_604305 = query.getOrDefault("NextToken")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "NextToken", valid_604305
  var valid_604306 = query.getOrDefault("MaxResults")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "MaxResults", valid_604306
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
  var valid_604307 = header.getOrDefault("X-Amz-Date")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Date", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-Security-Token")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Security-Token", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Content-Sha256", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Algorithm")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Algorithm", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-Signature")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Signature", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-SignedHeaders", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Credential")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Credential", valid_604313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604314: Call_ListBulkDeploymentDetailedReports_604301;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_604314.validator(path, query, header, formData, body)
  let scheme = call_604314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604314.url(scheme.get, call_604314.host, call_604314.base,
                         call_604314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604314, url, valid)

proc call*(call_604315: Call_ListBulkDeploymentDetailedReports_604301;
          BulkDeploymentId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_604316 = newJObject()
  var query_604317 = newJObject()
  add(query_604317, "NextToken", newJString(NextToken))
  add(query_604317, "MaxResults", newJString(MaxResults))
  add(path_604316, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_604315.call(path_604316, query_604317, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_604301(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_604302, base: "/",
    url: url_ListBulkDeploymentDetailedReports_604303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_604333 = ref object of OpenApiRestCall_602450
proc url_StartBulkDeployment_604335(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBulkDeployment_604334(path: JsonNode; query: JsonNode;
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
  var valid_604336 = header.getOrDefault("X-Amz-Date")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-Date", valid_604336
  var valid_604337 = header.getOrDefault("X-Amz-Security-Token")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "X-Amz-Security-Token", valid_604337
  var valid_604338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "X-Amz-Content-Sha256", valid_604338
  var valid_604339 = header.getOrDefault("X-Amz-Algorithm")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Algorithm", valid_604339
  var valid_604340 = header.getOrDefault("X-Amzn-Client-Token")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amzn-Client-Token", valid_604340
  var valid_604341 = header.getOrDefault("X-Amz-Signature")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "X-Amz-Signature", valid_604341
  var valid_604342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-SignedHeaders", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Credential")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Credential", valid_604343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604345: Call_StartBulkDeployment_604333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_604345.validator(path, query, header, formData, body)
  let scheme = call_604345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604345.url(scheme.get, call_604345.host, call_604345.base,
                         call_604345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604345, url, valid)

proc call*(call_604346: Call_StartBulkDeployment_604333; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_604347 = newJObject()
  if body != nil:
    body_604347 = body
  result = call_604346.call(nil, nil, nil, nil, body_604347)

var startBulkDeployment* = Call_StartBulkDeployment_604333(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_604334, base: "/",
    url: url_StartBulkDeployment_604335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_604318 = ref object of OpenApiRestCall_602450
proc url_ListBulkDeployments_604320(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBulkDeployments_604319(path: JsonNode; query: JsonNode;
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
  var valid_604321 = query.getOrDefault("NextToken")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "NextToken", valid_604321
  var valid_604322 = query.getOrDefault("MaxResults")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "MaxResults", valid_604322
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
  var valid_604323 = header.getOrDefault("X-Amz-Date")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Date", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Security-Token")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Security-Token", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Content-Sha256", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-Algorithm")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-Algorithm", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Signature")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Signature", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-SignedHeaders", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-Credential")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Credential", valid_604329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604330: Call_ListBulkDeployments_604318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_604330.validator(path, query, header, formData, body)
  let scheme = call_604330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604330.url(scheme.get, call_604330.host, call_604330.base,
                         call_604330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604330, url, valid)

proc call*(call_604331: Call_ListBulkDeployments_604318; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_604332 = newJObject()
  add(query_604332, "NextToken", newJString(NextToken))
  add(query_604332, "MaxResults", newJString(MaxResults))
  result = call_604331.call(nil, query_604332, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_604318(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_604319, base: "/",
    url: url_ListBulkDeployments_604320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604362 = ref object of OpenApiRestCall_602450
proc url_TagResource_604364(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_604363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604365 = path.getOrDefault("resource-arn")
  valid_604365 = validateParameter(valid_604365, JString, required = true,
                                 default = nil)
  if valid_604365 != nil:
    section.add "resource-arn", valid_604365
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
  var valid_604366 = header.getOrDefault("X-Amz-Date")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-Date", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Security-Token")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Security-Token", valid_604367
  var valid_604368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Content-Sha256", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Algorithm")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Algorithm", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Signature")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Signature", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-SignedHeaders", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Credential")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Credential", valid_604372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604374: Call_TagResource_604362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_604374.validator(path, query, header, formData, body)
  let scheme = call_604374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604374.url(scheme.get, call_604374.host, call_604374.base,
                         call_604374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604374, url, valid)

proc call*(call_604375: Call_TagResource_604362; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_604376 = newJObject()
  var body_604377 = newJObject()
  add(path_604376, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_604377 = body
  result = call_604375.call(path_604376, nil, nil, nil, body_604377)

var tagResource* = Call_TagResource_604362(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_604363,
                                        base: "/", url: url_TagResource_604364,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_604348 = ref object of OpenApiRestCall_602450
proc url_ListTagsForResource_604350(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_604349(path: JsonNode; query: JsonNode;
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
  var valid_604351 = path.getOrDefault("resource-arn")
  valid_604351 = validateParameter(valid_604351, JString, required = true,
                                 default = nil)
  if valid_604351 != nil:
    section.add "resource-arn", valid_604351
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
  var valid_604352 = header.getOrDefault("X-Amz-Date")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Date", valid_604352
  var valid_604353 = header.getOrDefault("X-Amz-Security-Token")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Security-Token", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Content-Sha256", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Algorithm")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Algorithm", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Signature")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Signature", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-SignedHeaders", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Credential")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Credential", valid_604358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604359: Call_ListTagsForResource_604348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_604359.validator(path, query, header, formData, body)
  let scheme = call_604359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604359.url(scheme.get, call_604359.host, call_604359.base,
                         call_604359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604359, url, valid)

proc call*(call_604360: Call_ListTagsForResource_604348; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_604361 = newJObject()
  add(path_604361, "resource-arn", newJString(resourceArn))
  result = call_604360.call(path_604361, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_604348(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_604349, base: "/",
    url: url_ListTagsForResource_604350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_604378 = ref object of OpenApiRestCall_602450
proc url_ResetDeployments_604380(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ResetDeployments_604379(path: JsonNode; query: JsonNode;
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
  var valid_604381 = path.getOrDefault("GroupId")
  valid_604381 = validateParameter(valid_604381, JString, required = true,
                                 default = nil)
  if valid_604381 != nil:
    section.add "GroupId", valid_604381
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
  var valid_604382 = header.getOrDefault("X-Amz-Date")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-Date", valid_604382
  var valid_604383 = header.getOrDefault("X-Amz-Security-Token")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "X-Amz-Security-Token", valid_604383
  var valid_604384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "X-Amz-Content-Sha256", valid_604384
  var valid_604385 = header.getOrDefault("X-Amz-Algorithm")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "X-Amz-Algorithm", valid_604385
  var valid_604386 = header.getOrDefault("X-Amzn-Client-Token")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amzn-Client-Token", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Signature")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Signature", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-SignedHeaders", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Credential")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Credential", valid_604389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604391: Call_ResetDeployments_604378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_604391.validator(path, query, header, formData, body)
  let scheme = call_604391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604391.url(scheme.get, call_604391.host, call_604391.base,
                         call_604391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604391, url, valid)

proc call*(call_604392: Call_ResetDeployments_604378; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_604393 = newJObject()
  var body_604394 = newJObject()
  add(path_604393, "GroupId", newJString(GroupId))
  if body != nil:
    body_604394 = body
  result = call_604392.call(path_604393, nil, nil, nil, body_604394)

var resetDeployments* = Call_ResetDeployments_604378(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_604379, base: "/",
    url: url_ResetDeployments_604380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_604395 = ref object of OpenApiRestCall_602450
proc url_StopBulkDeployment_604397(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_StopBulkDeployment_604396(path: JsonNode; query: JsonNode;
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
  var valid_604398 = path.getOrDefault("BulkDeploymentId")
  valid_604398 = validateParameter(valid_604398, JString, required = true,
                                 default = nil)
  if valid_604398 != nil:
    section.add "BulkDeploymentId", valid_604398
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
  var valid_604399 = header.getOrDefault("X-Amz-Date")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-Date", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Security-Token")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Security-Token", valid_604400
  var valid_604401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Content-Sha256", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Algorithm")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Algorithm", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Signature")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Signature", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-SignedHeaders", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Credential")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Credential", valid_604405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604406: Call_StopBulkDeployment_604395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_604406.validator(path, query, header, formData, body)
  let scheme = call_604406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604406.url(scheme.get, call_604406.host, call_604406.base,
                         call_604406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604406, url, valid)

proc call*(call_604407: Call_StopBulkDeployment_604395; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_604408 = newJObject()
  add(path_604408, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_604407.call(path_604408, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_604395(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_604396, base: "/",
    url: url_StopBulkDeployment_604397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604409 = ref object of OpenApiRestCall_602450
proc url_UntagResource_604411(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_604410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604412 = path.getOrDefault("resource-arn")
  valid_604412 = validateParameter(valid_604412, JString, required = true,
                                 default = nil)
  if valid_604412 != nil:
    section.add "resource-arn", valid_604412
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_604413 = query.getOrDefault("tagKeys")
  valid_604413 = validateParameter(valid_604413, JArray, required = true, default = nil)
  if valid_604413 != nil:
    section.add "tagKeys", valid_604413
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
  var valid_604414 = header.getOrDefault("X-Amz-Date")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Date", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-Security-Token")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-Security-Token", valid_604415
  var valid_604416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-Content-Sha256", valid_604416
  var valid_604417 = header.getOrDefault("X-Amz-Algorithm")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Algorithm", valid_604417
  var valid_604418 = header.getOrDefault("X-Amz-Signature")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "X-Amz-Signature", valid_604418
  var valid_604419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "X-Amz-SignedHeaders", valid_604419
  var valid_604420 = header.getOrDefault("X-Amz-Credential")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Credential", valid_604420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604421: Call_UntagResource_604409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_604421.validator(path, query, header, formData, body)
  let scheme = call_604421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604421.url(scheme.get, call_604421.host, call_604421.base,
                         call_604421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604421, url, valid)

proc call*(call_604422: Call_UntagResource_604409; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_604423 = newJObject()
  var query_604424 = newJObject()
  if tagKeys != nil:
    query_604424.add "tagKeys", tagKeys
  add(path_604423, "resource-arn", newJString(resourceArn))
  result = call_604422.call(path_604423, query_604424, nil, nil, nil)

var untagResource* = Call_UntagResource_604409(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_604410,
    base: "/", url: url_UntagResource_604411, schemes: {Scheme.Https, Scheme.Http})
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
