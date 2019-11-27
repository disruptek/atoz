
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_AssociateRoleToGroup_599959 = ref object of OpenApiRestCall_599352
proc url_AssociateRoleToGroup_599961(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRoleToGroup_599960(path: JsonNode; query: JsonNode;
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
  var valid_599962 = path.getOrDefault("GroupId")
  valid_599962 = validateParameter(valid_599962, JString, required = true,
                                 default = nil)
  if valid_599962 != nil:
    section.add "GroupId", valid_599962
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
  var valid_599963 = header.getOrDefault("X-Amz-Date")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Date", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Security-Token")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Security-Token", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Content-Sha256", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Algorithm")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Algorithm", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Signature")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Signature", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-SignedHeaders", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Credential")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Credential", valid_599969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599971: Call_AssociateRoleToGroup_599959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_599971.validator(path, query, header, formData, body)
  let scheme = call_599971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599971.url(scheme.get, call_599971.host, call_599971.base,
                         call_599971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599971, url, valid)

proc call*(call_599972: Call_AssociateRoleToGroup_599959; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_599973 = newJObject()
  var body_599974 = newJObject()
  add(path_599973, "GroupId", newJString(GroupId))
  if body != nil:
    body_599974 = body
  result = call_599972.call(path_599973, nil, nil, nil, body_599974)

var associateRoleToGroup* = Call_AssociateRoleToGroup_599959(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_599960, base: "/",
    url: url_AssociateRoleToGroup_599961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_599689 = ref object of OpenApiRestCall_599352
proc url_GetAssociatedRole_599691(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssociatedRole_599690(path: JsonNode; query: JsonNode;
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
  var valid_599817 = path.getOrDefault("GroupId")
  valid_599817 = validateParameter(valid_599817, JString, required = true,
                                 default = nil)
  if valid_599817 != nil:
    section.add "GroupId", valid_599817
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
  var valid_599818 = header.getOrDefault("X-Amz-Date")
  valid_599818 = validateParameter(valid_599818, JString, required = false,
                                 default = nil)
  if valid_599818 != nil:
    section.add "X-Amz-Date", valid_599818
  var valid_599819 = header.getOrDefault("X-Amz-Security-Token")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Security-Token", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Content-Sha256", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Algorithm")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Algorithm", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Signature")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Signature", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-SignedHeaders", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Credential")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Credential", valid_599824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599847: Call_GetAssociatedRole_599689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_599847.validator(path, query, header, formData, body)
  let scheme = call_599847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599847.url(scheme.get, call_599847.host, call_599847.base,
                         call_599847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599847, url, valid)

proc call*(call_599918: Call_GetAssociatedRole_599689; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_599919 = newJObject()
  add(path_599919, "GroupId", newJString(GroupId))
  result = call_599918.call(path_599919, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_599689(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_599690, base: "/",
    url: url_GetAssociatedRole_599691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_599975 = ref object of OpenApiRestCall_599352
proc url_DisassociateRoleFromGroup_599977(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_599976(path: JsonNode; query: JsonNode;
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
  var valid_599978 = path.getOrDefault("GroupId")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "GroupId", valid_599978
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
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_DisassociateRoleFromGroup_599975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_DisassociateRoleFromGroup_599975; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_599988 = newJObject()
  add(path_599988, "GroupId", newJString(GroupId))
  result = call_599987.call(path_599988, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_599975(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_599976, base: "/",
    url: url_DisassociateRoleFromGroup_599977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_600001 = ref object of OpenApiRestCall_599352
proc url_AssociateServiceRoleToAccount_600003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceRoleToAccount_600002(path: JsonNode; query: JsonNode;
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
  var valid_600004 = header.getOrDefault("X-Amz-Date")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Date", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Security-Token")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Security-Token", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Content-Sha256", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Algorithm")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Algorithm", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Signature")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Signature", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-SignedHeaders", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Credential")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Credential", valid_600010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600012: Call_AssociateServiceRoleToAccount_600001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_600012.validator(path, query, header, formData, body)
  let scheme = call_600012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600012.url(scheme.get, call_600012.host, call_600012.base,
                         call_600012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600012, url, valid)

proc call*(call_600013: Call_AssociateServiceRoleToAccount_600001; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_600014 = newJObject()
  if body != nil:
    body_600014 = body
  result = call_600013.call(nil, nil, nil, nil, body_600014)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_600001(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_600002, base: "/",
    url: url_AssociateServiceRoleToAccount_600003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_599989 = ref object of OpenApiRestCall_599352
proc url_GetServiceRoleForAccount_599991(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceRoleForAccount_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Content-Sha256", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Algorithm")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Algorithm", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Signature")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Signature", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-SignedHeaders", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Credential")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Credential", valid_599998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599999: Call_GetServiceRoleForAccount_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_599999.validator(path, query, header, formData, body)
  let scheme = call_599999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599999.url(scheme.get, call_599999.host, call_599999.base,
                         call_599999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599999, url, valid)

proc call*(call_600000: Call_GetServiceRoleForAccount_599989): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_600000.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_599989(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_599990, base: "/",
    url: url_GetServiceRoleForAccount_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_600015 = ref object of OpenApiRestCall_599352
proc url_DisassociateServiceRoleFromAccount_600017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_600016(path: JsonNode;
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
  var valid_600018 = header.getOrDefault("X-Amz-Date")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Date", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Security-Token")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Security-Token", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Content-Sha256", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Algorithm")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Algorithm", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Signature")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Signature", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-SignedHeaders", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Credential")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Credential", valid_600024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600025: Call_DisassociateServiceRoleFromAccount_600015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_600025.validator(path, query, header, formData, body)
  let scheme = call_600025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600025.url(scheme.get, call_600025.host, call_600025.base,
                         call_600025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600025, url, valid)

proc call*(call_600026: Call_DisassociateServiceRoleFromAccount_600015): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_600026.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_600015(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_600016, base: "/",
    url: url_DisassociateServiceRoleFromAccount_600017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_600042 = ref object of OpenApiRestCall_599352
proc url_CreateConnectorDefinition_600044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnectorDefinition_600043(path: JsonNode; query: JsonNode;
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
  var valid_600045 = header.getOrDefault("X-Amz-Date")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Date", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Security-Token")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Security-Token", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Content-Sha256", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Algorithm")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Algorithm", valid_600048
  var valid_600049 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amzn-Client-Token", valid_600049
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

proc call*(call_600054: Call_CreateConnectorDefinition_600042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_CreateConnectorDefinition_600042; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_600056 = newJObject()
  if body != nil:
    body_600056 = body
  result = call_600055.call(nil, nil, nil, nil, body_600056)

var createConnectorDefinition* = Call_CreateConnectorDefinition_600042(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_600043, base: "/",
    url: url_CreateConnectorDefinition_600044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_600027 = ref object of OpenApiRestCall_599352
proc url_ListConnectorDefinitions_600029(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConnectorDefinitions_600028(path: JsonNode; query: JsonNode;
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
  var valid_600030 = query.getOrDefault("NextToken")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "NextToken", valid_600030
  var valid_600031 = query.getOrDefault("MaxResults")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "MaxResults", valid_600031
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
  var valid_600032 = header.getOrDefault("X-Amz-Date")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Date", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Security-Token")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Security-Token", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Content-Sha256", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Algorithm")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Algorithm", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Signature")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Signature", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-SignedHeaders", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Credential")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Credential", valid_600038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_ListConnectorDefinitions_600027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_ListConnectorDefinitions_600027;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600041 = newJObject()
  add(query_600041, "NextToken", newJString(NextToken))
  add(query_600041, "MaxResults", newJString(MaxResults))
  result = call_600040.call(nil, query_600041, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_600027(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_600028, base: "/",
    url: url_ListConnectorDefinitions_600029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_600074 = ref object of OpenApiRestCall_599352
proc url_CreateConnectorDefinitionVersion_600076(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinitionVersion_600075(path: JsonNode;
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
  var valid_600077 = path.getOrDefault("ConnectorDefinitionId")
  valid_600077 = validateParameter(valid_600077, JString, required = true,
                                 default = nil)
  if valid_600077 != nil:
    section.add "ConnectorDefinitionId", valid_600077
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
  var valid_600078 = header.getOrDefault("X-Amz-Date")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Date", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Security-Token")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Security-Token", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Content-Sha256", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Algorithm")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Algorithm", valid_600081
  var valid_600082 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amzn-Client-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Signature")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Signature", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-SignedHeaders", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Credential")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Credential", valid_600085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600087: Call_CreateConnectorDefinitionVersion_600074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_600087.validator(path, query, header, formData, body)
  let scheme = call_600087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600087.url(scheme.get, call_600087.host, call_600087.base,
                         call_600087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600087, url, valid)

proc call*(call_600088: Call_CreateConnectorDefinitionVersion_600074;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_600089 = newJObject()
  var body_600090 = newJObject()
  add(path_600089, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_600090 = body
  result = call_600088.call(path_600089, nil, nil, nil, body_600090)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_600074(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_600075, base: "/",
    url: url_CreateConnectorDefinitionVersion_600076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_600057 = ref object of OpenApiRestCall_599352
proc url_ListConnectorDefinitionVersions_600059(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitionVersions_600058(path: JsonNode;
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
  var valid_600060 = path.getOrDefault("ConnectorDefinitionId")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "ConnectorDefinitionId", valid_600060
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600061 = query.getOrDefault("NextToken")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "NextToken", valid_600061
  var valid_600062 = query.getOrDefault("MaxResults")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "MaxResults", valid_600062
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
  var valid_600063 = header.getOrDefault("X-Amz-Date")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Date", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Security-Token")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Security-Token", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Content-Sha256", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Algorithm")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Algorithm", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Signature")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Signature", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-SignedHeaders", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Credential")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Credential", valid_600069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600070: Call_ListConnectorDefinitionVersions_600057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_600070.validator(path, query, header, formData, body)
  let scheme = call_600070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600070.url(scheme.get, call_600070.host, call_600070.base,
                         call_600070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600070, url, valid)

proc call*(call_600071: Call_ListConnectorDefinitionVersions_600057;
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
  var path_600072 = newJObject()
  var query_600073 = newJObject()
  add(query_600073, "NextToken", newJString(NextToken))
  add(path_600072, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  add(query_600073, "MaxResults", newJString(MaxResults))
  result = call_600071.call(path_600072, query_600073, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_600057(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_600058, base: "/",
    url: url_ListConnectorDefinitionVersions_600059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_600106 = ref object of OpenApiRestCall_599352
proc url_CreateCoreDefinition_600108(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCoreDefinition_600107(path: JsonNode; query: JsonNode;
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
  var valid_600109 = header.getOrDefault("X-Amz-Date")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Date", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Security-Token")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Security-Token", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Content-Sha256", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Algorithm")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Algorithm", valid_600112
  var valid_600113 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amzn-Client-Token", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Signature")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Signature", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-SignedHeaders", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Credential")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Credential", valid_600116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600118: Call_CreateCoreDefinition_600106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_600118.validator(path, query, header, formData, body)
  let scheme = call_600118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600118.url(scheme.get, call_600118.host, call_600118.base,
                         call_600118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600118, url, valid)

proc call*(call_600119: Call_CreateCoreDefinition_600106; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_600120 = newJObject()
  if body != nil:
    body_600120 = body
  result = call_600119.call(nil, nil, nil, nil, body_600120)

var createCoreDefinition* = Call_CreateCoreDefinition_600106(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_600107, base: "/",
    url: url_CreateCoreDefinition_600108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_600091 = ref object of OpenApiRestCall_599352
proc url_ListCoreDefinitions_600093(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCoreDefinitions_600092(path: JsonNode; query: JsonNode;
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
  var valid_600094 = query.getOrDefault("NextToken")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "NextToken", valid_600094
  var valid_600095 = query.getOrDefault("MaxResults")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "MaxResults", valid_600095
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
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Content-Sha256", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Algorithm")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Algorithm", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Signature")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Signature", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-SignedHeaders", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Credential")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Credential", valid_600102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600103: Call_ListCoreDefinitions_600091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_600103.validator(path, query, header, formData, body)
  let scheme = call_600103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600103.url(scheme.get, call_600103.host, call_600103.base,
                         call_600103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600103, url, valid)

proc call*(call_600104: Call_ListCoreDefinitions_600091; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600105 = newJObject()
  add(query_600105, "NextToken", newJString(NextToken))
  add(query_600105, "MaxResults", newJString(MaxResults))
  result = call_600104.call(nil, query_600105, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_600091(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_600092, base: "/",
    url: url_ListCoreDefinitions_600093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_600138 = ref object of OpenApiRestCall_599352
proc url_CreateCoreDefinitionVersion_600140(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_600139(path: JsonNode; query: JsonNode;
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
  var valid_600141 = path.getOrDefault("CoreDefinitionId")
  valid_600141 = validateParameter(valid_600141, JString, required = true,
                                 default = nil)
  if valid_600141 != nil:
    section.add "CoreDefinitionId", valid_600141
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Content-Sha256", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Algorithm")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Algorithm", valid_600145
  var valid_600146 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amzn-Client-Token", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateCoreDefinitionVersion_600138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateCoreDefinitionVersion_600138;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_600153 = newJObject()
  var body_600154 = newJObject()
  add(path_600153, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_600154 = body
  result = call_600152.call(path_600153, nil, nil, nil, body_600154)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_600138(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_600139, base: "/",
    url: url_CreateCoreDefinitionVersion_600140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_600121 = ref object of OpenApiRestCall_599352
proc url_ListCoreDefinitionVersions_600123(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_600122(path: JsonNode; query: JsonNode;
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
  var valid_600124 = path.getOrDefault("CoreDefinitionId")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = nil)
  if valid_600124 != nil:
    section.add "CoreDefinitionId", valid_600124
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600125 = query.getOrDefault("NextToken")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "NextToken", valid_600125
  var valid_600126 = query.getOrDefault("MaxResults")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "MaxResults", valid_600126
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Content-Sha256", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Algorithm")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Algorithm", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Signature")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Signature", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-SignedHeaders", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Credential")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Credential", valid_600133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600134: Call_ListCoreDefinitionVersions_600121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_600134.validator(path, query, header, formData, body)
  let scheme = call_600134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600134.url(scheme.get, call_600134.host, call_600134.base,
                         call_600134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600134, url, valid)

proc call*(call_600135: Call_ListCoreDefinitionVersions_600121;
          CoreDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_600136 = newJObject()
  var query_600137 = newJObject()
  add(path_600136, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(query_600137, "NextToken", newJString(NextToken))
  add(query_600137, "MaxResults", newJString(MaxResults))
  result = call_600135.call(path_600136, query_600137, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_600121(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_600122, base: "/",
    url: url_ListCoreDefinitionVersions_600123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_600172 = ref object of OpenApiRestCall_599352
proc url_CreateDeployment_600174(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_600173(path: JsonNode; query: JsonNode;
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
  var valid_600175 = path.getOrDefault("GroupId")
  valid_600175 = validateParameter(valid_600175, JString, required = true,
                                 default = nil)
  if valid_600175 != nil:
    section.add "GroupId", valid_600175
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
  var valid_600176 = header.getOrDefault("X-Amz-Date")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Date", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Security-Token")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Security-Token", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Content-Sha256", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Algorithm")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Algorithm", valid_600179
  var valid_600180 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amzn-Client-Token", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Signature")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Signature", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-SignedHeaders", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Credential")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Credential", valid_600183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600185: Call_CreateDeployment_600172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_600185.validator(path, query, header, formData, body)
  let scheme = call_600185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600185.url(scheme.get, call_600185.host, call_600185.base,
                         call_600185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600185, url, valid)

proc call*(call_600186: Call_CreateDeployment_600172; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_600187 = newJObject()
  var body_600188 = newJObject()
  add(path_600187, "GroupId", newJString(GroupId))
  if body != nil:
    body_600188 = body
  result = call_600186.call(path_600187, nil, nil, nil, body_600188)

var createDeployment* = Call_CreateDeployment_600172(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_600173, base: "/",
    url: url_CreateDeployment_600174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_600155 = ref object of OpenApiRestCall_599352
proc url_ListDeployments_600157(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_600156(path: JsonNode; query: JsonNode;
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
  var valid_600158 = path.getOrDefault("GroupId")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = nil)
  if valid_600158 != nil:
    section.add "GroupId", valid_600158
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600159 = query.getOrDefault("NextToken")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "NextToken", valid_600159
  var valid_600160 = query.getOrDefault("MaxResults")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "MaxResults", valid_600160
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
  var valid_600161 = header.getOrDefault("X-Amz-Date")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Date", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Security-Token")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Security-Token", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Content-Sha256", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Algorithm")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Algorithm", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Signature")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Signature", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-SignedHeaders", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Credential")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Credential", valid_600167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600168: Call_ListDeployments_600155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_600168.validator(path, query, header, formData, body)
  let scheme = call_600168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600168.url(scheme.get, call_600168.host, call_600168.base,
                         call_600168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600168, url, valid)

proc call*(call_600169: Call_ListDeployments_600155; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_600170 = newJObject()
  var query_600171 = newJObject()
  add(path_600170, "GroupId", newJString(GroupId))
  add(query_600171, "NextToken", newJString(NextToken))
  add(query_600171, "MaxResults", newJString(MaxResults))
  result = call_600169.call(path_600170, query_600171, nil, nil, nil)

var listDeployments* = Call_ListDeployments_600155(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_600156, base: "/", url: url_ListDeployments_600157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_600204 = ref object of OpenApiRestCall_599352
proc url_CreateDeviceDefinition_600206(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeviceDefinition_600205(path: JsonNode; query: JsonNode;
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
  var valid_600207 = header.getOrDefault("X-Amz-Date")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Date", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Security-Token")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Security-Token", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Content-Sha256", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Algorithm")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Algorithm", valid_600210
  var valid_600211 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amzn-Client-Token", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Signature")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Signature", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-SignedHeaders", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Credential")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Credential", valid_600214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600216: Call_CreateDeviceDefinition_600204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_600216.validator(path, query, header, formData, body)
  let scheme = call_600216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600216.url(scheme.get, call_600216.host, call_600216.base,
                         call_600216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600216, url, valid)

proc call*(call_600217: Call_CreateDeviceDefinition_600204; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_600218 = newJObject()
  if body != nil:
    body_600218 = body
  result = call_600217.call(nil, nil, nil, nil, body_600218)

var createDeviceDefinition* = Call_CreateDeviceDefinition_600204(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_600205, base: "/",
    url: url_CreateDeviceDefinition_600206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_600189 = ref object of OpenApiRestCall_599352
proc url_ListDeviceDefinitions_600191(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeviceDefinitions_600190(path: JsonNode; query: JsonNode;
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
  var valid_600192 = query.getOrDefault("NextToken")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "NextToken", valid_600192
  var valid_600193 = query.getOrDefault("MaxResults")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "MaxResults", valid_600193
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
  var valid_600194 = header.getOrDefault("X-Amz-Date")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Date", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Security-Token")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Security-Token", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Content-Sha256", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Algorithm")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Algorithm", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Signature")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Signature", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-SignedHeaders", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Credential")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Credential", valid_600200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600201: Call_ListDeviceDefinitions_600189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_600201.validator(path, query, header, formData, body)
  let scheme = call_600201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600201.url(scheme.get, call_600201.host, call_600201.base,
                         call_600201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600201, url, valid)

proc call*(call_600202: Call_ListDeviceDefinitions_600189; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600203 = newJObject()
  add(query_600203, "NextToken", newJString(NextToken))
  add(query_600203, "MaxResults", newJString(MaxResults))
  result = call_600202.call(nil, query_600203, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_600189(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_600190, base: "/",
    url: url_ListDeviceDefinitions_600191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_600236 = ref object of OpenApiRestCall_599352
proc url_CreateDeviceDefinitionVersion_600238(protocol: Scheme; host: string;
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

proc validate_CreateDeviceDefinitionVersion_600237(path: JsonNode; query: JsonNode;
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
  var valid_600239 = path.getOrDefault("DeviceDefinitionId")
  valid_600239 = validateParameter(valid_600239, JString, required = true,
                                 default = nil)
  if valid_600239 != nil:
    section.add "DeviceDefinitionId", valid_600239
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
  var valid_600240 = header.getOrDefault("X-Amz-Date")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Date", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Security-Token")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Security-Token", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Content-Sha256", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Algorithm")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Algorithm", valid_600243
  var valid_600244 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amzn-Client-Token", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Signature")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Signature", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-SignedHeaders", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Credential")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Credential", valid_600247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600249: Call_CreateDeviceDefinitionVersion_600236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_600249.validator(path, query, header, formData, body)
  let scheme = call_600249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600249.url(scheme.get, call_600249.host, call_600249.base,
                         call_600249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600249, url, valid)

proc call*(call_600250: Call_CreateDeviceDefinitionVersion_600236;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_600251 = newJObject()
  var body_600252 = newJObject()
  add(path_600251, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_600252 = body
  result = call_600250.call(path_600251, nil, nil, nil, body_600252)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_600236(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_600237, base: "/",
    url: url_CreateDeviceDefinitionVersion_600238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_600219 = ref object of OpenApiRestCall_599352
proc url_ListDeviceDefinitionVersions_600221(protocol: Scheme; host: string;
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

proc validate_ListDeviceDefinitionVersions_600220(path: JsonNode; query: JsonNode;
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
  var valid_600222 = path.getOrDefault("DeviceDefinitionId")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "DeviceDefinitionId", valid_600222
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600223 = query.getOrDefault("NextToken")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "NextToken", valid_600223
  var valid_600224 = query.getOrDefault("MaxResults")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "MaxResults", valid_600224
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
  var valid_600225 = header.getOrDefault("X-Amz-Date")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Date", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Security-Token")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Security-Token", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600232: Call_ListDeviceDefinitionVersions_600219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_600232.validator(path, query, header, formData, body)
  let scheme = call_600232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600232.url(scheme.get, call_600232.host, call_600232.base,
                         call_600232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600232, url, valid)

proc call*(call_600233: Call_ListDeviceDefinitionVersions_600219;
          DeviceDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_600234 = newJObject()
  var query_600235 = newJObject()
  add(path_600234, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_600235, "NextToken", newJString(NextToken))
  add(query_600235, "MaxResults", newJString(MaxResults))
  result = call_600233.call(path_600234, query_600235, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_600219(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_600220, base: "/",
    url: url_ListDeviceDefinitionVersions_600221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_600268 = ref object of OpenApiRestCall_599352
proc url_CreateFunctionDefinition_600270(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunctionDefinition_600269(path: JsonNode; query: JsonNode;
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
  var valid_600271 = header.getOrDefault("X-Amz-Date")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Date", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Security-Token")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Security-Token", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Content-Sha256", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Algorithm")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Algorithm", valid_600274
  var valid_600275 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amzn-Client-Token", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Signature")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Signature", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-SignedHeaders", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Credential")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Credential", valid_600278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600280: Call_CreateFunctionDefinition_600268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_600280.validator(path, query, header, formData, body)
  let scheme = call_600280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600280.url(scheme.get, call_600280.host, call_600280.base,
                         call_600280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600280, url, valid)

proc call*(call_600281: Call_CreateFunctionDefinition_600268; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_600282 = newJObject()
  if body != nil:
    body_600282 = body
  result = call_600281.call(nil, nil, nil, nil, body_600282)

var createFunctionDefinition* = Call_CreateFunctionDefinition_600268(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_600269, base: "/",
    url: url_CreateFunctionDefinition_600270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_600253 = ref object of OpenApiRestCall_599352
proc url_ListFunctionDefinitions_600255(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctionDefinitions_600254(path: JsonNode; query: JsonNode;
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
  var valid_600256 = query.getOrDefault("NextToken")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "NextToken", valid_600256
  var valid_600257 = query.getOrDefault("MaxResults")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "MaxResults", valid_600257
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
  var valid_600258 = header.getOrDefault("X-Amz-Date")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Date", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Security-Token")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Security-Token", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Content-Sha256", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Algorithm")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Algorithm", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Signature")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Signature", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-SignedHeaders", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Credential")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Credential", valid_600264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600265: Call_ListFunctionDefinitions_600253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_600265.validator(path, query, header, formData, body)
  let scheme = call_600265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600265.url(scheme.get, call_600265.host, call_600265.base,
                         call_600265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600265, url, valid)

proc call*(call_600266: Call_ListFunctionDefinitions_600253;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600267 = newJObject()
  add(query_600267, "NextToken", newJString(NextToken))
  add(query_600267, "MaxResults", newJString(MaxResults))
  result = call_600266.call(nil, query_600267, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_600253(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_600254, base: "/",
    url: url_ListFunctionDefinitions_600255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_600300 = ref object of OpenApiRestCall_599352
proc url_CreateFunctionDefinitionVersion_600302(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinitionVersion_600301(path: JsonNode;
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
  var valid_600303 = path.getOrDefault("FunctionDefinitionId")
  valid_600303 = validateParameter(valid_600303, JString, required = true,
                                 default = nil)
  if valid_600303 != nil:
    section.add "FunctionDefinitionId", valid_600303
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
  var valid_600304 = header.getOrDefault("X-Amz-Date")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Date", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Security-Token")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Security-Token", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Content-Sha256", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Algorithm")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Algorithm", valid_600307
  var valid_600308 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amzn-Client-Token", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_CreateFunctionDefinitionVersion_600300;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_CreateFunctionDefinitionVersion_600300;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_600315 = newJObject()
  var body_600316 = newJObject()
  add(path_600315, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_600316 = body
  result = call_600314.call(path_600315, nil, nil, nil, body_600316)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_600300(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_600301, base: "/",
    url: url_CreateFunctionDefinitionVersion_600302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_600283 = ref object of OpenApiRestCall_599352
proc url_ListFunctionDefinitionVersions_600285(protocol: Scheme; host: string;
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

proc validate_ListFunctionDefinitionVersions_600284(path: JsonNode;
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
  var valid_600286 = path.getOrDefault("FunctionDefinitionId")
  valid_600286 = validateParameter(valid_600286, JString, required = true,
                                 default = nil)
  if valid_600286 != nil:
    section.add "FunctionDefinitionId", valid_600286
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600287 = query.getOrDefault("NextToken")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "NextToken", valid_600287
  var valid_600288 = query.getOrDefault("MaxResults")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "MaxResults", valid_600288
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
  var valid_600289 = header.getOrDefault("X-Amz-Date")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Date", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Security-Token")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Security-Token", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Content-Sha256", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Algorithm")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Algorithm", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Signature")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Signature", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-SignedHeaders", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Credential")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Credential", valid_600295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600296: Call_ListFunctionDefinitionVersions_600283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_600296.validator(path, query, header, formData, body)
  let scheme = call_600296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600296.url(scheme.get, call_600296.host, call_600296.base,
                         call_600296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600296, url, valid)

proc call*(call_600297: Call_ListFunctionDefinitionVersions_600283;
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
  var path_600298 = newJObject()
  var query_600299 = newJObject()
  add(query_600299, "NextToken", newJString(NextToken))
  add(path_600298, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  add(query_600299, "MaxResults", newJString(MaxResults))
  result = call_600297.call(path_600298, query_600299, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_600283(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_600284, base: "/",
    url: url_ListFunctionDefinitionVersions_600285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_600332 = ref object of OpenApiRestCall_599352
proc url_CreateGroup_600334(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_600333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600335 = header.getOrDefault("X-Amz-Date")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Date", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Security-Token")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Security-Token", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Content-Sha256", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Algorithm")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Algorithm", valid_600338
  var valid_600339 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amzn-Client-Token", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Signature")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Signature", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-SignedHeaders", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Credential")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Credential", valid_600342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600344: Call_CreateGroup_600332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_600344.validator(path, query, header, formData, body)
  let scheme = call_600344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600344.url(scheme.get, call_600344.host, call_600344.base,
                         call_600344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600344, url, valid)

proc call*(call_600345: Call_CreateGroup_600332; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_600346 = newJObject()
  if body != nil:
    body_600346 = body
  result = call_600345.call(nil, nil, nil, nil, body_600346)

var createGroup* = Call_CreateGroup_600332(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_600333,
                                        base: "/", url: url_CreateGroup_600334,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_600317 = ref object of OpenApiRestCall_599352
proc url_ListGroups_600319(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_600318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600320 = query.getOrDefault("NextToken")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "NextToken", valid_600320
  var valid_600321 = query.getOrDefault("MaxResults")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "MaxResults", valid_600321
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Content-Sha256", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Algorithm")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Algorithm", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Signature")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Signature", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-SignedHeaders", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Credential")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Credential", valid_600328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600329: Call_ListGroups_600317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_600329.validator(path, query, header, formData, body)
  let scheme = call_600329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600329.url(scheme.get, call_600329.host, call_600329.base,
                         call_600329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600329, url, valid)

proc call*(call_600330: Call_ListGroups_600317; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600331 = newJObject()
  add(query_600331, "NextToken", newJString(NextToken))
  add(query_600331, "MaxResults", newJString(MaxResults))
  result = call_600330.call(nil, query_600331, nil, nil, nil)

var listGroups* = Call_ListGroups_600317(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_600318,
                                      base: "/", url: url_ListGroups_600319,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_600361 = ref object of OpenApiRestCall_599352
proc url_CreateGroupCertificateAuthority_600363(protocol: Scheme; host: string;
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

proc validate_CreateGroupCertificateAuthority_600362(path: JsonNode;
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
  var valid_600364 = path.getOrDefault("GroupId")
  valid_600364 = validateParameter(valid_600364, JString, required = true,
                                 default = nil)
  if valid_600364 != nil:
    section.add "GroupId", valid_600364
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
  var valid_600365 = header.getOrDefault("X-Amz-Date")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Date", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Security-Token")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Security-Token", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amzn-Client-Token", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Signature")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Signature", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-SignedHeaders", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Credential")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Credential", valid_600372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600373: Call_CreateGroupCertificateAuthority_600361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_CreateGroupCertificateAuthority_600361;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_600375 = newJObject()
  add(path_600375, "GroupId", newJString(GroupId))
  result = call_600374.call(path_600375, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_600361(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_600362, base: "/",
    url: url_CreateGroupCertificateAuthority_600363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_600347 = ref object of OpenApiRestCall_599352
proc url_ListGroupCertificateAuthorities_600349(protocol: Scheme; host: string;
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

proc validate_ListGroupCertificateAuthorities_600348(path: JsonNode;
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
  var valid_600350 = path.getOrDefault("GroupId")
  valid_600350 = validateParameter(valid_600350, JString, required = true,
                                 default = nil)
  if valid_600350 != nil:
    section.add "GroupId", valid_600350
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
  var valid_600351 = header.getOrDefault("X-Amz-Date")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Date", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Security-Token")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Security-Token", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Content-Sha256", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Algorithm")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Algorithm", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Signature")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Signature", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-SignedHeaders", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Credential")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Credential", valid_600357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600358: Call_ListGroupCertificateAuthorities_600347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_600358.validator(path, query, header, formData, body)
  let scheme = call_600358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600358.url(scheme.get, call_600358.host, call_600358.base,
                         call_600358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600358, url, valid)

proc call*(call_600359: Call_ListGroupCertificateAuthorities_600347;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_600360 = newJObject()
  add(path_600360, "GroupId", newJString(GroupId))
  result = call_600359.call(path_600360, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_600347(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_600348, base: "/",
    url: url_ListGroupCertificateAuthorities_600349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_600393 = ref object of OpenApiRestCall_599352
proc url_CreateGroupVersion_600395(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupVersion_600394(path: JsonNode; query: JsonNode;
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
  var valid_600396 = path.getOrDefault("GroupId")
  valid_600396 = validateParameter(valid_600396, JString, required = true,
                                 default = nil)
  if valid_600396 != nil:
    section.add "GroupId", valid_600396
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
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Content-Sha256", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Algorithm")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Algorithm", valid_600400
  var valid_600401 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amzn-Client-Token", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_CreateGroupVersion_600393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_CreateGroupVersion_600393; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_600408 = newJObject()
  var body_600409 = newJObject()
  add(path_600408, "GroupId", newJString(GroupId))
  if body != nil:
    body_600409 = body
  result = call_600407.call(path_600408, nil, nil, nil, body_600409)

var createGroupVersion* = Call_CreateGroupVersion_600393(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_600394, base: "/",
    url: url_CreateGroupVersion_600395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_600376 = ref object of OpenApiRestCall_599352
proc url_ListGroupVersions_600378(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupVersions_600377(path: JsonNode; query: JsonNode;
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
  var valid_600379 = path.getOrDefault("GroupId")
  valid_600379 = validateParameter(valid_600379, JString, required = true,
                                 default = nil)
  if valid_600379 != nil:
    section.add "GroupId", valid_600379
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600380 = query.getOrDefault("NextToken")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "NextToken", valid_600380
  var valid_600381 = query.getOrDefault("MaxResults")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "MaxResults", valid_600381
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
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Content-Sha256", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Algorithm")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Algorithm", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Signature")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Signature", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-SignedHeaders", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Credential")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Credential", valid_600388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600389: Call_ListGroupVersions_600376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_600389.validator(path, query, header, formData, body)
  let scheme = call_600389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600389.url(scheme.get, call_600389.host, call_600389.base,
                         call_600389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600389, url, valid)

proc call*(call_600390: Call_ListGroupVersions_600376; GroupId: string;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_600391 = newJObject()
  var query_600392 = newJObject()
  add(path_600391, "GroupId", newJString(GroupId))
  add(query_600392, "NextToken", newJString(NextToken))
  add(query_600392, "MaxResults", newJString(MaxResults))
  result = call_600390.call(path_600391, query_600392, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_600376(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_600377, base: "/",
    url: url_ListGroupVersions_600378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_600425 = ref object of OpenApiRestCall_599352
proc url_CreateLoggerDefinition_600427(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoggerDefinition_600426(path: JsonNode; query: JsonNode;
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
  var valid_600428 = header.getOrDefault("X-Amz-Date")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Date", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Security-Token")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Security-Token", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amzn-Client-Token", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Signature")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Signature", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-SignedHeaders", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Credential")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Credential", valid_600435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600437: Call_CreateLoggerDefinition_600425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_600437.validator(path, query, header, formData, body)
  let scheme = call_600437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600437.url(scheme.get, call_600437.host, call_600437.base,
                         call_600437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600437, url, valid)

proc call*(call_600438: Call_CreateLoggerDefinition_600425; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_600439 = newJObject()
  if body != nil:
    body_600439 = body
  result = call_600438.call(nil, nil, nil, nil, body_600439)

var createLoggerDefinition* = Call_CreateLoggerDefinition_600425(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_600426, base: "/",
    url: url_CreateLoggerDefinition_600427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_600410 = ref object of OpenApiRestCall_599352
proc url_ListLoggerDefinitions_600412(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggerDefinitions_600411(path: JsonNode; query: JsonNode;
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
  var valid_600413 = query.getOrDefault("NextToken")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "NextToken", valid_600413
  var valid_600414 = query.getOrDefault("MaxResults")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "MaxResults", valid_600414
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
  var valid_600415 = header.getOrDefault("X-Amz-Date")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Date", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Security-Token")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Security-Token", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Content-Sha256", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Algorithm")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Algorithm", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Signature")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Signature", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-SignedHeaders", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Credential")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Credential", valid_600421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600422: Call_ListLoggerDefinitions_600410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_600422.validator(path, query, header, formData, body)
  let scheme = call_600422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600422.url(scheme.get, call_600422.host, call_600422.base,
                         call_600422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600422, url, valid)

proc call*(call_600423: Call_ListLoggerDefinitions_600410; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600424 = newJObject()
  add(query_600424, "NextToken", newJString(NextToken))
  add(query_600424, "MaxResults", newJString(MaxResults))
  result = call_600423.call(nil, query_600424, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_600410(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_600411, base: "/",
    url: url_ListLoggerDefinitions_600412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_600457 = ref object of OpenApiRestCall_599352
proc url_CreateLoggerDefinitionVersion_600459(protocol: Scheme; host: string;
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

proc validate_CreateLoggerDefinitionVersion_600458(path: JsonNode; query: JsonNode;
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
  var valid_600460 = path.getOrDefault("LoggerDefinitionId")
  valid_600460 = validateParameter(valid_600460, JString, required = true,
                                 default = nil)
  if valid_600460 != nil:
    section.add "LoggerDefinitionId", valid_600460
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
  var valid_600461 = header.getOrDefault("X-Amz-Date")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Date", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Security-Token")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Security-Token", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Content-Sha256", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Algorithm")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Algorithm", valid_600464
  var valid_600465 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amzn-Client-Token", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Signature")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Signature", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-SignedHeaders", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Credential")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Credential", valid_600468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600470: Call_CreateLoggerDefinitionVersion_600457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_600470.validator(path, query, header, formData, body)
  let scheme = call_600470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600470.url(scheme.get, call_600470.host, call_600470.base,
                         call_600470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600470, url, valid)

proc call*(call_600471: Call_CreateLoggerDefinitionVersion_600457;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_600472 = newJObject()
  var body_600473 = newJObject()
  add(path_600472, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_600473 = body
  result = call_600471.call(path_600472, nil, nil, nil, body_600473)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_600457(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_600458, base: "/",
    url: url_CreateLoggerDefinitionVersion_600459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_600440 = ref object of OpenApiRestCall_599352
proc url_ListLoggerDefinitionVersions_600442(protocol: Scheme; host: string;
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

proc validate_ListLoggerDefinitionVersions_600441(path: JsonNode; query: JsonNode;
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
  var valid_600443 = path.getOrDefault("LoggerDefinitionId")
  valid_600443 = validateParameter(valid_600443, JString, required = true,
                                 default = nil)
  if valid_600443 != nil:
    section.add "LoggerDefinitionId", valid_600443
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600444 = query.getOrDefault("NextToken")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "NextToken", valid_600444
  var valid_600445 = query.getOrDefault("MaxResults")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "MaxResults", valid_600445
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
  var valid_600446 = header.getOrDefault("X-Amz-Date")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Date", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Security-Token")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Security-Token", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Content-Sha256", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Algorithm")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Algorithm", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Signature")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Signature", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-SignedHeaders", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Credential")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Credential", valid_600452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600453: Call_ListLoggerDefinitionVersions_600440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_600453.validator(path, query, header, formData, body)
  let scheme = call_600453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600453.url(scheme.get, call_600453.host, call_600453.base,
                         call_600453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600453, url, valid)

proc call*(call_600454: Call_ListLoggerDefinitionVersions_600440;
          LoggerDefinitionId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var path_600455 = newJObject()
  var query_600456 = newJObject()
  add(query_600456, "NextToken", newJString(NextToken))
  add(path_600455, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  add(query_600456, "MaxResults", newJString(MaxResults))
  result = call_600454.call(path_600455, query_600456, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_600440(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_600441, base: "/",
    url: url_ListLoggerDefinitionVersions_600442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_600489 = ref object of OpenApiRestCall_599352
proc url_CreateResourceDefinition_600491(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDefinition_600490(path: JsonNode; query: JsonNode;
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
  var valid_600492 = header.getOrDefault("X-Amz-Date")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Date", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Security-Token")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Security-Token", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Content-Sha256", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Algorithm")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Algorithm", valid_600495
  var valid_600496 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amzn-Client-Token", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Signature")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Signature", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-SignedHeaders", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Credential")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Credential", valid_600499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600501: Call_CreateResourceDefinition_600489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_600501.validator(path, query, header, formData, body)
  let scheme = call_600501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600501.url(scheme.get, call_600501.host, call_600501.base,
                         call_600501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600501, url, valid)

proc call*(call_600502: Call_CreateResourceDefinition_600489; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_600503 = newJObject()
  if body != nil:
    body_600503 = body
  result = call_600502.call(nil, nil, nil, nil, body_600503)

var createResourceDefinition* = Call_CreateResourceDefinition_600489(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_600490, base: "/",
    url: url_CreateResourceDefinition_600491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_600474 = ref object of OpenApiRestCall_599352
proc url_ListResourceDefinitions_600476(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDefinitions_600475(path: JsonNode; query: JsonNode;
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
  var valid_600477 = query.getOrDefault("NextToken")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "NextToken", valid_600477
  var valid_600478 = query.getOrDefault("MaxResults")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "MaxResults", valid_600478
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
  var valid_600479 = header.getOrDefault("X-Amz-Date")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Date", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Security-Token")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Security-Token", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Content-Sha256", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Algorithm")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Algorithm", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Signature")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Signature", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-SignedHeaders", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Credential")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Credential", valid_600485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600486: Call_ListResourceDefinitions_600474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_600486.validator(path, query, header, formData, body)
  let scheme = call_600486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600486.url(scheme.get, call_600486.host, call_600486.base,
                         call_600486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600486, url, valid)

proc call*(call_600487: Call_ListResourceDefinitions_600474;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600488 = newJObject()
  add(query_600488, "NextToken", newJString(NextToken))
  add(query_600488, "MaxResults", newJString(MaxResults))
  result = call_600487.call(nil, query_600488, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_600474(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_600475, base: "/",
    url: url_ListResourceDefinitions_600476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_600521 = ref object of OpenApiRestCall_599352
proc url_CreateResourceDefinitionVersion_600523(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinitionVersion_600522(path: JsonNode;
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
  var valid_600524 = path.getOrDefault("ResourceDefinitionId")
  valid_600524 = validateParameter(valid_600524, JString, required = true,
                                 default = nil)
  if valid_600524 != nil:
    section.add "ResourceDefinitionId", valid_600524
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
  var valid_600525 = header.getOrDefault("X-Amz-Date")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Date", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Security-Token")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Security-Token", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Content-Sha256", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Algorithm")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Algorithm", valid_600528
  var valid_600529 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amzn-Client-Token", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Signature")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Signature", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-SignedHeaders", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Credential")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Credential", valid_600532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600534: Call_CreateResourceDefinitionVersion_600521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_600534.validator(path, query, header, formData, body)
  let scheme = call_600534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600534.url(scheme.get, call_600534.host, call_600534.base,
                         call_600534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600534, url, valid)

proc call*(call_600535: Call_CreateResourceDefinitionVersion_600521;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_600536 = newJObject()
  var body_600537 = newJObject()
  add(path_600536, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_600537 = body
  result = call_600535.call(path_600536, nil, nil, nil, body_600537)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_600521(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_600522, base: "/",
    url: url_CreateResourceDefinitionVersion_600523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_600504 = ref object of OpenApiRestCall_599352
proc url_ListResourceDefinitionVersions_600506(protocol: Scheme; host: string;
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

proc validate_ListResourceDefinitionVersions_600505(path: JsonNode;
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
  var valid_600507 = path.getOrDefault("ResourceDefinitionId")
  valid_600507 = validateParameter(valid_600507, JString, required = true,
                                 default = nil)
  if valid_600507 != nil:
    section.add "ResourceDefinitionId", valid_600507
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600508 = query.getOrDefault("NextToken")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "NextToken", valid_600508
  var valid_600509 = query.getOrDefault("MaxResults")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "MaxResults", valid_600509
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
  var valid_600510 = header.getOrDefault("X-Amz-Date")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Date", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Security-Token")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Security-Token", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Content-Sha256", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Algorithm")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Algorithm", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Signature")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Signature", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-SignedHeaders", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Credential")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Credential", valid_600516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600517: Call_ListResourceDefinitionVersions_600504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_600517.validator(path, query, header, formData, body)
  let scheme = call_600517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600517.url(scheme.get, call_600517.host, call_600517.base,
                         call_600517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600517, url, valid)

proc call*(call_600518: Call_ListResourceDefinitionVersions_600504;
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
  var path_600519 = newJObject()
  var query_600520 = newJObject()
  add(query_600520, "NextToken", newJString(NextToken))
  add(path_600519, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  add(query_600520, "MaxResults", newJString(MaxResults))
  result = call_600518.call(path_600519, query_600520, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_600504(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_600505, base: "/",
    url: url_ListResourceDefinitionVersions_600506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_600538 = ref object of OpenApiRestCall_599352
proc url_CreateSoftwareUpdateJob_600540(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSoftwareUpdateJob_600539(path: JsonNode; query: JsonNode;
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
  var valid_600541 = header.getOrDefault("X-Amz-Date")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Date", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Security-Token")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Security-Token", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Content-Sha256", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Algorithm")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Algorithm", valid_600544
  var valid_600545 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amzn-Client-Token", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Signature")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Signature", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-SignedHeaders", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Credential")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Credential", valid_600548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600550: Call_CreateSoftwareUpdateJob_600538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_600550.validator(path, query, header, formData, body)
  let scheme = call_600550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600550.url(scheme.get, call_600550.host, call_600550.base,
                         call_600550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600550, url, valid)

proc call*(call_600551: Call_CreateSoftwareUpdateJob_600538; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_600552 = newJObject()
  if body != nil:
    body_600552 = body
  result = call_600551.call(nil, nil, nil, nil, body_600552)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_600538(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_600539, base: "/",
    url: url_CreateSoftwareUpdateJob_600540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_600568 = ref object of OpenApiRestCall_599352
proc url_CreateSubscriptionDefinition_600570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubscriptionDefinition_600569(path: JsonNode; query: JsonNode;
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
  var valid_600571 = header.getOrDefault("X-Amz-Date")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Date", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Security-Token")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Security-Token", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Content-Sha256", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Algorithm")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Algorithm", valid_600574
  var valid_600575 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amzn-Client-Token", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Signature")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Signature", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-SignedHeaders", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Credential")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Credential", valid_600578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600580: Call_CreateSubscriptionDefinition_600568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_600580.validator(path, query, header, formData, body)
  let scheme = call_600580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600580.url(scheme.get, call_600580.host, call_600580.base,
                         call_600580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600580, url, valid)

proc call*(call_600581: Call_CreateSubscriptionDefinition_600568; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_600582 = newJObject()
  if body != nil:
    body_600582 = body
  result = call_600581.call(nil, nil, nil, nil, body_600582)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_600568(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_600569, base: "/",
    url: url_CreateSubscriptionDefinition_600570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_600553 = ref object of OpenApiRestCall_599352
proc url_ListSubscriptionDefinitions_600555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscriptionDefinitions_600554(path: JsonNode; query: JsonNode;
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
  var valid_600556 = query.getOrDefault("NextToken")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "NextToken", valid_600556
  var valid_600557 = query.getOrDefault("MaxResults")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "MaxResults", valid_600557
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
  var valid_600558 = header.getOrDefault("X-Amz-Date")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Date", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Security-Token")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Security-Token", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Content-Sha256", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Algorithm")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Algorithm", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Signature")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Signature", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-SignedHeaders", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Credential")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Credential", valid_600564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600565: Call_ListSubscriptionDefinitions_600553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_600565.validator(path, query, header, formData, body)
  let scheme = call_600565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600565.url(scheme.get, call_600565.host, call_600565.base,
                         call_600565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600565, url, valid)

proc call*(call_600566: Call_ListSubscriptionDefinitions_600553;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_600567 = newJObject()
  add(query_600567, "NextToken", newJString(NextToken))
  add(query_600567, "MaxResults", newJString(MaxResults))
  result = call_600566.call(nil, query_600567, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_600553(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_600554, base: "/",
    url: url_ListSubscriptionDefinitions_600555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_600600 = ref object of OpenApiRestCall_599352
proc url_CreateSubscriptionDefinitionVersion_600602(protocol: Scheme; host: string;
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

proc validate_CreateSubscriptionDefinitionVersion_600601(path: JsonNode;
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
  var valid_600603 = path.getOrDefault("SubscriptionDefinitionId")
  valid_600603 = validateParameter(valid_600603, JString, required = true,
                                 default = nil)
  if valid_600603 != nil:
    section.add "SubscriptionDefinitionId", valid_600603
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
  var valid_600604 = header.getOrDefault("X-Amz-Date")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Date", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Security-Token")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Security-Token", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Content-Sha256", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Algorithm")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Algorithm", valid_600607
  var valid_600608 = header.getOrDefault("X-Amzn-Client-Token")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amzn-Client-Token", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Signature")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Signature", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-SignedHeaders", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Credential")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Credential", valid_600611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600613: Call_CreateSubscriptionDefinitionVersion_600600;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_600613.validator(path, query, header, formData, body)
  let scheme = call_600613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600613.url(scheme.get, call_600613.host, call_600613.base,
                         call_600613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600613, url, valid)

proc call*(call_600614: Call_CreateSubscriptionDefinitionVersion_600600;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_600615 = newJObject()
  var body_600616 = newJObject()
  add(path_600615, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_600616 = body
  result = call_600614.call(path_600615, nil, nil, nil, body_600616)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_600600(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_600601, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_600602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_600583 = ref object of OpenApiRestCall_599352
proc url_ListSubscriptionDefinitionVersions_600585(protocol: Scheme; host: string;
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

proc validate_ListSubscriptionDefinitionVersions_600584(path: JsonNode;
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
  var valid_600586 = path.getOrDefault("SubscriptionDefinitionId")
  valid_600586 = validateParameter(valid_600586, JString, required = true,
                                 default = nil)
  if valid_600586 != nil:
    section.add "SubscriptionDefinitionId", valid_600586
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_600587 = query.getOrDefault("NextToken")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "NextToken", valid_600587
  var valid_600588 = query.getOrDefault("MaxResults")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "MaxResults", valid_600588
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
  var valid_600589 = header.getOrDefault("X-Amz-Date")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Date", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Security-Token")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Security-Token", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Content-Sha256", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Algorithm")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Algorithm", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Signature")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Signature", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-SignedHeaders", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Credential")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Credential", valid_600595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600596: Call_ListSubscriptionDefinitionVersions_600583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_ListSubscriptionDefinitionVersions_600583;
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
  var path_600598 = newJObject()
  var query_600599 = newJObject()
  add(query_600599, "NextToken", newJString(NextToken))
  add(path_600598, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(query_600599, "MaxResults", newJString(MaxResults))
  result = call_600597.call(path_600598, query_600599, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_600583(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_600584, base: "/",
    url: url_ListSubscriptionDefinitionVersions_600585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_600631 = ref object of OpenApiRestCall_599352
proc url_UpdateConnectorDefinition_600633(protocol: Scheme; host: string;
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

proc validate_UpdateConnectorDefinition_600632(path: JsonNode; query: JsonNode;
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
  var valid_600634 = path.getOrDefault("ConnectorDefinitionId")
  valid_600634 = validateParameter(valid_600634, JString, required = true,
                                 default = nil)
  if valid_600634 != nil:
    section.add "ConnectorDefinitionId", valid_600634
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
  var valid_600635 = header.getOrDefault("X-Amz-Date")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Date", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Security-Token")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Security-Token", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Content-Sha256", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Algorithm")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Algorithm", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Signature")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Signature", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-SignedHeaders", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Credential")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Credential", valid_600641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600643: Call_UpdateConnectorDefinition_600631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_600643.validator(path, query, header, formData, body)
  let scheme = call_600643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600643.url(scheme.get, call_600643.host, call_600643.base,
                         call_600643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600643, url, valid)

proc call*(call_600644: Call_UpdateConnectorDefinition_600631;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_600645 = newJObject()
  var body_600646 = newJObject()
  add(path_600645, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_600646 = body
  result = call_600644.call(path_600645, nil, nil, nil, body_600646)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_600631(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_600632, base: "/",
    url: url_UpdateConnectorDefinition_600633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_600617 = ref object of OpenApiRestCall_599352
proc url_GetConnectorDefinition_600619(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectorDefinition_600618(path: JsonNode; query: JsonNode;
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
  var valid_600620 = path.getOrDefault("ConnectorDefinitionId")
  valid_600620 = validateParameter(valid_600620, JString, required = true,
                                 default = nil)
  if valid_600620 != nil:
    section.add "ConnectorDefinitionId", valid_600620
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
  var valid_600621 = header.getOrDefault("X-Amz-Date")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Date", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Security-Token")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Security-Token", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Content-Sha256", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Algorithm")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Algorithm", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Signature")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Signature", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-SignedHeaders", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Credential")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Credential", valid_600627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600628: Call_GetConnectorDefinition_600617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_600628.validator(path, query, header, formData, body)
  let scheme = call_600628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600628.url(scheme.get, call_600628.host, call_600628.base,
                         call_600628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600628, url, valid)

proc call*(call_600629: Call_GetConnectorDefinition_600617;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_600630 = newJObject()
  add(path_600630, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_600629.call(path_600630, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_600617(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_600618, base: "/",
    url: url_GetConnectorDefinition_600619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_600647 = ref object of OpenApiRestCall_599352
proc url_DeleteConnectorDefinition_600649(protocol: Scheme; host: string;
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

proc validate_DeleteConnectorDefinition_600648(path: JsonNode; query: JsonNode;
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
  var valid_600650 = path.getOrDefault("ConnectorDefinitionId")
  valid_600650 = validateParameter(valid_600650, JString, required = true,
                                 default = nil)
  if valid_600650 != nil:
    section.add "ConnectorDefinitionId", valid_600650
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
  var valid_600651 = header.getOrDefault("X-Amz-Date")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Date", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Security-Token")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Security-Token", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Content-Sha256", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Algorithm")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Algorithm", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Signature")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Signature", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-SignedHeaders", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Credential")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Credential", valid_600657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600658: Call_DeleteConnectorDefinition_600647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_600658.validator(path, query, header, formData, body)
  let scheme = call_600658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600658.url(scheme.get, call_600658.host, call_600658.base,
                         call_600658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600658, url, valid)

proc call*(call_600659: Call_DeleteConnectorDefinition_600647;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_600660 = newJObject()
  add(path_600660, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_600659.call(path_600660, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_600647(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_600648, base: "/",
    url: url_DeleteConnectorDefinition_600649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_600675 = ref object of OpenApiRestCall_599352
proc url_UpdateCoreDefinition_600677(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCoreDefinition_600676(path: JsonNode; query: JsonNode;
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
  var valid_600678 = path.getOrDefault("CoreDefinitionId")
  valid_600678 = validateParameter(valid_600678, JString, required = true,
                                 default = nil)
  if valid_600678 != nil:
    section.add "CoreDefinitionId", valid_600678
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
  var valid_600679 = header.getOrDefault("X-Amz-Date")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Date", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Security-Token")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Security-Token", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Content-Sha256", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Algorithm")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Algorithm", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Signature")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Signature", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-SignedHeaders", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Credential")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Credential", valid_600685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600687: Call_UpdateCoreDefinition_600675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_600687.validator(path, query, header, formData, body)
  let scheme = call_600687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600687.url(scheme.get, call_600687.host, call_600687.base,
                         call_600687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600687, url, valid)

proc call*(call_600688: Call_UpdateCoreDefinition_600675; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_600689 = newJObject()
  var body_600690 = newJObject()
  add(path_600689, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_600690 = body
  result = call_600688.call(path_600689, nil, nil, nil, body_600690)

var updateCoreDefinition* = Call_UpdateCoreDefinition_600675(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_600676, base: "/",
    url: url_UpdateCoreDefinition_600677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_600661 = ref object of OpenApiRestCall_599352
proc url_GetCoreDefinition_600663(protocol: Scheme; host: string; base: string;
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

proc validate_GetCoreDefinition_600662(path: JsonNode; query: JsonNode;
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
  var valid_600664 = path.getOrDefault("CoreDefinitionId")
  valid_600664 = validateParameter(valid_600664, JString, required = true,
                                 default = nil)
  if valid_600664 != nil:
    section.add "CoreDefinitionId", valid_600664
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
  var valid_600665 = header.getOrDefault("X-Amz-Date")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Date", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Security-Token")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Security-Token", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Content-Sha256", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Algorithm")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Algorithm", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Signature")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Signature", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-SignedHeaders", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Credential")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Credential", valid_600671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600672: Call_GetCoreDefinition_600661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_600672.validator(path, query, header, formData, body)
  let scheme = call_600672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600672.url(scheme.get, call_600672.host, call_600672.base,
                         call_600672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600672, url, valid)

proc call*(call_600673: Call_GetCoreDefinition_600661; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_600674 = newJObject()
  add(path_600674, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_600673.call(path_600674, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_600661(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_600662, base: "/",
    url: url_GetCoreDefinition_600663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_600691 = ref object of OpenApiRestCall_599352
proc url_DeleteCoreDefinition_600693(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCoreDefinition_600692(path: JsonNode; query: JsonNode;
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
  var valid_600694 = path.getOrDefault("CoreDefinitionId")
  valid_600694 = validateParameter(valid_600694, JString, required = true,
                                 default = nil)
  if valid_600694 != nil:
    section.add "CoreDefinitionId", valid_600694
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
  var valid_600695 = header.getOrDefault("X-Amz-Date")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Date", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Security-Token")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Security-Token", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Content-Sha256", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Algorithm")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Algorithm", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Signature")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Signature", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-SignedHeaders", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Credential")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Credential", valid_600701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600702: Call_DeleteCoreDefinition_600691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_600702.validator(path, query, header, formData, body)
  let scheme = call_600702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600702.url(scheme.get, call_600702.host, call_600702.base,
                         call_600702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600702, url, valid)

proc call*(call_600703: Call_DeleteCoreDefinition_600691; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_600704 = newJObject()
  add(path_600704, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_600703.call(path_600704, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_600691(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_600692, base: "/",
    url: url_DeleteCoreDefinition_600693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_600719 = ref object of OpenApiRestCall_599352
proc url_UpdateDeviceDefinition_600721(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceDefinition_600720(path: JsonNode; query: JsonNode;
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
  var valid_600722 = path.getOrDefault("DeviceDefinitionId")
  valid_600722 = validateParameter(valid_600722, JString, required = true,
                                 default = nil)
  if valid_600722 != nil:
    section.add "DeviceDefinitionId", valid_600722
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
  var valid_600723 = header.getOrDefault("X-Amz-Date")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Date", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Security-Token")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Security-Token", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Content-Sha256", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Algorithm")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Algorithm", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Signature")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Signature", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-SignedHeaders", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Credential")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Credential", valid_600729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600731: Call_UpdateDeviceDefinition_600719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_600731.validator(path, query, header, formData, body)
  let scheme = call_600731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600731.url(scheme.get, call_600731.host, call_600731.base,
                         call_600731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600731, url, valid)

proc call*(call_600732: Call_UpdateDeviceDefinition_600719;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_600733 = newJObject()
  var body_600734 = newJObject()
  add(path_600733, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_600734 = body
  result = call_600732.call(path_600733, nil, nil, nil, body_600734)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_600719(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_600720, base: "/",
    url: url_UpdateDeviceDefinition_600721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_600705 = ref object of OpenApiRestCall_599352
proc url_GetDeviceDefinition_600707(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceDefinition_600706(path: JsonNode; query: JsonNode;
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
  var valid_600708 = path.getOrDefault("DeviceDefinitionId")
  valid_600708 = validateParameter(valid_600708, JString, required = true,
                                 default = nil)
  if valid_600708 != nil:
    section.add "DeviceDefinitionId", valid_600708
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
  var valid_600709 = header.getOrDefault("X-Amz-Date")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Date", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Security-Token")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Security-Token", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Content-Sha256", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Algorithm")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Algorithm", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Signature")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Signature", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-SignedHeaders", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Credential")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Credential", valid_600715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600716: Call_GetDeviceDefinition_600705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_600716.validator(path, query, header, formData, body)
  let scheme = call_600716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600716.url(scheme.get, call_600716.host, call_600716.base,
                         call_600716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600716, url, valid)

proc call*(call_600717: Call_GetDeviceDefinition_600705; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_600718 = newJObject()
  add(path_600718, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_600717.call(path_600718, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_600705(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_600706, base: "/",
    url: url_GetDeviceDefinition_600707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_600735 = ref object of OpenApiRestCall_599352
proc url_DeleteDeviceDefinition_600737(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceDefinition_600736(path: JsonNode; query: JsonNode;
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
  var valid_600738 = path.getOrDefault("DeviceDefinitionId")
  valid_600738 = validateParameter(valid_600738, JString, required = true,
                                 default = nil)
  if valid_600738 != nil:
    section.add "DeviceDefinitionId", valid_600738
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
  var valid_600739 = header.getOrDefault("X-Amz-Date")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Date", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Security-Token")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Security-Token", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Content-Sha256", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Algorithm")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Algorithm", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Signature")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Signature", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-SignedHeaders", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Credential")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Credential", valid_600745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600746: Call_DeleteDeviceDefinition_600735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_600746.validator(path, query, header, formData, body)
  let scheme = call_600746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600746.url(scheme.get, call_600746.host, call_600746.base,
                         call_600746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600746, url, valid)

proc call*(call_600747: Call_DeleteDeviceDefinition_600735;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_600748 = newJObject()
  add(path_600748, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_600747.call(path_600748, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_600735(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_600736, base: "/",
    url: url_DeleteDeviceDefinition_600737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_600763 = ref object of OpenApiRestCall_599352
proc url_UpdateFunctionDefinition_600765(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionDefinition_600764(path: JsonNode; query: JsonNode;
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
  var valid_600766 = path.getOrDefault("FunctionDefinitionId")
  valid_600766 = validateParameter(valid_600766, JString, required = true,
                                 default = nil)
  if valid_600766 != nil:
    section.add "FunctionDefinitionId", valid_600766
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
  var valid_600767 = header.getOrDefault("X-Amz-Date")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Date", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Security-Token")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Security-Token", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Content-Sha256", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Algorithm")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Algorithm", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Signature")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Signature", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-SignedHeaders", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Credential")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Credential", valid_600773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600775: Call_UpdateFunctionDefinition_600763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_600775.validator(path, query, header, formData, body)
  let scheme = call_600775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600775.url(scheme.get, call_600775.host, call_600775.base,
                         call_600775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600775, url, valid)

proc call*(call_600776: Call_UpdateFunctionDefinition_600763;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_600777 = newJObject()
  var body_600778 = newJObject()
  add(path_600777, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_600778 = body
  result = call_600776.call(path_600777, nil, nil, nil, body_600778)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_600763(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_600764, base: "/",
    url: url_UpdateFunctionDefinition_600765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_600749 = ref object of OpenApiRestCall_599352
proc url_GetFunctionDefinition_600751(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionDefinition_600750(path: JsonNode; query: JsonNode;
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
  var valid_600752 = path.getOrDefault("FunctionDefinitionId")
  valid_600752 = validateParameter(valid_600752, JString, required = true,
                                 default = nil)
  if valid_600752 != nil:
    section.add "FunctionDefinitionId", valid_600752
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
  var valid_600753 = header.getOrDefault("X-Amz-Date")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Date", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Security-Token")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Security-Token", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-Content-Sha256", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Algorithm")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Algorithm", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-Signature")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Signature", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-SignedHeaders", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-Credential")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Credential", valid_600759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600760: Call_GetFunctionDefinition_600749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_600760.validator(path, query, header, formData, body)
  let scheme = call_600760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600760.url(scheme.get, call_600760.host, call_600760.base,
                         call_600760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600760, url, valid)

proc call*(call_600761: Call_GetFunctionDefinition_600749;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_600762 = newJObject()
  add(path_600762, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_600761.call(path_600762, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_600749(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_600750, base: "/",
    url: url_GetFunctionDefinition_600751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_600779 = ref object of OpenApiRestCall_599352
proc url_DeleteFunctionDefinition_600781(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionDefinition_600780(path: JsonNode; query: JsonNode;
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
  var valid_600782 = path.getOrDefault("FunctionDefinitionId")
  valid_600782 = validateParameter(valid_600782, JString, required = true,
                                 default = nil)
  if valid_600782 != nil:
    section.add "FunctionDefinitionId", valid_600782
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
  var valid_600783 = header.getOrDefault("X-Amz-Date")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Date", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Security-Token")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Security-Token", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-Content-Sha256", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Algorithm")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Algorithm", valid_600786
  var valid_600787 = header.getOrDefault("X-Amz-Signature")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Signature", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-SignedHeaders", valid_600788
  var valid_600789 = header.getOrDefault("X-Amz-Credential")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "X-Amz-Credential", valid_600789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600790: Call_DeleteFunctionDefinition_600779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_600790.validator(path, query, header, formData, body)
  let scheme = call_600790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600790.url(scheme.get, call_600790.host, call_600790.base,
                         call_600790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600790, url, valid)

proc call*(call_600791: Call_DeleteFunctionDefinition_600779;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_600792 = newJObject()
  add(path_600792, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_600791.call(path_600792, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_600779(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_600780, base: "/",
    url: url_DeleteFunctionDefinition_600781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_600807 = ref object of OpenApiRestCall_599352
proc url_UpdateGroup_600809(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_600808(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600810 = path.getOrDefault("GroupId")
  valid_600810 = validateParameter(valid_600810, JString, required = true,
                                 default = nil)
  if valid_600810 != nil:
    section.add "GroupId", valid_600810
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
  var valid_600811 = header.getOrDefault("X-Amz-Date")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Date", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Security-Token")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Security-Token", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Content-Sha256", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Algorithm")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Algorithm", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Signature")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Signature", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-SignedHeaders", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Credential")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Credential", valid_600817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600819: Call_UpdateGroup_600807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_600819.validator(path, query, header, formData, body)
  let scheme = call_600819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600819.url(scheme.get, call_600819.host, call_600819.base,
                         call_600819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600819, url, valid)

proc call*(call_600820: Call_UpdateGroup_600807; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_600821 = newJObject()
  var body_600822 = newJObject()
  add(path_600821, "GroupId", newJString(GroupId))
  if body != nil:
    body_600822 = body
  result = call_600820.call(path_600821, nil, nil, nil, body_600822)

var updateGroup* = Call_UpdateGroup_600807(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_600808,
                                        base: "/", url: url_UpdateGroup_600809,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_600793 = ref object of OpenApiRestCall_599352
proc url_GetGroup_600795(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_600794(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600796 = path.getOrDefault("GroupId")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = nil)
  if valid_600796 != nil:
    section.add "GroupId", valid_600796
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
  var valid_600797 = header.getOrDefault("X-Amz-Date")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Date", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Security-Token")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Security-Token", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Content-Sha256", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Algorithm")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Algorithm", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Signature")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Signature", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-SignedHeaders", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Credential")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Credential", valid_600803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600804: Call_GetGroup_600793; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_600804.validator(path, query, header, formData, body)
  let scheme = call_600804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600804.url(scheme.get, call_600804.host, call_600804.base,
                         call_600804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600804, url, valid)

proc call*(call_600805: Call_GetGroup_600793; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_600806 = newJObject()
  add(path_600806, "GroupId", newJString(GroupId))
  result = call_600805.call(path_600806, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_600793(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_600794, base: "/",
                                  url: url_GetGroup_600795,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_600823 = ref object of OpenApiRestCall_599352
proc url_DeleteGroup_600825(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_600824(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600826 = path.getOrDefault("GroupId")
  valid_600826 = validateParameter(valid_600826, JString, required = true,
                                 default = nil)
  if valid_600826 != nil:
    section.add "GroupId", valid_600826
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
  var valid_600827 = header.getOrDefault("X-Amz-Date")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Date", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Security-Token")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Security-Token", valid_600828
  var valid_600829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "X-Amz-Content-Sha256", valid_600829
  var valid_600830 = header.getOrDefault("X-Amz-Algorithm")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "X-Amz-Algorithm", valid_600830
  var valid_600831 = header.getOrDefault("X-Amz-Signature")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-Signature", valid_600831
  var valid_600832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-SignedHeaders", valid_600832
  var valid_600833 = header.getOrDefault("X-Amz-Credential")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Credential", valid_600833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600834: Call_DeleteGroup_600823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_600834.validator(path, query, header, formData, body)
  let scheme = call_600834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600834.url(scheme.get, call_600834.host, call_600834.base,
                         call_600834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600834, url, valid)

proc call*(call_600835: Call_DeleteGroup_600823; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_600836 = newJObject()
  add(path_600836, "GroupId", newJString(GroupId))
  result = call_600835.call(path_600836, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_600823(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_600824,
                                        base: "/", url: url_DeleteGroup_600825,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_600851 = ref object of OpenApiRestCall_599352
proc url_UpdateLoggerDefinition_600853(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLoggerDefinition_600852(path: JsonNode; query: JsonNode;
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
  var valid_600854 = path.getOrDefault("LoggerDefinitionId")
  valid_600854 = validateParameter(valid_600854, JString, required = true,
                                 default = nil)
  if valid_600854 != nil:
    section.add "LoggerDefinitionId", valid_600854
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
  var valid_600855 = header.getOrDefault("X-Amz-Date")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Date", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Security-Token")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Security-Token", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Content-Sha256", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Algorithm")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Algorithm", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Signature")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Signature", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-SignedHeaders", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Credential")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Credential", valid_600861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600863: Call_UpdateLoggerDefinition_600851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_600863.validator(path, query, header, formData, body)
  let scheme = call_600863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600863.url(scheme.get, call_600863.host, call_600863.base,
                         call_600863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600863, url, valid)

proc call*(call_600864: Call_UpdateLoggerDefinition_600851;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_600865 = newJObject()
  var body_600866 = newJObject()
  add(path_600865, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_600866 = body
  result = call_600864.call(path_600865, nil, nil, nil, body_600866)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_600851(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_600852, base: "/",
    url: url_UpdateLoggerDefinition_600853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_600837 = ref object of OpenApiRestCall_599352
proc url_GetLoggerDefinition_600839(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoggerDefinition_600838(path: JsonNode; query: JsonNode;
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
  var valid_600840 = path.getOrDefault("LoggerDefinitionId")
  valid_600840 = validateParameter(valid_600840, JString, required = true,
                                 default = nil)
  if valid_600840 != nil:
    section.add "LoggerDefinitionId", valid_600840
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
  var valid_600841 = header.getOrDefault("X-Amz-Date")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Date", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Security-Token")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Security-Token", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Content-Sha256", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Algorithm")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Algorithm", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Signature")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Signature", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-SignedHeaders", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Credential")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Credential", valid_600847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600848: Call_GetLoggerDefinition_600837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_600848.validator(path, query, header, formData, body)
  let scheme = call_600848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600848.url(scheme.get, call_600848.host, call_600848.base,
                         call_600848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600848, url, valid)

proc call*(call_600849: Call_GetLoggerDefinition_600837; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_600850 = newJObject()
  add(path_600850, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_600849.call(path_600850, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_600837(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_600838, base: "/",
    url: url_GetLoggerDefinition_600839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_600867 = ref object of OpenApiRestCall_599352
proc url_DeleteLoggerDefinition_600869(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoggerDefinition_600868(path: JsonNode; query: JsonNode;
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
  var valid_600870 = path.getOrDefault("LoggerDefinitionId")
  valid_600870 = validateParameter(valid_600870, JString, required = true,
                                 default = nil)
  if valid_600870 != nil:
    section.add "LoggerDefinitionId", valid_600870
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
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600878: Call_DeleteLoggerDefinition_600867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_600878.validator(path, query, header, formData, body)
  let scheme = call_600878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600878.url(scheme.get, call_600878.host, call_600878.base,
                         call_600878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600878, url, valid)

proc call*(call_600879: Call_DeleteLoggerDefinition_600867;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_600880 = newJObject()
  add(path_600880, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_600879.call(path_600880, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_600867(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_600868, base: "/",
    url: url_DeleteLoggerDefinition_600869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_600895 = ref object of OpenApiRestCall_599352
proc url_UpdateResourceDefinition_600897(protocol: Scheme; host: string;
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

proc validate_UpdateResourceDefinition_600896(path: JsonNode; query: JsonNode;
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
  var valid_600898 = path.getOrDefault("ResourceDefinitionId")
  valid_600898 = validateParameter(valid_600898, JString, required = true,
                                 default = nil)
  if valid_600898 != nil:
    section.add "ResourceDefinitionId", valid_600898
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Content-Sha256", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Algorithm")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Algorithm", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Signature")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Signature", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-SignedHeaders", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Credential")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Credential", valid_600905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600907: Call_UpdateResourceDefinition_600895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_600907.validator(path, query, header, formData, body)
  let scheme = call_600907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600907.url(scheme.get, call_600907.host, call_600907.base,
                         call_600907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600907, url, valid)

proc call*(call_600908: Call_UpdateResourceDefinition_600895;
          ResourceDefinitionId: string; body: JsonNode): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  ##   body: JObject (required)
  var path_600909 = newJObject()
  var body_600910 = newJObject()
  add(path_600909, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  if body != nil:
    body_600910 = body
  result = call_600908.call(path_600909, nil, nil, nil, body_600910)

var updateResourceDefinition* = Call_UpdateResourceDefinition_600895(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_600896, base: "/",
    url: url_UpdateResourceDefinition_600897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_600881 = ref object of OpenApiRestCall_599352
proc url_GetResourceDefinition_600883(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceDefinition_600882(path: JsonNode; query: JsonNode;
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
  var valid_600884 = path.getOrDefault("ResourceDefinitionId")
  valid_600884 = validateParameter(valid_600884, JString, required = true,
                                 default = nil)
  if valid_600884 != nil:
    section.add "ResourceDefinitionId", valid_600884
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
  var valid_600885 = header.getOrDefault("X-Amz-Date")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Date", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Security-Token")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Security-Token", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Content-Sha256", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Algorithm")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Algorithm", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Signature")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Signature", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-SignedHeaders", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Credential")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Credential", valid_600891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600892: Call_GetResourceDefinition_600881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_600892.validator(path, query, header, formData, body)
  let scheme = call_600892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600892.url(scheme.get, call_600892.host, call_600892.base,
                         call_600892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600892, url, valid)

proc call*(call_600893: Call_GetResourceDefinition_600881;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_600894 = newJObject()
  add(path_600894, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_600893.call(path_600894, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_600881(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_600882, base: "/",
    url: url_GetResourceDefinition_600883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_600911 = ref object of OpenApiRestCall_599352
proc url_DeleteResourceDefinition_600913(protocol: Scheme; host: string;
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

proc validate_DeleteResourceDefinition_600912(path: JsonNode; query: JsonNode;
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
  var valid_600914 = path.getOrDefault("ResourceDefinitionId")
  valid_600914 = validateParameter(valid_600914, JString, required = true,
                                 default = nil)
  if valid_600914 != nil:
    section.add "ResourceDefinitionId", valid_600914
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
  var valid_600915 = header.getOrDefault("X-Amz-Date")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Date", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Security-Token")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Security-Token", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Content-Sha256", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Algorithm")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Algorithm", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Signature")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Signature", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-SignedHeaders", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Credential")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Credential", valid_600921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600922: Call_DeleteResourceDefinition_600911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_600922.validator(path, query, header, formData, body)
  let scheme = call_600922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600922.url(scheme.get, call_600922.host, call_600922.base,
                         call_600922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600922, url, valid)

proc call*(call_600923: Call_DeleteResourceDefinition_600911;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_600924 = newJObject()
  add(path_600924, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_600923.call(path_600924, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_600911(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_600912, base: "/",
    url: url_DeleteResourceDefinition_600913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_600939 = ref object of OpenApiRestCall_599352
proc url_UpdateSubscriptionDefinition_600941(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_600940(path: JsonNode; query: JsonNode;
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
  var valid_600942 = path.getOrDefault("SubscriptionDefinitionId")
  valid_600942 = validateParameter(valid_600942, JString, required = true,
                                 default = nil)
  if valid_600942 != nil:
    section.add "SubscriptionDefinitionId", valid_600942
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
  var valid_600943 = header.getOrDefault("X-Amz-Date")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-Date", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Security-Token")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Security-Token", valid_600944
  var valid_600945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-Content-Sha256", valid_600945
  var valid_600946 = header.getOrDefault("X-Amz-Algorithm")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Algorithm", valid_600946
  var valid_600947 = header.getOrDefault("X-Amz-Signature")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "X-Amz-Signature", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-SignedHeaders", valid_600948
  var valid_600949 = header.getOrDefault("X-Amz-Credential")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Credential", valid_600949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600951: Call_UpdateSubscriptionDefinition_600939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_600951.validator(path, query, header, formData, body)
  let scheme = call_600951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600951.url(scheme.get, call_600951.host, call_600951.base,
                         call_600951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600951, url, valid)

proc call*(call_600952: Call_UpdateSubscriptionDefinition_600939;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_600953 = newJObject()
  var body_600954 = newJObject()
  add(path_600953, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_600954 = body
  result = call_600952.call(path_600953, nil, nil, nil, body_600954)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_600939(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_600940, base: "/",
    url: url_UpdateSubscriptionDefinition_600941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_600925 = ref object of OpenApiRestCall_599352
proc url_GetSubscriptionDefinition_600927(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_600926(path: JsonNode; query: JsonNode;
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
  var valid_600928 = path.getOrDefault("SubscriptionDefinitionId")
  valid_600928 = validateParameter(valid_600928, JString, required = true,
                                 default = nil)
  if valid_600928 != nil:
    section.add "SubscriptionDefinitionId", valid_600928
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
  var valid_600929 = header.getOrDefault("X-Amz-Date")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Date", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Security-Token")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Security-Token", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Content-Sha256", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-Algorithm")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-Algorithm", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Signature")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Signature", valid_600933
  var valid_600934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-SignedHeaders", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Credential")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Credential", valid_600935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600936: Call_GetSubscriptionDefinition_600925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_600936.validator(path, query, header, formData, body)
  let scheme = call_600936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600936.url(scheme.get, call_600936.host, call_600936.base,
                         call_600936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600936, url, valid)

proc call*(call_600937: Call_GetSubscriptionDefinition_600925;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_600938 = newJObject()
  add(path_600938, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_600937.call(path_600938, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_600925(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_600926, base: "/",
    url: url_GetSubscriptionDefinition_600927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_600955 = ref object of OpenApiRestCall_599352
proc url_DeleteSubscriptionDefinition_600957(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_600956(path: JsonNode; query: JsonNode;
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
  var valid_600958 = path.getOrDefault("SubscriptionDefinitionId")
  valid_600958 = validateParameter(valid_600958, JString, required = true,
                                 default = nil)
  if valid_600958 != nil:
    section.add "SubscriptionDefinitionId", valid_600958
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
  var valid_600959 = header.getOrDefault("X-Amz-Date")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Date", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Security-Token")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Security-Token", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Content-Sha256", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Algorithm")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Algorithm", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Signature")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Signature", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-SignedHeaders", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Credential")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Credential", valid_600965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600966: Call_DeleteSubscriptionDefinition_600955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_600966.validator(path, query, header, formData, body)
  let scheme = call_600966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600966.url(scheme.get, call_600966.host, call_600966.base,
                         call_600966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600966, url, valid)

proc call*(call_600967: Call_DeleteSubscriptionDefinition_600955;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_600968 = newJObject()
  add(path_600968, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_600967.call(path_600968, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_600955(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_600956, base: "/",
    url: url_DeleteSubscriptionDefinition_600957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_600969 = ref object of OpenApiRestCall_599352
proc url_GetBulkDeploymentStatus_600971(protocol: Scheme; host: string; base: string;
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

proc validate_GetBulkDeploymentStatus_600970(path: JsonNode; query: JsonNode;
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
  var valid_600972 = path.getOrDefault("BulkDeploymentId")
  valid_600972 = validateParameter(valid_600972, JString, required = true,
                                 default = nil)
  if valid_600972 != nil:
    section.add "BulkDeploymentId", valid_600972
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
  var valid_600973 = header.getOrDefault("X-Amz-Date")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Date", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Security-Token")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Security-Token", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Content-Sha256", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Algorithm")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Algorithm", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Signature")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Signature", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-SignedHeaders", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Credential")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Credential", valid_600979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600980: Call_GetBulkDeploymentStatus_600969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_600980.validator(path, query, header, formData, body)
  let scheme = call_600980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600980.url(scheme.get, call_600980.host, call_600980.base,
                         call_600980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600980, url, valid)

proc call*(call_600981: Call_GetBulkDeploymentStatus_600969;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_600982 = newJObject()
  add(path_600982, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_600981.call(path_600982, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_600969(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_600970, base: "/",
    url: url_GetBulkDeploymentStatus_600971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_600997 = ref object of OpenApiRestCall_599352
proc url_UpdateConnectivityInfo_600999(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnectivityInfo_600998(path: JsonNode; query: JsonNode;
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
  var valid_601000 = path.getOrDefault("ThingName")
  valid_601000 = validateParameter(valid_601000, JString, required = true,
                                 default = nil)
  if valid_601000 != nil:
    section.add "ThingName", valid_601000
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
  var valid_601001 = header.getOrDefault("X-Amz-Date")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Date", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-Security-Token")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-Security-Token", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-Content-Sha256", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-Algorithm")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Algorithm", valid_601004
  var valid_601005 = header.getOrDefault("X-Amz-Signature")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Signature", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-SignedHeaders", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Credential")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Credential", valid_601007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601009: Call_UpdateConnectivityInfo_600997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_601009.validator(path, query, header, formData, body)
  let scheme = call_601009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601009.url(scheme.get, call_601009.host, call_601009.base,
                         call_601009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601009, url, valid)

proc call*(call_601010: Call_UpdateConnectivityInfo_600997; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_601011 = newJObject()
  var body_601012 = newJObject()
  add(path_601011, "ThingName", newJString(ThingName))
  if body != nil:
    body_601012 = body
  result = call_601010.call(path_601011, nil, nil, nil, body_601012)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_600997(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_600998, base: "/",
    url: url_UpdateConnectivityInfo_600999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_600983 = ref object of OpenApiRestCall_599352
proc url_GetConnectivityInfo_600985(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectivityInfo_600984(path: JsonNode; query: JsonNode;
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
  var valid_600986 = path.getOrDefault("ThingName")
  valid_600986 = validateParameter(valid_600986, JString, required = true,
                                 default = nil)
  if valid_600986 != nil:
    section.add "ThingName", valid_600986
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
  var valid_600987 = header.getOrDefault("X-Amz-Date")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Date", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-Security-Token")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Security-Token", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Content-Sha256", valid_600989
  var valid_600990 = header.getOrDefault("X-Amz-Algorithm")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Algorithm", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Signature")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Signature", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-SignedHeaders", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-Credential")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-Credential", valid_600993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600994: Call_GetConnectivityInfo_600983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_600994.validator(path, query, header, formData, body)
  let scheme = call_600994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600994.url(scheme.get, call_600994.host, call_600994.base,
                         call_600994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600994, url, valid)

proc call*(call_600995: Call_GetConnectivityInfo_600983; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_600996 = newJObject()
  add(path_600996, "ThingName", newJString(ThingName))
  result = call_600995.call(path_600996, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_600983(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_600984, base: "/",
    url: url_GetConnectivityInfo_600985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_601013 = ref object of OpenApiRestCall_599352
proc url_GetConnectorDefinitionVersion_601015(protocol: Scheme; host: string;
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

proc validate_GetConnectorDefinitionVersion_601014(path: JsonNode; query: JsonNode;
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
  var valid_601016 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_601016 = validateParameter(valid_601016, JString, required = true,
                                 default = nil)
  if valid_601016 != nil:
    section.add "ConnectorDefinitionVersionId", valid_601016
  var valid_601017 = path.getOrDefault("ConnectorDefinitionId")
  valid_601017 = validateParameter(valid_601017, JString, required = true,
                                 default = nil)
  if valid_601017 != nil:
    section.add "ConnectorDefinitionId", valid_601017
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_601018 = query.getOrDefault("NextToken")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "NextToken", valid_601018
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
  var valid_601019 = header.getOrDefault("X-Amz-Date")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-Date", valid_601019
  var valid_601020 = header.getOrDefault("X-Amz-Security-Token")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Security-Token", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Content-Sha256", valid_601021
  var valid_601022 = header.getOrDefault("X-Amz-Algorithm")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Algorithm", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Signature")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Signature", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-SignedHeaders", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Credential")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Credential", valid_601025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601026: Call_GetConnectorDefinitionVersion_601013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_601026.validator(path, query, header, formData, body)
  let scheme = call_601026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601026.url(scheme.get, call_601026.host, call_601026.base,
                         call_601026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601026, url, valid)

proc call*(call_601027: Call_GetConnectorDefinitionVersion_601013;
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
  var path_601028 = newJObject()
  var query_601029 = newJObject()
  add(query_601029, "NextToken", newJString(NextToken))
  add(path_601028, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(path_601028, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_601027.call(path_601028, query_601029, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_601013(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_601014, base: "/",
    url: url_GetConnectorDefinitionVersion_601015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_601030 = ref object of OpenApiRestCall_599352
proc url_GetCoreDefinitionVersion_601032(protocol: Scheme; host: string;
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

proc validate_GetCoreDefinitionVersion_601031(path: JsonNode; query: JsonNode;
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
  var valid_601033 = path.getOrDefault("CoreDefinitionId")
  valid_601033 = validateParameter(valid_601033, JString, required = true,
                                 default = nil)
  if valid_601033 != nil:
    section.add "CoreDefinitionId", valid_601033
  var valid_601034 = path.getOrDefault("CoreDefinitionVersionId")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "CoreDefinitionVersionId", valid_601034
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601042: Call_GetCoreDefinitionVersion_601030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_601042.validator(path, query, header, formData, body)
  let scheme = call_601042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601042.url(scheme.get, call_601042.host, call_601042.base,
                         call_601042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601042, url, valid)

proc call*(call_601043: Call_GetCoreDefinitionVersion_601030;
          CoreDefinitionId: string; CoreDefinitionVersionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  var path_601044 = newJObject()
  add(path_601044, "CoreDefinitionId", newJString(CoreDefinitionId))
  add(path_601044, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  result = call_601043.call(path_601044, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_601030(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_601031, base: "/",
    url: url_GetCoreDefinitionVersion_601032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_601045 = ref object of OpenApiRestCall_599352
proc url_GetDeploymentStatus_601047(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStatus_601046(path: JsonNode; query: JsonNode;
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
  var valid_601048 = path.getOrDefault("GroupId")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = nil)
  if valid_601048 != nil:
    section.add "GroupId", valid_601048
  var valid_601049 = path.getOrDefault("DeploymentId")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = nil)
  if valid_601049 != nil:
    section.add "DeploymentId", valid_601049
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
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Content-Sha256", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Algorithm")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Algorithm", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Signature")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Signature", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-SignedHeaders", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Credential")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Credential", valid_601056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601057: Call_GetDeploymentStatus_601045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_601057.validator(path, query, header, formData, body)
  let scheme = call_601057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601057.url(scheme.get, call_601057.host, call_601057.base,
                         call_601057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601057, url, valid)

proc call*(call_601058: Call_GetDeploymentStatus_601045; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_601059 = newJObject()
  add(path_601059, "GroupId", newJString(GroupId))
  add(path_601059, "DeploymentId", newJString(DeploymentId))
  result = call_601058.call(path_601059, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_601045(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_601046, base: "/",
    url: url_GetDeploymentStatus_601047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_601060 = ref object of OpenApiRestCall_599352
proc url_GetDeviceDefinitionVersion_601062(protocol: Scheme; host: string;
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

proc validate_GetDeviceDefinitionVersion_601061(path: JsonNode; query: JsonNode;
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
  var valid_601063 = path.getOrDefault("DeviceDefinitionId")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "DeviceDefinitionId", valid_601063
  var valid_601064 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "DeviceDefinitionVersionId", valid_601064
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_601065 = query.getOrDefault("NextToken")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "NextToken", valid_601065
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
  var valid_601066 = header.getOrDefault("X-Amz-Date")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Date", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Security-Token")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Security-Token", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Content-Sha256", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Algorithm")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Algorithm", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Signature")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Signature", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-SignedHeaders", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Credential")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Credential", valid_601072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601073: Call_GetDeviceDefinitionVersion_601060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_601073.validator(path, query, header, formData, body)
  let scheme = call_601073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601073.url(scheme.get, call_601073.host, call_601073.base,
                         call_601073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601073, url, valid)

proc call*(call_601074: Call_GetDeviceDefinitionVersion_601060;
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
  var path_601075 = newJObject()
  var query_601076 = newJObject()
  add(path_601075, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_601076, "NextToken", newJString(NextToken))
  add(path_601075, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_601074.call(path_601075, query_601076, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_601060(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_601061, base: "/",
    url: url_GetDeviceDefinitionVersion_601062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_601077 = ref object of OpenApiRestCall_599352
proc url_GetFunctionDefinitionVersion_601079(protocol: Scheme; host: string;
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

proc validate_GetFunctionDefinitionVersion_601078(path: JsonNode; query: JsonNode;
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
  var valid_601080 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = nil)
  if valid_601080 != nil:
    section.add "FunctionDefinitionVersionId", valid_601080
  var valid_601081 = path.getOrDefault("FunctionDefinitionId")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = nil)
  if valid_601081 != nil:
    section.add "FunctionDefinitionId", valid_601081
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_601082 = query.getOrDefault("NextToken")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "NextToken", valid_601082
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
  var valid_601083 = header.getOrDefault("X-Amz-Date")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Date", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Security-Token")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Security-Token", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Content-Sha256", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Algorithm")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Algorithm", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Signature", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-SignedHeaders", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Credential")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Credential", valid_601089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601090: Call_GetFunctionDefinitionVersion_601077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_601090.validator(path, query, header, formData, body)
  let scheme = call_601090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601090.url(scheme.get, call_601090.host, call_601090.base,
                         call_601090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601090, url, valid)

proc call*(call_601091: Call_GetFunctionDefinitionVersion_601077;
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
  var path_601092 = newJObject()
  var query_601093 = newJObject()
  add(path_601092, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_601093, "NextToken", newJString(NextToken))
  add(path_601092, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_601091.call(path_601092, query_601093, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_601077(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_601078, base: "/",
    url: url_GetFunctionDefinitionVersion_601079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_601094 = ref object of OpenApiRestCall_599352
proc url_GetGroupCertificateAuthority_601096(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_601095(path: JsonNode; query: JsonNode;
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
  var valid_601097 = path.getOrDefault("GroupId")
  valid_601097 = validateParameter(valid_601097, JString, required = true,
                                 default = nil)
  if valid_601097 != nil:
    section.add "GroupId", valid_601097
  var valid_601098 = path.getOrDefault("CertificateAuthorityId")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = nil)
  if valid_601098 != nil:
    section.add "CertificateAuthorityId", valid_601098
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
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Content-Sha256", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Algorithm")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Algorithm", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Signature")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Signature", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-SignedHeaders", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Credential")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Credential", valid_601105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_GetGroupCertificateAuthority_601094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601106, url, valid)

proc call*(call_601107: Call_GetGroupCertificateAuthority_601094; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_601108 = newJObject()
  add(path_601108, "GroupId", newJString(GroupId))
  add(path_601108, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_601107.call(path_601108, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_601094(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_601095, base: "/",
    url: url_GetGroupCertificateAuthority_601096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_601123 = ref object of OpenApiRestCall_599352
proc url_UpdateGroupCertificateConfiguration_601125(protocol: Scheme; host: string;
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

proc validate_UpdateGroupCertificateConfiguration_601124(path: JsonNode;
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
  var valid_601126 = path.getOrDefault("GroupId")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "GroupId", valid_601126
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
  var valid_601127 = header.getOrDefault("X-Amz-Date")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Date", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Security-Token")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Security-Token", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Content-Sha256", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Algorithm")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Algorithm", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Signature")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Signature", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-SignedHeaders", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Credential")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Credential", valid_601133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601135: Call_UpdateGroupCertificateConfiguration_601123;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_601135.validator(path, query, header, formData, body)
  let scheme = call_601135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601135.url(scheme.get, call_601135.host, call_601135.base,
                         call_601135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601135, url, valid)

proc call*(call_601136: Call_UpdateGroupCertificateConfiguration_601123;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_601137 = newJObject()
  var body_601138 = newJObject()
  add(path_601137, "GroupId", newJString(GroupId))
  if body != nil:
    body_601138 = body
  result = call_601136.call(path_601137, nil, nil, nil, body_601138)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_601123(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_601124, base: "/",
    url: url_UpdateGroupCertificateConfiguration_601125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_601109 = ref object of OpenApiRestCall_599352
proc url_GetGroupCertificateConfiguration_601111(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateConfiguration_601110(path: JsonNode;
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
  var valid_601112 = path.getOrDefault("GroupId")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = nil)
  if valid_601112 != nil:
    section.add "GroupId", valid_601112
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
  var valid_601113 = header.getOrDefault("X-Amz-Date")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Date", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Security-Token")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Security-Token", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Content-Sha256", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Algorithm")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Algorithm", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Signature")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Signature", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-SignedHeaders", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Credential")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Credential", valid_601119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_GetGroupCertificateConfiguration_601109;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601120, url, valid)

proc call*(call_601121: Call_GetGroupCertificateConfiguration_601109;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_601122 = newJObject()
  add(path_601122, "GroupId", newJString(GroupId))
  result = call_601121.call(path_601122, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_601109(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_601110, base: "/",
    url: url_GetGroupCertificateConfiguration_601111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_601139 = ref object of OpenApiRestCall_599352
proc url_GetGroupVersion_601141(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupVersion_601140(path: JsonNode; query: JsonNode;
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
  var valid_601142 = path.getOrDefault("GroupVersionId")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "GroupVersionId", valid_601142
  var valid_601143 = path.getOrDefault("GroupId")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = nil)
  if valid_601143 != nil:
    section.add "GroupId", valid_601143
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
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Content-Sha256", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Algorithm")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Algorithm", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Signature")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Signature", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-SignedHeaders", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Credential")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Credential", valid_601150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601151: Call_GetGroupVersion_601139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_601151.validator(path, query, header, formData, body)
  let scheme = call_601151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601151.url(scheme.get, call_601151.host, call_601151.base,
                         call_601151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601151, url, valid)

proc call*(call_601152: Call_GetGroupVersion_601139; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_601153 = newJObject()
  add(path_601153, "GroupVersionId", newJString(GroupVersionId))
  add(path_601153, "GroupId", newJString(GroupId))
  result = call_601152.call(path_601153, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_601139(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_601140, base: "/", url: url_GetGroupVersion_601141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_601154 = ref object of OpenApiRestCall_599352
proc url_GetLoggerDefinitionVersion_601156(protocol: Scheme; host: string;
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

proc validate_GetLoggerDefinitionVersion_601155(path: JsonNode; query: JsonNode;
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
  var valid_601157 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = nil)
  if valid_601157 != nil:
    section.add "LoggerDefinitionVersionId", valid_601157
  var valid_601158 = path.getOrDefault("LoggerDefinitionId")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "LoggerDefinitionId", valid_601158
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_601159 = query.getOrDefault("NextToken")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "NextToken", valid_601159
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
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Content-Sha256", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Algorithm")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Algorithm", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Signature")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Signature", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-SignedHeaders", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Credential")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Credential", valid_601166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_GetLoggerDefinitionVersion_601154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601167, url, valid)

proc call*(call_601168: Call_GetLoggerDefinitionVersion_601154;
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
  var path_601169 = newJObject()
  var query_601170 = newJObject()
  add(path_601169, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_601170, "NextToken", newJString(NextToken))
  add(path_601169, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_601168.call(path_601169, query_601170, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_601154(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_601155, base: "/",
    url: url_GetLoggerDefinitionVersion_601156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_601171 = ref object of OpenApiRestCall_599352
proc url_GetResourceDefinitionVersion_601173(protocol: Scheme; host: string;
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

proc validate_GetResourceDefinitionVersion_601172(path: JsonNode; query: JsonNode;
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
  var valid_601174 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "ResourceDefinitionVersionId", valid_601174
  var valid_601175 = path.getOrDefault("ResourceDefinitionId")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "ResourceDefinitionId", valid_601175
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
  var valid_601176 = header.getOrDefault("X-Amz-Date")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Date", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Security-Token")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Security-Token", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601183: Call_GetResourceDefinitionVersion_601171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_601183.validator(path, query, header, formData, body)
  let scheme = call_601183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601183.url(scheme.get, call_601183.host, call_601183.base,
                         call_601183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601183, url, valid)

proc call*(call_601184: Call_GetResourceDefinitionVersion_601171;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_601185 = newJObject()
  add(path_601185, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_601185, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_601184.call(path_601185, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_601171(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_601172, base: "/",
    url: url_GetResourceDefinitionVersion_601173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_601186 = ref object of OpenApiRestCall_599352
proc url_GetSubscriptionDefinitionVersion_601188(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinitionVersion_601187(path: JsonNode;
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
  var valid_601189 = path.getOrDefault("SubscriptionDefinitionId")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "SubscriptionDefinitionId", valid_601189
  var valid_601190 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_601190
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_601191 = query.getOrDefault("NextToken")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "NextToken", valid_601191
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
  var valid_601192 = header.getOrDefault("X-Amz-Date")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Date", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Security-Token")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Security-Token", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Content-Sha256", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Algorithm")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Algorithm", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Signature")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Signature", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-SignedHeaders", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Credential")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Credential", valid_601198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_GetSubscriptionDefinitionVersion_601186;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601199, url, valid)

proc call*(call_601200: Call_GetSubscriptionDefinitionVersion_601186;
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
  var path_601201 = newJObject()
  var query_601202 = newJObject()
  add(query_601202, "NextToken", newJString(NextToken))
  add(path_601201, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  add(path_601201, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  result = call_601200.call(path_601201, query_601202, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_601186(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_601187, base: "/",
    url: url_GetSubscriptionDefinitionVersion_601188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_601203 = ref object of OpenApiRestCall_599352
proc url_ListBulkDeploymentDetailedReports_601205(protocol: Scheme; host: string;
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

proc validate_ListBulkDeploymentDetailedReports_601204(path: JsonNode;
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
  var valid_601206 = path.getOrDefault("BulkDeploymentId")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "BulkDeploymentId", valid_601206
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  section = newJObject()
  var valid_601207 = query.getOrDefault("NextToken")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "NextToken", valid_601207
  var valid_601208 = query.getOrDefault("MaxResults")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "MaxResults", valid_601208
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
  var valid_601209 = header.getOrDefault("X-Amz-Date")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Date", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Security-Token")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Security-Token", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Content-Sha256", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Algorithm")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Algorithm", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Signature")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Signature", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-SignedHeaders", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Credential")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Credential", valid_601215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_ListBulkDeploymentDetailedReports_601203;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601216, url, valid)

proc call*(call_601217: Call_ListBulkDeploymentDetailedReports_601203;
          BulkDeploymentId: string; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_601218 = newJObject()
  var query_601219 = newJObject()
  add(query_601219, "NextToken", newJString(NextToken))
  add(query_601219, "MaxResults", newJString(MaxResults))
  add(path_601218, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_601217.call(path_601218, query_601219, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_601203(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_601204, base: "/",
    url: url_ListBulkDeploymentDetailedReports_601205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_601235 = ref object of OpenApiRestCall_599352
proc url_StartBulkDeployment_601237(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartBulkDeployment_601236(path: JsonNode; query: JsonNode;
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
  var valid_601238 = header.getOrDefault("X-Amz-Date")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Date", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Security-Token")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Security-Token", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Content-Sha256", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Algorithm")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Algorithm", valid_601241
  var valid_601242 = header.getOrDefault("X-Amzn-Client-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amzn-Client-Token", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Signature")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Signature", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-SignedHeaders", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Credential")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Credential", valid_601245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601247: Call_StartBulkDeployment_601235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_601247.validator(path, query, header, formData, body)
  let scheme = call_601247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601247.url(scheme.get, call_601247.host, call_601247.base,
                         call_601247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601247, url, valid)

proc call*(call_601248: Call_StartBulkDeployment_601235; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_601249 = newJObject()
  if body != nil:
    body_601249 = body
  result = call_601248.call(nil, nil, nil, nil, body_601249)

var startBulkDeployment* = Call_StartBulkDeployment_601235(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_601236, base: "/",
    url: url_StartBulkDeployment_601237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_601220 = ref object of OpenApiRestCall_599352
proc url_ListBulkDeployments_601222(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBulkDeployments_601221(path: JsonNode; query: JsonNode;
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
  var valid_601223 = query.getOrDefault("NextToken")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "NextToken", valid_601223
  var valid_601224 = query.getOrDefault("MaxResults")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "MaxResults", valid_601224
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
  var valid_601225 = header.getOrDefault("X-Amz-Date")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Date", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Security-Token")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Security-Token", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Content-Sha256", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Algorithm")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Algorithm", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Signature", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-SignedHeaders", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Credential")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Credential", valid_601231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601232: Call_ListBulkDeployments_601220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_601232.validator(path, query, header, formData, body)
  let scheme = call_601232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601232.url(scheme.get, call_601232.host, call_601232.base,
                         call_601232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601232, url, valid)

proc call*(call_601233: Call_ListBulkDeployments_601220; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  var query_601234 = newJObject()
  add(query_601234, "NextToken", newJString(NextToken))
  add(query_601234, "MaxResults", newJString(MaxResults))
  result = call_601233.call(nil, query_601234, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_601220(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_601221, base: "/",
    url: url_ListBulkDeployments_601222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601264 = ref object of OpenApiRestCall_599352
proc url_TagResource_601266(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_601265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601267 = path.getOrDefault("resource-arn")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "resource-arn", valid_601267
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
  var valid_601268 = header.getOrDefault("X-Amz-Date")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Date", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Security-Token")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Security-Token", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Content-Sha256", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Algorithm")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Algorithm", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Signature")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Signature", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-SignedHeaders", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Credential")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Credential", valid_601274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601276: Call_TagResource_601264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_601276.validator(path, query, header, formData, body)
  let scheme = call_601276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601276.url(scheme.get, call_601276.host, call_601276.base,
                         call_601276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601276, url, valid)

proc call*(call_601277: Call_TagResource_601264; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_601278 = newJObject()
  var body_601279 = newJObject()
  add(path_601278, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_601279 = body
  result = call_601277.call(path_601278, nil, nil, nil, body_601279)

var tagResource* = Call_TagResource_601264(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_601265,
                                        base: "/", url: url_TagResource_601266,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601250 = ref object of OpenApiRestCall_599352
proc url_ListTagsForResource_601252(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_601251(path: JsonNode; query: JsonNode;
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
  var valid_601253 = path.getOrDefault("resource-arn")
  valid_601253 = validateParameter(valid_601253, JString, required = true,
                                 default = nil)
  if valid_601253 != nil:
    section.add "resource-arn", valid_601253
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
  var valid_601254 = header.getOrDefault("X-Amz-Date")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Date", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Security-Token")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Security-Token", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Content-Sha256", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Algorithm")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Algorithm", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Signature")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Signature", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-SignedHeaders", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Credential")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Credential", valid_601260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601261: Call_ListTagsForResource_601250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_601261.validator(path, query, header, formData, body)
  let scheme = call_601261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601261.url(scheme.get, call_601261.host, call_601261.base,
                         call_601261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601261, url, valid)

proc call*(call_601262: Call_ListTagsForResource_601250; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_601263 = newJObject()
  add(path_601263, "resource-arn", newJString(resourceArn))
  result = call_601262.call(path_601263, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601250(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_601251, base: "/",
    url: url_ListTagsForResource_601252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_601280 = ref object of OpenApiRestCall_599352
proc url_ResetDeployments_601282(protocol: Scheme; host: string; base: string;
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

proc validate_ResetDeployments_601281(path: JsonNode; query: JsonNode;
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
  var valid_601283 = path.getOrDefault("GroupId")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = nil)
  if valid_601283 != nil:
    section.add "GroupId", valid_601283
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
  var valid_601284 = header.getOrDefault("X-Amz-Date")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Date", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Security-Token")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Security-Token", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Content-Sha256", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Algorithm")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Algorithm", valid_601287
  var valid_601288 = header.getOrDefault("X-Amzn-Client-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amzn-Client-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Signature")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Signature", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-SignedHeaders", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Credential")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Credential", valid_601291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601293: Call_ResetDeployments_601280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_601293.validator(path, query, header, formData, body)
  let scheme = call_601293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601293.url(scheme.get, call_601293.host, call_601293.base,
                         call_601293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601293, url, valid)

proc call*(call_601294: Call_ResetDeployments_601280; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_601295 = newJObject()
  var body_601296 = newJObject()
  add(path_601295, "GroupId", newJString(GroupId))
  if body != nil:
    body_601296 = body
  result = call_601294.call(path_601295, nil, nil, nil, body_601296)

var resetDeployments* = Call_ResetDeployments_601280(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_601281, base: "/",
    url: url_ResetDeployments_601282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_601297 = ref object of OpenApiRestCall_599352
proc url_StopBulkDeployment_601299(protocol: Scheme; host: string; base: string;
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

proc validate_StopBulkDeployment_601298(path: JsonNode; query: JsonNode;
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
  var valid_601300 = path.getOrDefault("BulkDeploymentId")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = nil)
  if valid_601300 != nil:
    section.add "BulkDeploymentId", valid_601300
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
  var valid_601301 = header.getOrDefault("X-Amz-Date")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Date", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Security-Token")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Security-Token", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Content-Sha256", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Algorithm")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Algorithm", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Signature")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Signature", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-SignedHeaders", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Credential")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Credential", valid_601307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601308: Call_StopBulkDeployment_601297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_601308.validator(path, query, header, formData, body)
  let scheme = call_601308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601308.url(scheme.get, call_601308.host, call_601308.base,
                         call_601308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601308, url, valid)

proc call*(call_601309: Call_StopBulkDeployment_601297; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_601310 = newJObject()
  add(path_601310, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_601309.call(path_601310, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_601297(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_601298, base: "/",
    url: url_StopBulkDeployment_601299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601311 = ref object of OpenApiRestCall_599352
proc url_UntagResource_601313(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_601312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601314 = path.getOrDefault("resource-arn")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = nil)
  if valid_601314 != nil:
    section.add "resource-arn", valid_601314
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601315 = query.getOrDefault("tagKeys")
  valid_601315 = validateParameter(valid_601315, JArray, required = true, default = nil)
  if valid_601315 != nil:
    section.add "tagKeys", valid_601315
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
  var valid_601316 = header.getOrDefault("X-Amz-Date")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Date", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Security-Token")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Security-Token", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Content-Sha256", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Algorithm")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Algorithm", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Signature", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-SignedHeaders", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Credential")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Credential", valid_601322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_UntagResource_601311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601323, url, valid)

proc call*(call_601324: Call_UntagResource_601311; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_601325 = newJObject()
  var query_601326 = newJObject()
  if tagKeys != nil:
    query_601326.add "tagKeys", tagKeys
  add(path_601325, "resource-arn", newJString(resourceArn))
  result = call_601324.call(path_601325, query_601326, nil, nil, nil)

var untagResource* = Call_UntagResource_601311(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_601312,
    base: "/", url: url_UntagResource_601313, schemes: {Scheme.Https, Scheme.Http})
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
