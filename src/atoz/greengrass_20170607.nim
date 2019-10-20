
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRoleToGroup_592957 = ref object of OpenApiRestCall_592348
proc url_AssociateRoleToGroup_592959(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRoleToGroup_592958(path: JsonNode; query: JsonNode;
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
  var valid_592960 = path.getOrDefault("GroupId")
  valid_592960 = validateParameter(valid_592960, JString, required = true,
                                 default = nil)
  if valid_592960 != nil:
    section.add "GroupId", valid_592960
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
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_AssociateRoleToGroup_592957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_AssociateRoleToGroup_592957; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_592971 = newJObject()
  var body_592972 = newJObject()
  add(path_592971, "GroupId", newJString(GroupId))
  if body != nil:
    body_592972 = body
  result = call_592970.call(path_592971, nil, nil, nil, body_592972)

var associateRoleToGroup* = Call_AssociateRoleToGroup_592957(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_592958, base: "/",
    url: url_AssociateRoleToGroup_592959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_592687 = ref object of OpenApiRestCall_592348
proc url_GetAssociatedRole_592689(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssociatedRole_592688(path: JsonNode; query: JsonNode;
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
  var valid_592815 = path.getOrDefault("GroupId")
  valid_592815 = validateParameter(valid_592815, JString, required = true,
                                 default = nil)
  if valid_592815 != nil:
    section.add "GroupId", valid_592815
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
  var valid_592816 = header.getOrDefault("X-Amz-Signature")
  valid_592816 = validateParameter(valid_592816, JString, required = false,
                                 default = nil)
  if valid_592816 != nil:
    section.add "X-Amz-Signature", valid_592816
  var valid_592817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Content-Sha256", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Date")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Date", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Credential")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Credential", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Security-Token")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Security-Token", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Algorithm")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Algorithm", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-SignedHeaders", valid_592822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592845: Call_GetAssociatedRole_592687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_592845.validator(path, query, header, formData, body)
  let scheme = call_592845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592845.url(scheme.get, call_592845.host, call_592845.base,
                         call_592845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592845, url, valid)

proc call*(call_592916: Call_GetAssociatedRole_592687; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_592917 = newJObject()
  add(path_592917, "GroupId", newJString(GroupId))
  result = call_592916.call(path_592917, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_592687(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_592688, base: "/",
    url: url_GetAssociatedRole_592689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_592973 = ref object of OpenApiRestCall_592348
proc url_DisassociateRoleFromGroup_592975(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_592974(path: JsonNode; query: JsonNode;
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
  var valid_592976 = path.getOrDefault("GroupId")
  valid_592976 = validateParameter(valid_592976, JString, required = true,
                                 default = nil)
  if valid_592976 != nil:
    section.add "GroupId", valid_592976
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
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Algorithm")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Algorithm", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-SignedHeaders", valid_592983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_DisassociateRoleFromGroup_592973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_DisassociateRoleFromGroup_592973; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_592986 = newJObject()
  add(path_592986, "GroupId", newJString(GroupId))
  result = call_592985.call(path_592986, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_592973(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_592974, base: "/",
    url: url_DisassociateRoleFromGroup_592975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_592999 = ref object of OpenApiRestCall_592348
proc url_AssociateServiceRoleToAccount_593001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateServiceRoleToAccount_593000(path: JsonNode; query: JsonNode;
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
  var valid_593002 = header.getOrDefault("X-Amz-Signature")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Signature", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Content-Sha256", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Date")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Date", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Credential")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Credential", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Security-Token")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Security-Token", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Algorithm")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Algorithm", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-SignedHeaders", valid_593008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_AssociateServiceRoleToAccount_592999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_AssociateServiceRoleToAccount_592999; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_593012 = newJObject()
  if body != nil:
    body_593012 = body
  result = call_593011.call(nil, nil, nil, nil, body_593012)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_592999(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_593000, base: "/",
    url: url_AssociateServiceRoleToAccount_593001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_592987 = ref object of OpenApiRestCall_592348
proc url_GetServiceRoleForAccount_592989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceRoleForAccount_592988(path: JsonNode; query: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Signature")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Signature", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Content-Sha256", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Date")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Date", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Credential")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Credential", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Security-Token")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Security-Token", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Algorithm")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Algorithm", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-SignedHeaders", valid_592996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592997: Call_GetServiceRoleForAccount_592987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_592997.validator(path, query, header, formData, body)
  let scheme = call_592997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592997.url(scheme.get, call_592997.host, call_592997.base,
                         call_592997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592997, url, valid)

proc call*(call_592998: Call_GetServiceRoleForAccount_592987): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_592998.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_592987(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_592988, base: "/",
    url: url_GetServiceRoleForAccount_592989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_593013 = ref object of OpenApiRestCall_592348
proc url_DisassociateServiceRoleFromAccount_593015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_593014(path: JsonNode;
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
  var valid_593016 = header.getOrDefault("X-Amz-Signature")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Signature", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Content-Sha256", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Date")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Date", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Credential")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Credential", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Security-Token")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Security-Token", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Algorithm")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Algorithm", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-SignedHeaders", valid_593022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593023: Call_DisassociateServiceRoleFromAccount_593013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_593023.validator(path, query, header, formData, body)
  let scheme = call_593023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593023.url(scheme.get, call_593023.host, call_593023.base,
                         call_593023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593023, url, valid)

proc call*(call_593024: Call_DisassociateServiceRoleFromAccount_593013): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_593024.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_593013(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_593014, base: "/",
    url: url_DisassociateServiceRoleFromAccount_593015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_593040 = ref object of OpenApiRestCall_592348
proc url_CreateConnectorDefinition_593042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnectorDefinition_593041(path: JsonNode; query: JsonNode;
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
  var valid_593043 = header.getOrDefault("X-Amz-Signature")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Signature", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Content-Sha256", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Date")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Date", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Credential")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Credential", valid_593046
  var valid_593047 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amzn-Client-Token", valid_593047
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

proc call*(call_593052: Call_CreateConnectorDefinition_593040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_593052.validator(path, query, header, formData, body)
  let scheme = call_593052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593052.url(scheme.get, call_593052.host, call_593052.base,
                         call_593052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593052, url, valid)

proc call*(call_593053: Call_CreateConnectorDefinition_593040; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_593054 = newJObject()
  if body != nil:
    body_593054 = body
  result = call_593053.call(nil, nil, nil, nil, body_593054)

var createConnectorDefinition* = Call_CreateConnectorDefinition_593040(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_593041, base: "/",
    url: url_CreateConnectorDefinition_593042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_593025 = ref object of OpenApiRestCall_592348
proc url_ListConnectorDefinitions_593027(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConnectorDefinitions_593026(path: JsonNode; query: JsonNode;
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
  var valid_593028 = query.getOrDefault("MaxResults")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "MaxResults", valid_593028
  var valid_593029 = query.getOrDefault("NextToken")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "NextToken", valid_593029
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
  var valid_593030 = header.getOrDefault("X-Amz-Signature")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Signature", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Content-Sha256", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Date")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Date", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Credential")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Credential", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Security-Token")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Security-Token", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Algorithm")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Algorithm", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-SignedHeaders", valid_593036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_ListConnectorDefinitions_593025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_ListConnectorDefinitions_593025;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593039 = newJObject()
  add(query_593039, "MaxResults", newJString(MaxResults))
  add(query_593039, "NextToken", newJString(NextToken))
  result = call_593038.call(nil, query_593039, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_593025(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_593026, base: "/",
    url: url_ListConnectorDefinitions_593027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_593072 = ref object of OpenApiRestCall_592348
proc url_CreateConnectorDefinitionVersion_593074(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinitionVersion_593073(path: JsonNode;
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
  var valid_593075 = path.getOrDefault("ConnectorDefinitionId")
  valid_593075 = validateParameter(valid_593075, JString, required = true,
                                 default = nil)
  if valid_593075 != nil:
    section.add "ConnectorDefinitionId", valid_593075
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
  var valid_593076 = header.getOrDefault("X-Amz-Signature")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Signature", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Content-Sha256", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Date")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Date", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Credential")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Credential", valid_593079
  var valid_593080 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amzn-Client-Token", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593085: Call_CreateConnectorDefinitionVersion_593072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_593085.validator(path, query, header, formData, body)
  let scheme = call_593085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593085.url(scheme.get, call_593085.host, call_593085.base,
                         call_593085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593085, url, valid)

proc call*(call_593086: Call_CreateConnectorDefinitionVersion_593072;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_593087 = newJObject()
  var body_593088 = newJObject()
  add(path_593087, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_593088 = body
  result = call_593086.call(path_593087, nil, nil, nil, body_593088)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_593072(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_593073, base: "/",
    url: url_CreateConnectorDefinitionVersion_593074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_593055 = ref object of OpenApiRestCall_592348
proc url_ListConnectorDefinitionVersions_593057(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitionVersions_593056(path: JsonNode;
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
  var valid_593058 = path.getOrDefault("ConnectorDefinitionId")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "ConnectorDefinitionId", valid_593058
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593059 = query.getOrDefault("MaxResults")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "MaxResults", valid_593059
  var valid_593060 = query.getOrDefault("NextToken")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "NextToken", valid_593060
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
  var valid_593061 = header.getOrDefault("X-Amz-Signature")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Signature", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Content-Sha256", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Date")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Date", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Credential")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Credential", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Security-Token")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Security-Token", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Algorithm")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Algorithm", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-SignedHeaders", valid_593067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593068: Call_ListConnectorDefinitionVersions_593055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_593068.validator(path, query, header, formData, body)
  let scheme = call_593068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593068.url(scheme.get, call_593068.host, call_593068.base,
                         call_593068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593068, url, valid)

proc call*(call_593069: Call_ListConnectorDefinitionVersions_593055;
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
  var path_593070 = newJObject()
  var query_593071 = newJObject()
  add(query_593071, "MaxResults", newJString(MaxResults))
  add(query_593071, "NextToken", newJString(NextToken))
  add(path_593070, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_593069.call(path_593070, query_593071, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_593055(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_593056, base: "/",
    url: url_ListConnectorDefinitionVersions_593057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_593104 = ref object of OpenApiRestCall_592348
proc url_CreateCoreDefinition_593106(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCoreDefinition_593105(path: JsonNode; query: JsonNode;
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
  var valid_593107 = header.getOrDefault("X-Amz-Signature")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Signature", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Content-Sha256", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Date")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Date", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Credential")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Credential", valid_593110
  var valid_593111 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amzn-Client-Token", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Security-Token")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Security-Token", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Algorithm")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Algorithm", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-SignedHeaders", valid_593114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593116: Call_CreateCoreDefinition_593104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_593116.validator(path, query, header, formData, body)
  let scheme = call_593116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593116.url(scheme.get, call_593116.host, call_593116.base,
                         call_593116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593116, url, valid)

proc call*(call_593117: Call_CreateCoreDefinition_593104; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_593118 = newJObject()
  if body != nil:
    body_593118 = body
  result = call_593117.call(nil, nil, nil, nil, body_593118)

var createCoreDefinition* = Call_CreateCoreDefinition_593104(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_593105, base: "/",
    url: url_CreateCoreDefinition_593106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_593089 = ref object of OpenApiRestCall_592348
proc url_ListCoreDefinitions_593091(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCoreDefinitions_593090(path: JsonNode; query: JsonNode;
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
  var valid_593092 = query.getOrDefault("MaxResults")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "MaxResults", valid_593092
  var valid_593093 = query.getOrDefault("NextToken")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "NextToken", valid_593093
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
  var valid_593094 = header.getOrDefault("X-Amz-Signature")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Signature", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Content-Sha256", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Date")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Date", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Credential")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Credential", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Security-Token")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Security-Token", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Algorithm")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Algorithm", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-SignedHeaders", valid_593100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593101: Call_ListCoreDefinitions_593089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_593101.validator(path, query, header, formData, body)
  let scheme = call_593101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593101.url(scheme.get, call_593101.host, call_593101.base,
                         call_593101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593101, url, valid)

proc call*(call_593102: Call_ListCoreDefinitions_593089; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593103 = newJObject()
  add(query_593103, "MaxResults", newJString(MaxResults))
  add(query_593103, "NextToken", newJString(NextToken))
  result = call_593102.call(nil, query_593103, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_593089(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_593090, base: "/",
    url: url_ListCoreDefinitions_593091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_593136 = ref object of OpenApiRestCall_592348
proc url_CreateCoreDefinitionVersion_593138(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_593137(path: JsonNode; query: JsonNode;
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
  var valid_593139 = path.getOrDefault("CoreDefinitionId")
  valid_593139 = validateParameter(valid_593139, JString, required = true,
                                 default = nil)
  if valid_593139 != nil:
    section.add "CoreDefinitionId", valid_593139
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
  var valid_593140 = header.getOrDefault("X-Amz-Signature")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Signature", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Content-Sha256", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Date")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Date", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Credential")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Credential", valid_593143
  var valid_593144 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amzn-Client-Token", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_CreateCoreDefinitionVersion_593136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_CreateCoreDefinitionVersion_593136;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_593151 = newJObject()
  var body_593152 = newJObject()
  add(path_593151, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_593152 = body
  result = call_593150.call(path_593151, nil, nil, nil, body_593152)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_593136(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_593137, base: "/",
    url: url_CreateCoreDefinitionVersion_593138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_593119 = ref object of OpenApiRestCall_592348
proc url_ListCoreDefinitionVersions_593121(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_593120(path: JsonNode; query: JsonNode;
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
  var valid_593122 = path.getOrDefault("CoreDefinitionId")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "CoreDefinitionId", valid_593122
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593123 = query.getOrDefault("MaxResults")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "MaxResults", valid_593123
  var valid_593124 = query.getOrDefault("NextToken")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "NextToken", valid_593124
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
  var valid_593125 = header.getOrDefault("X-Amz-Signature")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Signature", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Content-Sha256", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Date")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Date", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Credential")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Credential", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Security-Token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Security-Token", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Algorithm")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Algorithm", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-SignedHeaders", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593132: Call_ListCoreDefinitionVersions_593119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_593132.validator(path, query, header, formData, body)
  let scheme = call_593132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593132.url(scheme.get, call_593132.host, call_593132.base,
                         call_593132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593132, url, valid)

proc call*(call_593133: Call_ListCoreDefinitionVersions_593119;
          CoreDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_593134 = newJObject()
  var query_593135 = newJObject()
  add(query_593135, "MaxResults", newJString(MaxResults))
  add(query_593135, "NextToken", newJString(NextToken))
  add(path_593134, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_593133.call(path_593134, query_593135, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_593119(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_593120, base: "/",
    url: url_ListCoreDefinitionVersions_593121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_593170 = ref object of OpenApiRestCall_592348
proc url_CreateDeployment_593172(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_593171(path: JsonNode; query: JsonNode;
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
  var valid_593173 = path.getOrDefault("GroupId")
  valid_593173 = validateParameter(valid_593173, JString, required = true,
                                 default = nil)
  if valid_593173 != nil:
    section.add "GroupId", valid_593173
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
  var valid_593174 = header.getOrDefault("X-Amz-Signature")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Signature", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Content-Sha256", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Date")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Date", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Credential")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Credential", valid_593177
  var valid_593178 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amzn-Client-Token", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Security-Token")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Security-Token", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Algorithm")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Algorithm", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-SignedHeaders", valid_593181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593183: Call_CreateDeployment_593170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_593183.validator(path, query, header, formData, body)
  let scheme = call_593183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593183.url(scheme.get, call_593183.host, call_593183.base,
                         call_593183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593183, url, valid)

proc call*(call_593184: Call_CreateDeployment_593170; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_593185 = newJObject()
  var body_593186 = newJObject()
  add(path_593185, "GroupId", newJString(GroupId))
  if body != nil:
    body_593186 = body
  result = call_593184.call(path_593185, nil, nil, nil, body_593186)

var createDeployment* = Call_CreateDeployment_593170(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_593171, base: "/",
    url: url_CreateDeployment_593172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_593153 = ref object of OpenApiRestCall_592348
proc url_ListDeployments_593155(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_593154(path: JsonNode; query: JsonNode;
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
  var valid_593156 = path.getOrDefault("GroupId")
  valid_593156 = validateParameter(valid_593156, JString, required = true,
                                 default = nil)
  if valid_593156 != nil:
    section.add "GroupId", valid_593156
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593157 = query.getOrDefault("MaxResults")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "MaxResults", valid_593157
  var valid_593158 = query.getOrDefault("NextToken")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "NextToken", valid_593158
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
  var valid_593159 = header.getOrDefault("X-Amz-Signature")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Signature", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Content-Sha256", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Date")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Date", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Credential")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Credential", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Security-Token")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Security-Token", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Algorithm")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Algorithm", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-SignedHeaders", valid_593165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593166: Call_ListDeployments_593153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_593166.validator(path, query, header, formData, body)
  let scheme = call_593166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593166.url(scheme.get, call_593166.host, call_593166.base,
                         call_593166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593166, url, valid)

proc call*(call_593167: Call_ListDeployments_593153; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_593168 = newJObject()
  var query_593169 = newJObject()
  add(path_593168, "GroupId", newJString(GroupId))
  add(query_593169, "MaxResults", newJString(MaxResults))
  add(query_593169, "NextToken", newJString(NextToken))
  result = call_593167.call(path_593168, query_593169, nil, nil, nil)

var listDeployments* = Call_ListDeployments_593153(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_593154, base: "/", url: url_ListDeployments_593155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_593202 = ref object of OpenApiRestCall_592348
proc url_CreateDeviceDefinition_593204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeviceDefinition_593203(path: JsonNode; query: JsonNode;
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
  var valid_593205 = header.getOrDefault("X-Amz-Signature")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Signature", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Content-Sha256", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Date")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Date", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Credential")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Credential", valid_593208
  var valid_593209 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amzn-Client-Token", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Security-Token")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Security-Token", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Algorithm")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Algorithm", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-SignedHeaders", valid_593212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593214: Call_CreateDeviceDefinition_593202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_593214.validator(path, query, header, formData, body)
  let scheme = call_593214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593214.url(scheme.get, call_593214.host, call_593214.base,
                         call_593214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593214, url, valid)

proc call*(call_593215: Call_CreateDeviceDefinition_593202; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_593216 = newJObject()
  if body != nil:
    body_593216 = body
  result = call_593215.call(nil, nil, nil, nil, body_593216)

var createDeviceDefinition* = Call_CreateDeviceDefinition_593202(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_593203, base: "/",
    url: url_CreateDeviceDefinition_593204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_593187 = ref object of OpenApiRestCall_592348
proc url_ListDeviceDefinitions_593189(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceDefinitions_593188(path: JsonNode; query: JsonNode;
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
  var valid_593190 = query.getOrDefault("MaxResults")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "MaxResults", valid_593190
  var valid_593191 = query.getOrDefault("NextToken")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "NextToken", valid_593191
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
  var valid_593192 = header.getOrDefault("X-Amz-Signature")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Signature", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Content-Sha256", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Date")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Date", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Credential")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Credential", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Security-Token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Security-Token", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Algorithm")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Algorithm", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-SignedHeaders", valid_593198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593199: Call_ListDeviceDefinitions_593187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_593199.validator(path, query, header, formData, body)
  let scheme = call_593199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593199.url(scheme.get, call_593199.host, call_593199.base,
                         call_593199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593199, url, valid)

proc call*(call_593200: Call_ListDeviceDefinitions_593187; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593201 = newJObject()
  add(query_593201, "MaxResults", newJString(MaxResults))
  add(query_593201, "NextToken", newJString(NextToken))
  result = call_593200.call(nil, query_593201, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_593187(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_593188, base: "/",
    url: url_ListDeviceDefinitions_593189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_593234 = ref object of OpenApiRestCall_592348
proc url_CreateDeviceDefinitionVersion_593236(protocol: Scheme; host: string;
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

proc validate_CreateDeviceDefinitionVersion_593235(path: JsonNode; query: JsonNode;
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
  var valid_593237 = path.getOrDefault("DeviceDefinitionId")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = nil)
  if valid_593237 != nil:
    section.add "DeviceDefinitionId", valid_593237
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
  var valid_593238 = header.getOrDefault("X-Amz-Signature")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Signature", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Content-Sha256", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Date")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Date", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Credential")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Credential", valid_593241
  var valid_593242 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amzn-Client-Token", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Security-Token")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Security-Token", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Algorithm")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Algorithm", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-SignedHeaders", valid_593245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593247: Call_CreateDeviceDefinitionVersion_593234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_593247.validator(path, query, header, formData, body)
  let scheme = call_593247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593247.url(scheme.get, call_593247.host, call_593247.base,
                         call_593247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593247, url, valid)

proc call*(call_593248: Call_CreateDeviceDefinitionVersion_593234;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_593249 = newJObject()
  var body_593250 = newJObject()
  add(path_593249, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_593250 = body
  result = call_593248.call(path_593249, nil, nil, nil, body_593250)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_593234(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_593235, base: "/",
    url: url_CreateDeviceDefinitionVersion_593236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_593217 = ref object of OpenApiRestCall_592348
proc url_ListDeviceDefinitionVersions_593219(protocol: Scheme; host: string;
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

proc validate_ListDeviceDefinitionVersions_593218(path: JsonNode; query: JsonNode;
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
  var valid_593220 = path.getOrDefault("DeviceDefinitionId")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "DeviceDefinitionId", valid_593220
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593221 = query.getOrDefault("MaxResults")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "MaxResults", valid_593221
  var valid_593222 = query.getOrDefault("NextToken")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "NextToken", valid_593222
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
  var valid_593223 = header.getOrDefault("X-Amz-Signature")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Signature", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Content-Sha256", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Date")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Date", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Credential")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Credential", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Security-Token")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Security-Token", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Algorithm")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Algorithm", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-SignedHeaders", valid_593229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593230: Call_ListDeviceDefinitionVersions_593217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_593230.validator(path, query, header, formData, body)
  let scheme = call_593230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593230.url(scheme.get, call_593230.host, call_593230.base,
                         call_593230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593230, url, valid)

proc call*(call_593231: Call_ListDeviceDefinitionVersions_593217;
          DeviceDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_593232 = newJObject()
  var query_593233 = newJObject()
  add(path_593232, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_593233, "MaxResults", newJString(MaxResults))
  add(query_593233, "NextToken", newJString(NextToken))
  result = call_593231.call(path_593232, query_593233, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_593217(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_593218, base: "/",
    url: url_ListDeviceDefinitionVersions_593219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_593266 = ref object of OpenApiRestCall_592348
proc url_CreateFunctionDefinition_593268(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFunctionDefinition_593267(path: JsonNode; query: JsonNode;
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
  var valid_593269 = header.getOrDefault("X-Amz-Signature")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Signature", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Content-Sha256", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Date")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Date", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Credential")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Credential", valid_593272
  var valid_593273 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amzn-Client-Token", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Security-Token")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Security-Token", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Algorithm")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Algorithm", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-SignedHeaders", valid_593276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_CreateFunctionDefinition_593266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_CreateFunctionDefinition_593266; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_593280 = newJObject()
  if body != nil:
    body_593280 = body
  result = call_593279.call(nil, nil, nil, nil, body_593280)

var createFunctionDefinition* = Call_CreateFunctionDefinition_593266(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_593267, base: "/",
    url: url_CreateFunctionDefinition_593268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_593251 = ref object of OpenApiRestCall_592348
proc url_ListFunctionDefinitions_593253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctionDefinitions_593252(path: JsonNode; query: JsonNode;
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
  var valid_593254 = query.getOrDefault("MaxResults")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "MaxResults", valid_593254
  var valid_593255 = query.getOrDefault("NextToken")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "NextToken", valid_593255
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
  var valid_593256 = header.getOrDefault("X-Amz-Signature")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Signature", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Content-Sha256", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Date")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Date", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Credential")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Credential", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Security-Token")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Security-Token", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Algorithm")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Algorithm", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-SignedHeaders", valid_593262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593263: Call_ListFunctionDefinitions_593251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_593263.validator(path, query, header, formData, body)
  let scheme = call_593263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593263.url(scheme.get, call_593263.host, call_593263.base,
                         call_593263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593263, url, valid)

proc call*(call_593264: Call_ListFunctionDefinitions_593251;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593265 = newJObject()
  add(query_593265, "MaxResults", newJString(MaxResults))
  add(query_593265, "NextToken", newJString(NextToken))
  result = call_593264.call(nil, query_593265, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_593251(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_593252, base: "/",
    url: url_ListFunctionDefinitions_593253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_593298 = ref object of OpenApiRestCall_592348
proc url_CreateFunctionDefinitionVersion_593300(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinitionVersion_593299(path: JsonNode;
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
  var valid_593301 = path.getOrDefault("FunctionDefinitionId")
  valid_593301 = validateParameter(valid_593301, JString, required = true,
                                 default = nil)
  if valid_593301 != nil:
    section.add "FunctionDefinitionId", valid_593301
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
  var valid_593302 = header.getOrDefault("X-Amz-Signature")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Signature", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Content-Sha256", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Date")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Date", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Credential")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Credential", valid_593305
  var valid_593306 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amzn-Client-Token", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Algorithm")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Algorithm", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-SignedHeaders", valid_593309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_CreateFunctionDefinitionVersion_593298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_CreateFunctionDefinitionVersion_593298;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_593313 = newJObject()
  var body_593314 = newJObject()
  add(path_593313, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_593314 = body
  result = call_593312.call(path_593313, nil, nil, nil, body_593314)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_593298(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_593299, base: "/",
    url: url_CreateFunctionDefinitionVersion_593300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_593281 = ref object of OpenApiRestCall_592348
proc url_ListFunctionDefinitionVersions_593283(protocol: Scheme; host: string;
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

proc validate_ListFunctionDefinitionVersions_593282(path: JsonNode;
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
  var valid_593284 = path.getOrDefault("FunctionDefinitionId")
  valid_593284 = validateParameter(valid_593284, JString, required = true,
                                 default = nil)
  if valid_593284 != nil:
    section.add "FunctionDefinitionId", valid_593284
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593285 = query.getOrDefault("MaxResults")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "MaxResults", valid_593285
  var valid_593286 = query.getOrDefault("NextToken")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "NextToken", valid_593286
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
  var valid_593287 = header.getOrDefault("X-Amz-Signature")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Signature", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Content-Sha256", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Date")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Date", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Credential")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Credential", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Security-Token")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Security-Token", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Algorithm")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Algorithm", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-SignedHeaders", valid_593293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593294: Call_ListFunctionDefinitionVersions_593281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_593294.validator(path, query, header, formData, body)
  let scheme = call_593294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593294.url(scheme.get, call_593294.host, call_593294.base,
                         call_593294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593294, url, valid)

proc call*(call_593295: Call_ListFunctionDefinitionVersions_593281;
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
  var path_593296 = newJObject()
  var query_593297 = newJObject()
  add(query_593297, "MaxResults", newJString(MaxResults))
  add(query_593297, "NextToken", newJString(NextToken))
  add(path_593296, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_593295.call(path_593296, query_593297, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_593281(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_593282, base: "/",
    url: url_ListFunctionDefinitionVersions_593283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_593330 = ref object of OpenApiRestCall_592348
proc url_CreateGroup_593332(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGroup_593331(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593333 = header.getOrDefault("X-Amz-Signature")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Signature", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Content-Sha256", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Date")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Date", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Credential")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Credential", valid_593336
  var valid_593337 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amzn-Client-Token", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Security-Token")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Security-Token", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Algorithm")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Algorithm", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-SignedHeaders", valid_593340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593342: Call_CreateGroup_593330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_593342.validator(path, query, header, formData, body)
  let scheme = call_593342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593342.url(scheme.get, call_593342.host, call_593342.base,
                         call_593342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593342, url, valid)

proc call*(call_593343: Call_CreateGroup_593330; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_593344 = newJObject()
  if body != nil:
    body_593344 = body
  result = call_593343.call(nil, nil, nil, nil, body_593344)

var createGroup* = Call_CreateGroup_593330(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_593331,
                                        base: "/", url: url_CreateGroup_593332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_593315 = ref object of OpenApiRestCall_592348
proc url_ListGroups_593317(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGroups_593316(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593318 = query.getOrDefault("MaxResults")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "MaxResults", valid_593318
  var valid_593319 = query.getOrDefault("NextToken")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "NextToken", valid_593319
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
  var valid_593320 = header.getOrDefault("X-Amz-Signature")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Signature", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Content-Sha256", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Date")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Date", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Credential")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Credential", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Security-Token")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Security-Token", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Algorithm")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Algorithm", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-SignedHeaders", valid_593326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593327: Call_ListGroups_593315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_593327.validator(path, query, header, formData, body)
  let scheme = call_593327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593327.url(scheme.get, call_593327.host, call_593327.base,
                         call_593327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593327, url, valid)

proc call*(call_593328: Call_ListGroups_593315; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593329 = newJObject()
  add(query_593329, "MaxResults", newJString(MaxResults))
  add(query_593329, "NextToken", newJString(NextToken))
  result = call_593328.call(nil, query_593329, nil, nil, nil)

var listGroups* = Call_ListGroups_593315(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_593316,
                                      base: "/", url: url_ListGroups_593317,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_593359 = ref object of OpenApiRestCall_592348
proc url_CreateGroupCertificateAuthority_593361(protocol: Scheme; host: string;
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

proc validate_CreateGroupCertificateAuthority_593360(path: JsonNode;
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
  var valid_593362 = path.getOrDefault("GroupId")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = nil)
  if valid_593362 != nil:
    section.add "GroupId", valid_593362
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
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amzn-Client-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Security-Token")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Security-Token", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Algorithm")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Algorithm", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-SignedHeaders", valid_593370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593371: Call_CreateGroupCertificateAuthority_593359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_593371.validator(path, query, header, formData, body)
  let scheme = call_593371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593371.url(scheme.get, call_593371.host, call_593371.base,
                         call_593371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593371, url, valid)

proc call*(call_593372: Call_CreateGroupCertificateAuthority_593359;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_593373 = newJObject()
  add(path_593373, "GroupId", newJString(GroupId))
  result = call_593372.call(path_593373, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_593359(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_593360, base: "/",
    url: url_CreateGroupCertificateAuthority_593361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_593345 = ref object of OpenApiRestCall_592348
proc url_ListGroupCertificateAuthorities_593347(protocol: Scheme; host: string;
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

proc validate_ListGroupCertificateAuthorities_593346(path: JsonNode;
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
  var valid_593348 = path.getOrDefault("GroupId")
  valid_593348 = validateParameter(valid_593348, JString, required = true,
                                 default = nil)
  if valid_593348 != nil:
    section.add "GroupId", valid_593348
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
  var valid_593349 = header.getOrDefault("X-Amz-Signature")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Signature", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Content-Sha256", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Date")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Date", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Credential")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Credential", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Security-Token")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Security-Token", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Algorithm")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Algorithm", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-SignedHeaders", valid_593355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_ListGroupCertificateAuthorities_593345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_ListGroupCertificateAuthorities_593345;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_593358 = newJObject()
  add(path_593358, "GroupId", newJString(GroupId))
  result = call_593357.call(path_593358, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_593345(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_593346, base: "/",
    url: url_ListGroupCertificateAuthorities_593347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_593391 = ref object of OpenApiRestCall_592348
proc url_CreateGroupVersion_593393(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupVersion_593392(path: JsonNode; query: JsonNode;
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
  var valid_593394 = path.getOrDefault("GroupId")
  valid_593394 = validateParameter(valid_593394, JString, required = true,
                                 default = nil)
  if valid_593394 != nil:
    section.add "GroupId", valid_593394
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
  var valid_593395 = header.getOrDefault("X-Amz-Signature")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Signature", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Content-Sha256", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Date")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Date", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Credential")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Credential", valid_593398
  var valid_593399 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amzn-Client-Token", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Security-Token")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Security-Token", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Algorithm")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Algorithm", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-SignedHeaders", valid_593402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593404: Call_CreateGroupVersion_593391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_593404.validator(path, query, header, formData, body)
  let scheme = call_593404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593404.url(scheme.get, call_593404.host, call_593404.base,
                         call_593404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593404, url, valid)

proc call*(call_593405: Call_CreateGroupVersion_593391; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_593406 = newJObject()
  var body_593407 = newJObject()
  add(path_593406, "GroupId", newJString(GroupId))
  if body != nil:
    body_593407 = body
  result = call_593405.call(path_593406, nil, nil, nil, body_593407)

var createGroupVersion* = Call_CreateGroupVersion_593391(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_593392, base: "/",
    url: url_CreateGroupVersion_593393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_593374 = ref object of OpenApiRestCall_592348
proc url_ListGroupVersions_593376(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupVersions_593375(path: JsonNode; query: JsonNode;
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
  var valid_593377 = path.getOrDefault("GroupId")
  valid_593377 = validateParameter(valid_593377, JString, required = true,
                                 default = nil)
  if valid_593377 != nil:
    section.add "GroupId", valid_593377
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593378 = query.getOrDefault("MaxResults")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "MaxResults", valid_593378
  var valid_593379 = query.getOrDefault("NextToken")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "NextToken", valid_593379
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
  var valid_593380 = header.getOrDefault("X-Amz-Signature")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Signature", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Content-Sha256", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Date")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Date", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Credential")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Credential", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Security-Token")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Security-Token", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Algorithm")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Algorithm", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-SignedHeaders", valid_593386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593387: Call_ListGroupVersions_593374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_593387.validator(path, query, header, formData, body)
  let scheme = call_593387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593387.url(scheme.get, call_593387.host, call_593387.base,
                         call_593387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593387, url, valid)

proc call*(call_593388: Call_ListGroupVersions_593374; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_593389 = newJObject()
  var query_593390 = newJObject()
  add(path_593389, "GroupId", newJString(GroupId))
  add(query_593390, "MaxResults", newJString(MaxResults))
  add(query_593390, "NextToken", newJString(NextToken))
  result = call_593388.call(path_593389, query_593390, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_593374(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_593375, base: "/",
    url: url_ListGroupVersions_593376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_593423 = ref object of OpenApiRestCall_592348
proc url_CreateLoggerDefinition_593425(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLoggerDefinition_593424(path: JsonNode; query: JsonNode;
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
  var valid_593426 = header.getOrDefault("X-Amz-Signature")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Signature", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Content-Sha256", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Date")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Date", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Credential")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Credential", valid_593429
  var valid_593430 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amzn-Client-Token", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Security-Token")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Security-Token", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Algorithm")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Algorithm", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-SignedHeaders", valid_593433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593435: Call_CreateLoggerDefinition_593423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_593435.validator(path, query, header, formData, body)
  let scheme = call_593435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593435.url(scheme.get, call_593435.host, call_593435.base,
                         call_593435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593435, url, valid)

proc call*(call_593436: Call_CreateLoggerDefinition_593423; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_593437 = newJObject()
  if body != nil:
    body_593437 = body
  result = call_593436.call(nil, nil, nil, nil, body_593437)

var createLoggerDefinition* = Call_CreateLoggerDefinition_593423(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_593424, base: "/",
    url: url_CreateLoggerDefinition_593425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_593408 = ref object of OpenApiRestCall_592348
proc url_ListLoggerDefinitions_593410(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLoggerDefinitions_593409(path: JsonNode; query: JsonNode;
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
  var valid_593411 = query.getOrDefault("MaxResults")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "MaxResults", valid_593411
  var valid_593412 = query.getOrDefault("NextToken")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "NextToken", valid_593412
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
  var valid_593413 = header.getOrDefault("X-Amz-Signature")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Signature", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Content-Sha256", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Date")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Date", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Credential")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Credential", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Security-Token")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Security-Token", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Algorithm")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Algorithm", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-SignedHeaders", valid_593419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593420: Call_ListLoggerDefinitions_593408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_593420.validator(path, query, header, formData, body)
  let scheme = call_593420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593420.url(scheme.get, call_593420.host, call_593420.base,
                         call_593420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593420, url, valid)

proc call*(call_593421: Call_ListLoggerDefinitions_593408; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593422 = newJObject()
  add(query_593422, "MaxResults", newJString(MaxResults))
  add(query_593422, "NextToken", newJString(NextToken))
  result = call_593421.call(nil, query_593422, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_593408(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_593409, base: "/",
    url: url_ListLoggerDefinitions_593410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_593455 = ref object of OpenApiRestCall_592348
proc url_CreateLoggerDefinitionVersion_593457(protocol: Scheme; host: string;
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

proc validate_CreateLoggerDefinitionVersion_593456(path: JsonNode; query: JsonNode;
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
  var valid_593458 = path.getOrDefault("LoggerDefinitionId")
  valid_593458 = validateParameter(valid_593458, JString, required = true,
                                 default = nil)
  if valid_593458 != nil:
    section.add "LoggerDefinitionId", valid_593458
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
  var valid_593459 = header.getOrDefault("X-Amz-Signature")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Signature", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Content-Sha256", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Date")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Date", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Credential")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Credential", valid_593462
  var valid_593463 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amzn-Client-Token", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Security-Token")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Security-Token", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Algorithm")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Algorithm", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-SignedHeaders", valid_593466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_CreateLoggerDefinitionVersion_593455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_CreateLoggerDefinitionVersion_593455;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_593470 = newJObject()
  var body_593471 = newJObject()
  add(path_593470, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_593471 = body
  result = call_593469.call(path_593470, nil, nil, nil, body_593471)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_593455(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_593456, base: "/",
    url: url_CreateLoggerDefinitionVersion_593457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_593438 = ref object of OpenApiRestCall_592348
proc url_ListLoggerDefinitionVersions_593440(protocol: Scheme; host: string;
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

proc validate_ListLoggerDefinitionVersions_593439(path: JsonNode; query: JsonNode;
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
  var valid_593441 = path.getOrDefault("LoggerDefinitionId")
  valid_593441 = validateParameter(valid_593441, JString, required = true,
                                 default = nil)
  if valid_593441 != nil:
    section.add "LoggerDefinitionId", valid_593441
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593442 = query.getOrDefault("MaxResults")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "MaxResults", valid_593442
  var valid_593443 = query.getOrDefault("NextToken")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "NextToken", valid_593443
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
  var valid_593444 = header.getOrDefault("X-Amz-Signature")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Signature", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Content-Sha256", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Date")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Date", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Credential")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Credential", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Security-Token")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Security-Token", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Algorithm")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Algorithm", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-SignedHeaders", valid_593450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593451: Call_ListLoggerDefinitionVersions_593438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_593451.validator(path, query, header, formData, body)
  let scheme = call_593451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593451.url(scheme.get, call_593451.host, call_593451.base,
                         call_593451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593451, url, valid)

proc call*(call_593452: Call_ListLoggerDefinitionVersions_593438;
          LoggerDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_593453 = newJObject()
  var query_593454 = newJObject()
  add(query_593454, "MaxResults", newJString(MaxResults))
  add(query_593454, "NextToken", newJString(NextToken))
  add(path_593453, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_593452.call(path_593453, query_593454, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_593438(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_593439, base: "/",
    url: url_ListLoggerDefinitionVersions_593440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_593487 = ref object of OpenApiRestCall_592348
proc url_CreateResourceDefinition_593489(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceDefinition_593488(path: JsonNode; query: JsonNode;
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
  var valid_593490 = header.getOrDefault("X-Amz-Signature")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Signature", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Content-Sha256", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-Date")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-Date", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-Credential")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Credential", valid_593493
  var valid_593494 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amzn-Client-Token", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Security-Token")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Security-Token", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Algorithm")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Algorithm", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-SignedHeaders", valid_593497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593499: Call_CreateResourceDefinition_593487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_593499.validator(path, query, header, formData, body)
  let scheme = call_593499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593499.url(scheme.get, call_593499.host, call_593499.base,
                         call_593499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593499, url, valid)

proc call*(call_593500: Call_CreateResourceDefinition_593487; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_593501 = newJObject()
  if body != nil:
    body_593501 = body
  result = call_593500.call(nil, nil, nil, nil, body_593501)

var createResourceDefinition* = Call_CreateResourceDefinition_593487(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_593488, base: "/",
    url: url_CreateResourceDefinition_593489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_593472 = ref object of OpenApiRestCall_592348
proc url_ListResourceDefinitions_593474(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceDefinitions_593473(path: JsonNode; query: JsonNode;
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
  var valid_593475 = query.getOrDefault("MaxResults")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "MaxResults", valid_593475
  var valid_593476 = query.getOrDefault("NextToken")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "NextToken", valid_593476
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
  var valid_593477 = header.getOrDefault("X-Amz-Signature")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Signature", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Content-Sha256", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Date")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Date", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Credential")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Credential", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Security-Token")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Security-Token", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Algorithm")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Algorithm", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-SignedHeaders", valid_593483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593484: Call_ListResourceDefinitions_593472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_593484.validator(path, query, header, formData, body)
  let scheme = call_593484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593484.url(scheme.get, call_593484.host, call_593484.base,
                         call_593484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593484, url, valid)

proc call*(call_593485: Call_ListResourceDefinitions_593472;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593486 = newJObject()
  add(query_593486, "MaxResults", newJString(MaxResults))
  add(query_593486, "NextToken", newJString(NextToken))
  result = call_593485.call(nil, query_593486, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_593472(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_593473, base: "/",
    url: url_ListResourceDefinitions_593474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_593519 = ref object of OpenApiRestCall_592348
proc url_CreateResourceDefinitionVersion_593521(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinitionVersion_593520(path: JsonNode;
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
  var valid_593522 = path.getOrDefault("ResourceDefinitionId")
  valid_593522 = validateParameter(valid_593522, JString, required = true,
                                 default = nil)
  if valid_593522 != nil:
    section.add "ResourceDefinitionId", valid_593522
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
  var valid_593523 = header.getOrDefault("X-Amz-Signature")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Signature", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Content-Sha256", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Date")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Date", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Credential")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Credential", valid_593526
  var valid_593527 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amzn-Client-Token", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-Security-Token")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-Security-Token", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Algorithm")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Algorithm", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-SignedHeaders", valid_593530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593532: Call_CreateResourceDefinitionVersion_593519;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_593532.validator(path, query, header, formData, body)
  let scheme = call_593532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593532.url(scheme.get, call_593532.host, call_593532.base,
                         call_593532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593532, url, valid)

proc call*(call_593533: Call_CreateResourceDefinitionVersion_593519;
          body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_593534 = newJObject()
  var body_593535 = newJObject()
  if body != nil:
    body_593535 = body
  add(path_593534, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_593533.call(path_593534, nil, nil, nil, body_593535)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_593519(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_593520, base: "/",
    url: url_CreateResourceDefinitionVersion_593521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_593502 = ref object of OpenApiRestCall_592348
proc url_ListResourceDefinitionVersions_593504(protocol: Scheme; host: string;
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

proc validate_ListResourceDefinitionVersions_593503(path: JsonNode;
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
  var valid_593505 = path.getOrDefault("ResourceDefinitionId")
  valid_593505 = validateParameter(valid_593505, JString, required = true,
                                 default = nil)
  if valid_593505 != nil:
    section.add "ResourceDefinitionId", valid_593505
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593506 = query.getOrDefault("MaxResults")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "MaxResults", valid_593506
  var valid_593507 = query.getOrDefault("NextToken")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "NextToken", valid_593507
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
  var valid_593508 = header.getOrDefault("X-Amz-Signature")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Signature", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Content-Sha256", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Date")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Date", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Credential")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Credential", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-Security-Token")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-Security-Token", valid_593512
  var valid_593513 = header.getOrDefault("X-Amz-Algorithm")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Algorithm", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-SignedHeaders", valid_593514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593515: Call_ListResourceDefinitionVersions_593502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_593515.validator(path, query, header, formData, body)
  let scheme = call_593515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593515.url(scheme.get, call_593515.host, call_593515.base,
                         call_593515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593515, url, valid)

proc call*(call_593516: Call_ListResourceDefinitionVersions_593502;
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
  var path_593517 = newJObject()
  var query_593518 = newJObject()
  add(query_593518, "MaxResults", newJString(MaxResults))
  add(query_593518, "NextToken", newJString(NextToken))
  add(path_593517, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_593516.call(path_593517, query_593518, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_593502(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_593503, base: "/",
    url: url_ListResourceDefinitionVersions_593504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_593536 = ref object of OpenApiRestCall_592348
proc url_CreateSoftwareUpdateJob_593538(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSoftwareUpdateJob_593537(path: JsonNode; query: JsonNode;
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
  var valid_593539 = header.getOrDefault("X-Amz-Signature")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Signature", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Content-Sha256", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Date")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Date", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Credential")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Credential", valid_593542
  var valid_593543 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amzn-Client-Token", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Security-Token")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Security-Token", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Algorithm")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Algorithm", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-SignedHeaders", valid_593546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593548: Call_CreateSoftwareUpdateJob_593536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_593548.validator(path, query, header, formData, body)
  let scheme = call_593548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593548.url(scheme.get, call_593548.host, call_593548.base,
                         call_593548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593548, url, valid)

proc call*(call_593549: Call_CreateSoftwareUpdateJob_593536; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_593550 = newJObject()
  if body != nil:
    body_593550 = body
  result = call_593549.call(nil, nil, nil, nil, body_593550)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_593536(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_593537, base: "/",
    url: url_CreateSoftwareUpdateJob_593538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_593566 = ref object of OpenApiRestCall_592348
proc url_CreateSubscriptionDefinition_593568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSubscriptionDefinition_593567(path: JsonNode; query: JsonNode;
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
  var valid_593569 = header.getOrDefault("X-Amz-Signature")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Signature", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Content-Sha256", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Date")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Date", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-Credential")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Credential", valid_593572
  var valid_593573 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amzn-Client-Token", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Security-Token")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Security-Token", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Algorithm")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Algorithm", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-SignedHeaders", valid_593576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593578: Call_CreateSubscriptionDefinition_593566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_593578.validator(path, query, header, formData, body)
  let scheme = call_593578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593578.url(scheme.get, call_593578.host, call_593578.base,
                         call_593578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593578, url, valid)

proc call*(call_593579: Call_CreateSubscriptionDefinition_593566; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_593580 = newJObject()
  if body != nil:
    body_593580 = body
  result = call_593579.call(nil, nil, nil, nil, body_593580)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_593566(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_593567, base: "/",
    url: url_CreateSubscriptionDefinition_593568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_593551 = ref object of OpenApiRestCall_592348
proc url_ListSubscriptionDefinitions_593553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscriptionDefinitions_593552(path: JsonNode; query: JsonNode;
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
  var valid_593554 = query.getOrDefault("MaxResults")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "MaxResults", valid_593554
  var valid_593555 = query.getOrDefault("NextToken")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "NextToken", valid_593555
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
  var valid_593556 = header.getOrDefault("X-Amz-Signature")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Signature", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Content-Sha256", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Date")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Date", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Credential")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Credential", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Security-Token")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Security-Token", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Algorithm")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Algorithm", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-SignedHeaders", valid_593562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593563: Call_ListSubscriptionDefinitions_593551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_593563.validator(path, query, header, formData, body)
  let scheme = call_593563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593563.url(scheme.get, call_593563.host, call_593563.base,
                         call_593563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593563, url, valid)

proc call*(call_593564: Call_ListSubscriptionDefinitions_593551;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_593565 = newJObject()
  add(query_593565, "MaxResults", newJString(MaxResults))
  add(query_593565, "NextToken", newJString(NextToken))
  result = call_593564.call(nil, query_593565, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_593551(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_593552, base: "/",
    url: url_ListSubscriptionDefinitions_593553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_593598 = ref object of OpenApiRestCall_592348
proc url_CreateSubscriptionDefinitionVersion_593600(protocol: Scheme; host: string;
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

proc validate_CreateSubscriptionDefinitionVersion_593599(path: JsonNode;
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
  var valid_593601 = path.getOrDefault("SubscriptionDefinitionId")
  valid_593601 = validateParameter(valid_593601, JString, required = true,
                                 default = nil)
  if valid_593601 != nil:
    section.add "SubscriptionDefinitionId", valid_593601
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
  var valid_593602 = header.getOrDefault("X-Amz-Signature")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Signature", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Content-Sha256", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Date")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Date", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Credential")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Credential", valid_593605
  var valid_593606 = header.getOrDefault("X-Amzn-Client-Token")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amzn-Client-Token", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Security-Token")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Security-Token", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Algorithm")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Algorithm", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-SignedHeaders", valid_593609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593611: Call_CreateSubscriptionDefinitionVersion_593598;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_593611.validator(path, query, header, formData, body)
  let scheme = call_593611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593611.url(scheme.get, call_593611.host, call_593611.base,
                         call_593611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593611, url, valid)

proc call*(call_593612: Call_CreateSubscriptionDefinitionVersion_593598;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_593613 = newJObject()
  var body_593614 = newJObject()
  add(path_593613, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_593614 = body
  result = call_593612.call(path_593613, nil, nil, nil, body_593614)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_593598(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_593599, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_593600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_593581 = ref object of OpenApiRestCall_592348
proc url_ListSubscriptionDefinitionVersions_593583(protocol: Scheme; host: string;
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

proc validate_ListSubscriptionDefinitionVersions_593582(path: JsonNode;
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
  var valid_593584 = path.getOrDefault("SubscriptionDefinitionId")
  valid_593584 = validateParameter(valid_593584, JString, required = true,
                                 default = nil)
  if valid_593584 != nil:
    section.add "SubscriptionDefinitionId", valid_593584
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_593585 = query.getOrDefault("MaxResults")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "MaxResults", valid_593585
  var valid_593586 = query.getOrDefault("NextToken")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "NextToken", valid_593586
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
  var valid_593587 = header.getOrDefault("X-Amz-Signature")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Signature", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Content-Sha256", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Date")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Date", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Credential")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Credential", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Security-Token")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Security-Token", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Algorithm")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Algorithm", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-SignedHeaders", valid_593593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593594: Call_ListSubscriptionDefinitionVersions_593581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_593594.validator(path, query, header, formData, body)
  let scheme = call_593594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593594.url(scheme.get, call_593594.host, call_593594.base,
                         call_593594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593594, url, valid)

proc call*(call_593595: Call_ListSubscriptionDefinitionVersions_593581;
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
  var path_593596 = newJObject()
  var query_593597 = newJObject()
  add(query_593597, "MaxResults", newJString(MaxResults))
  add(query_593597, "NextToken", newJString(NextToken))
  add(path_593596, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_593595.call(path_593596, query_593597, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_593581(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_593582, base: "/",
    url: url_ListSubscriptionDefinitionVersions_593583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_593629 = ref object of OpenApiRestCall_592348
proc url_UpdateConnectorDefinition_593631(protocol: Scheme; host: string;
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

proc validate_UpdateConnectorDefinition_593630(path: JsonNode; query: JsonNode;
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
  var valid_593632 = path.getOrDefault("ConnectorDefinitionId")
  valid_593632 = validateParameter(valid_593632, JString, required = true,
                                 default = nil)
  if valid_593632 != nil:
    section.add "ConnectorDefinitionId", valid_593632
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
  var valid_593633 = header.getOrDefault("X-Amz-Signature")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Signature", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Content-Sha256", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Date")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Date", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Credential")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Credential", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Security-Token")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Security-Token", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Algorithm")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Algorithm", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-SignedHeaders", valid_593639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593641: Call_UpdateConnectorDefinition_593629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_593641.validator(path, query, header, formData, body)
  let scheme = call_593641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593641.url(scheme.get, call_593641.host, call_593641.base,
                         call_593641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593641, url, valid)

proc call*(call_593642: Call_UpdateConnectorDefinition_593629;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_593643 = newJObject()
  var body_593644 = newJObject()
  add(path_593643, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_593644 = body
  result = call_593642.call(path_593643, nil, nil, nil, body_593644)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_593629(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_593630, base: "/",
    url: url_UpdateConnectorDefinition_593631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_593615 = ref object of OpenApiRestCall_592348
proc url_GetConnectorDefinition_593617(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectorDefinition_593616(path: JsonNode; query: JsonNode;
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
  var valid_593618 = path.getOrDefault("ConnectorDefinitionId")
  valid_593618 = validateParameter(valid_593618, JString, required = true,
                                 default = nil)
  if valid_593618 != nil:
    section.add "ConnectorDefinitionId", valid_593618
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
  var valid_593619 = header.getOrDefault("X-Amz-Signature")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Signature", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Content-Sha256", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Date")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Date", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Credential")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Credential", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Security-Token")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Security-Token", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Algorithm")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Algorithm", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-SignedHeaders", valid_593625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593626: Call_GetConnectorDefinition_593615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_593626.validator(path, query, header, formData, body)
  let scheme = call_593626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593626.url(scheme.get, call_593626.host, call_593626.base,
                         call_593626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593626, url, valid)

proc call*(call_593627: Call_GetConnectorDefinition_593615;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_593628 = newJObject()
  add(path_593628, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_593627.call(path_593628, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_593615(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_593616, base: "/",
    url: url_GetConnectorDefinition_593617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_593645 = ref object of OpenApiRestCall_592348
proc url_DeleteConnectorDefinition_593647(protocol: Scheme; host: string;
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

proc validate_DeleteConnectorDefinition_593646(path: JsonNode; query: JsonNode;
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
  var valid_593648 = path.getOrDefault("ConnectorDefinitionId")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = nil)
  if valid_593648 != nil:
    section.add "ConnectorDefinitionId", valid_593648
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
  var valid_593649 = header.getOrDefault("X-Amz-Signature")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Signature", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Content-Sha256", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Date")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Date", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Credential")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Credential", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Security-Token")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Security-Token", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Algorithm")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Algorithm", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-SignedHeaders", valid_593655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593656: Call_DeleteConnectorDefinition_593645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_593656.validator(path, query, header, formData, body)
  let scheme = call_593656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593656.url(scheme.get, call_593656.host, call_593656.base,
                         call_593656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593656, url, valid)

proc call*(call_593657: Call_DeleteConnectorDefinition_593645;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_593658 = newJObject()
  add(path_593658, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_593657.call(path_593658, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_593645(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_593646, base: "/",
    url: url_DeleteConnectorDefinition_593647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_593673 = ref object of OpenApiRestCall_592348
proc url_UpdateCoreDefinition_593675(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCoreDefinition_593674(path: JsonNode; query: JsonNode;
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
  var valid_593676 = path.getOrDefault("CoreDefinitionId")
  valid_593676 = validateParameter(valid_593676, JString, required = true,
                                 default = nil)
  if valid_593676 != nil:
    section.add "CoreDefinitionId", valid_593676
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
  var valid_593677 = header.getOrDefault("X-Amz-Signature")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Signature", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Content-Sha256", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Date")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Date", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-Credential")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Credential", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Security-Token")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Security-Token", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Algorithm")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Algorithm", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-SignedHeaders", valid_593683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593685: Call_UpdateCoreDefinition_593673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_593685.validator(path, query, header, formData, body)
  let scheme = call_593685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593685.url(scheme.get, call_593685.host, call_593685.base,
                         call_593685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593685, url, valid)

proc call*(call_593686: Call_UpdateCoreDefinition_593673; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_593687 = newJObject()
  var body_593688 = newJObject()
  add(path_593687, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_593688 = body
  result = call_593686.call(path_593687, nil, nil, nil, body_593688)

var updateCoreDefinition* = Call_UpdateCoreDefinition_593673(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_593674, base: "/",
    url: url_UpdateCoreDefinition_593675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_593659 = ref object of OpenApiRestCall_592348
proc url_GetCoreDefinition_593661(protocol: Scheme; host: string; base: string;
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

proc validate_GetCoreDefinition_593660(path: JsonNode; query: JsonNode;
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
  var valid_593662 = path.getOrDefault("CoreDefinitionId")
  valid_593662 = validateParameter(valid_593662, JString, required = true,
                                 default = nil)
  if valid_593662 != nil:
    section.add "CoreDefinitionId", valid_593662
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
  var valid_593663 = header.getOrDefault("X-Amz-Signature")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-Signature", valid_593663
  var valid_593664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Content-Sha256", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-Date")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Date", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Credential")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Credential", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Security-Token")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Security-Token", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Algorithm")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Algorithm", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-SignedHeaders", valid_593669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593670: Call_GetCoreDefinition_593659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_593670.validator(path, query, header, formData, body)
  let scheme = call_593670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593670.url(scheme.get, call_593670.host, call_593670.base,
                         call_593670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593670, url, valid)

proc call*(call_593671: Call_GetCoreDefinition_593659; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_593672 = newJObject()
  add(path_593672, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_593671.call(path_593672, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_593659(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_593660, base: "/",
    url: url_GetCoreDefinition_593661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_593689 = ref object of OpenApiRestCall_592348
proc url_DeleteCoreDefinition_593691(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCoreDefinition_593690(path: JsonNode; query: JsonNode;
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
  var valid_593692 = path.getOrDefault("CoreDefinitionId")
  valid_593692 = validateParameter(valid_593692, JString, required = true,
                                 default = nil)
  if valid_593692 != nil:
    section.add "CoreDefinitionId", valid_593692
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
  var valid_593693 = header.getOrDefault("X-Amz-Signature")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Signature", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Content-Sha256", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Date")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Date", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Credential")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Credential", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Security-Token")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Security-Token", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Algorithm")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Algorithm", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-SignedHeaders", valid_593699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593700: Call_DeleteCoreDefinition_593689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_593700.validator(path, query, header, formData, body)
  let scheme = call_593700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593700.url(scheme.get, call_593700.host, call_593700.base,
                         call_593700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593700, url, valid)

proc call*(call_593701: Call_DeleteCoreDefinition_593689; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_593702 = newJObject()
  add(path_593702, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_593701.call(path_593702, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_593689(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_593690, base: "/",
    url: url_DeleteCoreDefinition_593691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_593717 = ref object of OpenApiRestCall_592348
proc url_UpdateDeviceDefinition_593719(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceDefinition_593718(path: JsonNode; query: JsonNode;
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
  var valid_593720 = path.getOrDefault("DeviceDefinitionId")
  valid_593720 = validateParameter(valid_593720, JString, required = true,
                                 default = nil)
  if valid_593720 != nil:
    section.add "DeviceDefinitionId", valid_593720
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
  var valid_593721 = header.getOrDefault("X-Amz-Signature")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-Signature", valid_593721
  var valid_593722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593722 = validateParameter(valid_593722, JString, required = false,
                                 default = nil)
  if valid_593722 != nil:
    section.add "X-Amz-Content-Sha256", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Date")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Date", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Credential")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Credential", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Security-Token")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Security-Token", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Algorithm")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Algorithm", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-SignedHeaders", valid_593727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593729: Call_UpdateDeviceDefinition_593717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_593729.validator(path, query, header, formData, body)
  let scheme = call_593729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593729.url(scheme.get, call_593729.host, call_593729.base,
                         call_593729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593729, url, valid)

proc call*(call_593730: Call_UpdateDeviceDefinition_593717;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_593731 = newJObject()
  var body_593732 = newJObject()
  add(path_593731, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_593732 = body
  result = call_593730.call(path_593731, nil, nil, nil, body_593732)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_593717(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_593718, base: "/",
    url: url_UpdateDeviceDefinition_593719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_593703 = ref object of OpenApiRestCall_592348
proc url_GetDeviceDefinition_593705(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceDefinition_593704(path: JsonNode; query: JsonNode;
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
  var valid_593706 = path.getOrDefault("DeviceDefinitionId")
  valid_593706 = validateParameter(valid_593706, JString, required = true,
                                 default = nil)
  if valid_593706 != nil:
    section.add "DeviceDefinitionId", valid_593706
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
  var valid_593707 = header.getOrDefault("X-Amz-Signature")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Signature", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Content-Sha256", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Date")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Date", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Credential")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Credential", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Security-Token")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Security-Token", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Algorithm")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Algorithm", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-SignedHeaders", valid_593713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593714: Call_GetDeviceDefinition_593703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_593714.validator(path, query, header, formData, body)
  let scheme = call_593714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593714.url(scheme.get, call_593714.host, call_593714.base,
                         call_593714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593714, url, valid)

proc call*(call_593715: Call_GetDeviceDefinition_593703; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_593716 = newJObject()
  add(path_593716, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_593715.call(path_593716, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_593703(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_593704, base: "/",
    url: url_GetDeviceDefinition_593705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_593733 = ref object of OpenApiRestCall_592348
proc url_DeleteDeviceDefinition_593735(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceDefinition_593734(path: JsonNode; query: JsonNode;
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
  var valid_593736 = path.getOrDefault("DeviceDefinitionId")
  valid_593736 = validateParameter(valid_593736, JString, required = true,
                                 default = nil)
  if valid_593736 != nil:
    section.add "DeviceDefinitionId", valid_593736
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
  var valid_593737 = header.getOrDefault("X-Amz-Signature")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-Signature", valid_593737
  var valid_593738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Content-Sha256", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Date")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Date", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Credential")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Credential", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-Security-Token")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Security-Token", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Algorithm")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Algorithm", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-SignedHeaders", valid_593743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593744: Call_DeleteDeviceDefinition_593733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_593744.validator(path, query, header, formData, body)
  let scheme = call_593744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593744.url(scheme.get, call_593744.host, call_593744.base,
                         call_593744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593744, url, valid)

proc call*(call_593745: Call_DeleteDeviceDefinition_593733;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_593746 = newJObject()
  add(path_593746, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_593745.call(path_593746, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_593733(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_593734, base: "/",
    url: url_DeleteDeviceDefinition_593735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_593761 = ref object of OpenApiRestCall_592348
proc url_UpdateFunctionDefinition_593763(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionDefinition_593762(path: JsonNode; query: JsonNode;
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
  var valid_593764 = path.getOrDefault("FunctionDefinitionId")
  valid_593764 = validateParameter(valid_593764, JString, required = true,
                                 default = nil)
  if valid_593764 != nil:
    section.add "FunctionDefinitionId", valid_593764
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
  var valid_593765 = header.getOrDefault("X-Amz-Signature")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Signature", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-Content-Sha256", valid_593766
  var valid_593767 = header.getOrDefault("X-Amz-Date")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Date", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Credential")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Credential", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Security-Token")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Security-Token", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Algorithm")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Algorithm", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-SignedHeaders", valid_593771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593773: Call_UpdateFunctionDefinition_593761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_593773.validator(path, query, header, formData, body)
  let scheme = call_593773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593773.url(scheme.get, call_593773.host, call_593773.base,
                         call_593773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593773, url, valid)

proc call*(call_593774: Call_UpdateFunctionDefinition_593761;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_593775 = newJObject()
  var body_593776 = newJObject()
  add(path_593775, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_593776 = body
  result = call_593774.call(path_593775, nil, nil, nil, body_593776)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_593761(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_593762, base: "/",
    url: url_UpdateFunctionDefinition_593763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_593747 = ref object of OpenApiRestCall_592348
proc url_GetFunctionDefinition_593749(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionDefinition_593748(path: JsonNode; query: JsonNode;
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
  var valid_593750 = path.getOrDefault("FunctionDefinitionId")
  valid_593750 = validateParameter(valid_593750, JString, required = true,
                                 default = nil)
  if valid_593750 != nil:
    section.add "FunctionDefinitionId", valid_593750
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
  var valid_593751 = header.getOrDefault("X-Amz-Signature")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-Signature", valid_593751
  var valid_593752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "X-Amz-Content-Sha256", valid_593752
  var valid_593753 = header.getOrDefault("X-Amz-Date")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "X-Amz-Date", valid_593753
  var valid_593754 = header.getOrDefault("X-Amz-Credential")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "X-Amz-Credential", valid_593754
  var valid_593755 = header.getOrDefault("X-Amz-Security-Token")
  valid_593755 = validateParameter(valid_593755, JString, required = false,
                                 default = nil)
  if valid_593755 != nil:
    section.add "X-Amz-Security-Token", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-Algorithm")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Algorithm", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-SignedHeaders", valid_593757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593758: Call_GetFunctionDefinition_593747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_593758.validator(path, query, header, formData, body)
  let scheme = call_593758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593758.url(scheme.get, call_593758.host, call_593758.base,
                         call_593758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593758, url, valid)

proc call*(call_593759: Call_GetFunctionDefinition_593747;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_593760 = newJObject()
  add(path_593760, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_593759.call(path_593760, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_593747(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_593748, base: "/",
    url: url_GetFunctionDefinition_593749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_593777 = ref object of OpenApiRestCall_592348
proc url_DeleteFunctionDefinition_593779(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionDefinition_593778(path: JsonNode; query: JsonNode;
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
  var valid_593780 = path.getOrDefault("FunctionDefinitionId")
  valid_593780 = validateParameter(valid_593780, JString, required = true,
                                 default = nil)
  if valid_593780 != nil:
    section.add "FunctionDefinitionId", valid_593780
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
  var valid_593781 = header.getOrDefault("X-Amz-Signature")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "X-Amz-Signature", valid_593781
  var valid_593782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "X-Amz-Content-Sha256", valid_593782
  var valid_593783 = header.getOrDefault("X-Amz-Date")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "X-Amz-Date", valid_593783
  var valid_593784 = header.getOrDefault("X-Amz-Credential")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "X-Amz-Credential", valid_593784
  var valid_593785 = header.getOrDefault("X-Amz-Security-Token")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Security-Token", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Algorithm")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Algorithm", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-SignedHeaders", valid_593787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593788: Call_DeleteFunctionDefinition_593777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_593788.validator(path, query, header, formData, body)
  let scheme = call_593788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593788.url(scheme.get, call_593788.host, call_593788.base,
                         call_593788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593788, url, valid)

proc call*(call_593789: Call_DeleteFunctionDefinition_593777;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_593790 = newJObject()
  add(path_593790, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_593789.call(path_593790, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_593777(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_593778, base: "/",
    url: url_DeleteFunctionDefinition_593779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_593805 = ref object of OpenApiRestCall_592348
proc url_UpdateGroup_593807(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_593806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593808 = path.getOrDefault("GroupId")
  valid_593808 = validateParameter(valid_593808, JString, required = true,
                                 default = nil)
  if valid_593808 != nil:
    section.add "GroupId", valid_593808
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
  var valid_593809 = header.getOrDefault("X-Amz-Signature")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Signature", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Content-Sha256", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Date")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Date", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Credential")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Credential", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Security-Token")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Security-Token", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Algorithm")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Algorithm", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-SignedHeaders", valid_593815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593817: Call_UpdateGroup_593805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_593817.validator(path, query, header, formData, body)
  let scheme = call_593817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593817.url(scheme.get, call_593817.host, call_593817.base,
                         call_593817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593817, url, valid)

proc call*(call_593818: Call_UpdateGroup_593805; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_593819 = newJObject()
  var body_593820 = newJObject()
  add(path_593819, "GroupId", newJString(GroupId))
  if body != nil:
    body_593820 = body
  result = call_593818.call(path_593819, nil, nil, nil, body_593820)

var updateGroup* = Call_UpdateGroup_593805(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_593806,
                                        base: "/", url: url_UpdateGroup_593807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_593791 = ref object of OpenApiRestCall_592348
proc url_GetGroup_593793(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_593792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593794 = path.getOrDefault("GroupId")
  valid_593794 = validateParameter(valid_593794, JString, required = true,
                                 default = nil)
  if valid_593794 != nil:
    section.add "GroupId", valid_593794
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
  var valid_593795 = header.getOrDefault("X-Amz-Signature")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Signature", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Content-Sha256", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Date")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Date", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Credential")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Credential", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Security-Token")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Security-Token", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Algorithm")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Algorithm", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-SignedHeaders", valid_593801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593802: Call_GetGroup_593791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_593802.validator(path, query, header, formData, body)
  let scheme = call_593802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593802.url(scheme.get, call_593802.host, call_593802.base,
                         call_593802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593802, url, valid)

proc call*(call_593803: Call_GetGroup_593791; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_593804 = newJObject()
  add(path_593804, "GroupId", newJString(GroupId))
  result = call_593803.call(path_593804, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_593791(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_593792, base: "/",
                                  url: url_GetGroup_593793,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_593821 = ref object of OpenApiRestCall_592348
proc url_DeleteGroup_593823(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_593822(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593824 = path.getOrDefault("GroupId")
  valid_593824 = validateParameter(valid_593824, JString, required = true,
                                 default = nil)
  if valid_593824 != nil:
    section.add "GroupId", valid_593824
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
  var valid_593825 = header.getOrDefault("X-Amz-Signature")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-Signature", valid_593825
  var valid_593826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "X-Amz-Content-Sha256", valid_593826
  var valid_593827 = header.getOrDefault("X-Amz-Date")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "X-Amz-Date", valid_593827
  var valid_593828 = header.getOrDefault("X-Amz-Credential")
  valid_593828 = validateParameter(valid_593828, JString, required = false,
                                 default = nil)
  if valid_593828 != nil:
    section.add "X-Amz-Credential", valid_593828
  var valid_593829 = header.getOrDefault("X-Amz-Security-Token")
  valid_593829 = validateParameter(valid_593829, JString, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "X-Amz-Security-Token", valid_593829
  var valid_593830 = header.getOrDefault("X-Amz-Algorithm")
  valid_593830 = validateParameter(valid_593830, JString, required = false,
                                 default = nil)
  if valid_593830 != nil:
    section.add "X-Amz-Algorithm", valid_593830
  var valid_593831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-SignedHeaders", valid_593831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593832: Call_DeleteGroup_593821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_593832.validator(path, query, header, formData, body)
  let scheme = call_593832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593832.url(scheme.get, call_593832.host, call_593832.base,
                         call_593832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593832, url, valid)

proc call*(call_593833: Call_DeleteGroup_593821; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_593834 = newJObject()
  add(path_593834, "GroupId", newJString(GroupId))
  result = call_593833.call(path_593834, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_593821(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_593822,
                                        base: "/", url: url_DeleteGroup_593823,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_593849 = ref object of OpenApiRestCall_592348
proc url_UpdateLoggerDefinition_593851(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLoggerDefinition_593850(path: JsonNode; query: JsonNode;
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
  var valid_593852 = path.getOrDefault("LoggerDefinitionId")
  valid_593852 = validateParameter(valid_593852, JString, required = true,
                                 default = nil)
  if valid_593852 != nil:
    section.add "LoggerDefinitionId", valid_593852
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
  var valid_593853 = header.getOrDefault("X-Amz-Signature")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Signature", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Content-Sha256", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Date")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Date", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Credential")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Credential", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Security-Token")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Security-Token", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Algorithm")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Algorithm", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-SignedHeaders", valid_593859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593861: Call_UpdateLoggerDefinition_593849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_593861.validator(path, query, header, formData, body)
  let scheme = call_593861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593861.url(scheme.get, call_593861.host, call_593861.base,
                         call_593861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593861, url, valid)

proc call*(call_593862: Call_UpdateLoggerDefinition_593849;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_593863 = newJObject()
  var body_593864 = newJObject()
  add(path_593863, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_593864 = body
  result = call_593862.call(path_593863, nil, nil, nil, body_593864)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_593849(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_593850, base: "/",
    url: url_UpdateLoggerDefinition_593851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_593835 = ref object of OpenApiRestCall_592348
proc url_GetLoggerDefinition_593837(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoggerDefinition_593836(path: JsonNode; query: JsonNode;
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
  var valid_593838 = path.getOrDefault("LoggerDefinitionId")
  valid_593838 = validateParameter(valid_593838, JString, required = true,
                                 default = nil)
  if valid_593838 != nil:
    section.add "LoggerDefinitionId", valid_593838
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
  var valid_593839 = header.getOrDefault("X-Amz-Signature")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Signature", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Content-Sha256", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Date")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Date", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Credential")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Credential", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-Security-Token")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Security-Token", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Algorithm")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Algorithm", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-SignedHeaders", valid_593845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593846: Call_GetLoggerDefinition_593835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_593846.validator(path, query, header, formData, body)
  let scheme = call_593846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593846.url(scheme.get, call_593846.host, call_593846.base,
                         call_593846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593846, url, valid)

proc call*(call_593847: Call_GetLoggerDefinition_593835; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_593848 = newJObject()
  add(path_593848, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_593847.call(path_593848, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_593835(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_593836, base: "/",
    url: url_GetLoggerDefinition_593837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_593865 = ref object of OpenApiRestCall_592348
proc url_DeleteLoggerDefinition_593867(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoggerDefinition_593866(path: JsonNode; query: JsonNode;
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
  var valid_593868 = path.getOrDefault("LoggerDefinitionId")
  valid_593868 = validateParameter(valid_593868, JString, required = true,
                                 default = nil)
  if valid_593868 != nil:
    section.add "LoggerDefinitionId", valid_593868
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
  var valid_593869 = header.getOrDefault("X-Amz-Signature")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Signature", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Content-Sha256", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Date")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Date", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Credential")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Credential", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Security-Token")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Security-Token", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-Algorithm")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Algorithm", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-SignedHeaders", valid_593875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593876: Call_DeleteLoggerDefinition_593865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_593876.validator(path, query, header, formData, body)
  let scheme = call_593876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593876.url(scheme.get, call_593876.host, call_593876.base,
                         call_593876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593876, url, valid)

proc call*(call_593877: Call_DeleteLoggerDefinition_593865;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_593878 = newJObject()
  add(path_593878, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_593877.call(path_593878, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_593865(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_593866, base: "/",
    url: url_DeleteLoggerDefinition_593867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_593893 = ref object of OpenApiRestCall_592348
proc url_UpdateResourceDefinition_593895(protocol: Scheme; host: string;
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

proc validate_UpdateResourceDefinition_593894(path: JsonNode; query: JsonNode;
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
  var valid_593896 = path.getOrDefault("ResourceDefinitionId")
  valid_593896 = validateParameter(valid_593896, JString, required = true,
                                 default = nil)
  if valid_593896 != nil:
    section.add "ResourceDefinitionId", valid_593896
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
  var valid_593897 = header.getOrDefault("X-Amz-Signature")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Signature", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-Content-Sha256", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Date")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Date", valid_593899
  var valid_593900 = header.getOrDefault("X-Amz-Credential")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "X-Amz-Credential", valid_593900
  var valid_593901 = header.getOrDefault("X-Amz-Security-Token")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Security-Token", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-Algorithm")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-Algorithm", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-SignedHeaders", valid_593903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593905: Call_UpdateResourceDefinition_593893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_593905.validator(path, query, header, formData, body)
  let scheme = call_593905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593905.url(scheme.get, call_593905.host, call_593905.base,
                         call_593905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593905, url, valid)

proc call*(call_593906: Call_UpdateResourceDefinition_593893; body: JsonNode;
          ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_593907 = newJObject()
  var body_593908 = newJObject()
  if body != nil:
    body_593908 = body
  add(path_593907, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_593906.call(path_593907, nil, nil, nil, body_593908)

var updateResourceDefinition* = Call_UpdateResourceDefinition_593893(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_593894, base: "/",
    url: url_UpdateResourceDefinition_593895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_593879 = ref object of OpenApiRestCall_592348
proc url_GetResourceDefinition_593881(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceDefinition_593880(path: JsonNode; query: JsonNode;
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
  var valid_593882 = path.getOrDefault("ResourceDefinitionId")
  valid_593882 = validateParameter(valid_593882, JString, required = true,
                                 default = nil)
  if valid_593882 != nil:
    section.add "ResourceDefinitionId", valid_593882
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
  var valid_593883 = header.getOrDefault("X-Amz-Signature")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Signature", valid_593883
  var valid_593884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Content-Sha256", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Date")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Date", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Credential")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Credential", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Security-Token")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Security-Token", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Algorithm")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Algorithm", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-SignedHeaders", valid_593889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593890: Call_GetResourceDefinition_593879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_593890.validator(path, query, header, formData, body)
  let scheme = call_593890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593890.url(scheme.get, call_593890.host, call_593890.base,
                         call_593890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593890, url, valid)

proc call*(call_593891: Call_GetResourceDefinition_593879;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_593892 = newJObject()
  add(path_593892, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_593891.call(path_593892, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_593879(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_593880, base: "/",
    url: url_GetResourceDefinition_593881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_593909 = ref object of OpenApiRestCall_592348
proc url_DeleteResourceDefinition_593911(protocol: Scheme; host: string;
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

proc validate_DeleteResourceDefinition_593910(path: JsonNode; query: JsonNode;
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
  var valid_593912 = path.getOrDefault("ResourceDefinitionId")
  valid_593912 = validateParameter(valid_593912, JString, required = true,
                                 default = nil)
  if valid_593912 != nil:
    section.add "ResourceDefinitionId", valid_593912
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
  var valid_593913 = header.getOrDefault("X-Amz-Signature")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "X-Amz-Signature", valid_593913
  var valid_593914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593914 = validateParameter(valid_593914, JString, required = false,
                                 default = nil)
  if valid_593914 != nil:
    section.add "X-Amz-Content-Sha256", valid_593914
  var valid_593915 = header.getOrDefault("X-Amz-Date")
  valid_593915 = validateParameter(valid_593915, JString, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "X-Amz-Date", valid_593915
  var valid_593916 = header.getOrDefault("X-Amz-Credential")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "X-Amz-Credential", valid_593916
  var valid_593917 = header.getOrDefault("X-Amz-Security-Token")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "X-Amz-Security-Token", valid_593917
  var valid_593918 = header.getOrDefault("X-Amz-Algorithm")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "X-Amz-Algorithm", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-SignedHeaders", valid_593919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593920: Call_DeleteResourceDefinition_593909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_593920.validator(path, query, header, formData, body)
  let scheme = call_593920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593920.url(scheme.get, call_593920.host, call_593920.base,
                         call_593920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593920, url, valid)

proc call*(call_593921: Call_DeleteResourceDefinition_593909;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_593922 = newJObject()
  add(path_593922, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_593921.call(path_593922, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_593909(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_593910, base: "/",
    url: url_DeleteResourceDefinition_593911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_593937 = ref object of OpenApiRestCall_592348
proc url_UpdateSubscriptionDefinition_593939(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_593938(path: JsonNode; query: JsonNode;
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
  var valid_593940 = path.getOrDefault("SubscriptionDefinitionId")
  valid_593940 = validateParameter(valid_593940, JString, required = true,
                                 default = nil)
  if valid_593940 != nil:
    section.add "SubscriptionDefinitionId", valid_593940
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
  var valid_593941 = header.getOrDefault("X-Amz-Signature")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Signature", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-Content-Sha256", valid_593942
  var valid_593943 = header.getOrDefault("X-Amz-Date")
  valid_593943 = validateParameter(valid_593943, JString, required = false,
                                 default = nil)
  if valid_593943 != nil:
    section.add "X-Amz-Date", valid_593943
  var valid_593944 = header.getOrDefault("X-Amz-Credential")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "X-Amz-Credential", valid_593944
  var valid_593945 = header.getOrDefault("X-Amz-Security-Token")
  valid_593945 = validateParameter(valid_593945, JString, required = false,
                                 default = nil)
  if valid_593945 != nil:
    section.add "X-Amz-Security-Token", valid_593945
  var valid_593946 = header.getOrDefault("X-Amz-Algorithm")
  valid_593946 = validateParameter(valid_593946, JString, required = false,
                                 default = nil)
  if valid_593946 != nil:
    section.add "X-Amz-Algorithm", valid_593946
  var valid_593947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "X-Amz-SignedHeaders", valid_593947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593949: Call_UpdateSubscriptionDefinition_593937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_593949.validator(path, query, header, formData, body)
  let scheme = call_593949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593949.url(scheme.get, call_593949.host, call_593949.base,
                         call_593949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593949, url, valid)

proc call*(call_593950: Call_UpdateSubscriptionDefinition_593937;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_593951 = newJObject()
  var body_593952 = newJObject()
  add(path_593951, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_593952 = body
  result = call_593950.call(path_593951, nil, nil, nil, body_593952)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_593937(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_593938, base: "/",
    url: url_UpdateSubscriptionDefinition_593939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_593923 = ref object of OpenApiRestCall_592348
proc url_GetSubscriptionDefinition_593925(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_593924(path: JsonNode; query: JsonNode;
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
  var valid_593926 = path.getOrDefault("SubscriptionDefinitionId")
  valid_593926 = validateParameter(valid_593926, JString, required = true,
                                 default = nil)
  if valid_593926 != nil:
    section.add "SubscriptionDefinitionId", valid_593926
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
  var valid_593927 = header.getOrDefault("X-Amz-Signature")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Signature", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-Content-Sha256", valid_593928
  var valid_593929 = header.getOrDefault("X-Amz-Date")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-Date", valid_593929
  var valid_593930 = header.getOrDefault("X-Amz-Credential")
  valid_593930 = validateParameter(valid_593930, JString, required = false,
                                 default = nil)
  if valid_593930 != nil:
    section.add "X-Amz-Credential", valid_593930
  var valid_593931 = header.getOrDefault("X-Amz-Security-Token")
  valid_593931 = validateParameter(valid_593931, JString, required = false,
                                 default = nil)
  if valid_593931 != nil:
    section.add "X-Amz-Security-Token", valid_593931
  var valid_593932 = header.getOrDefault("X-Amz-Algorithm")
  valid_593932 = validateParameter(valid_593932, JString, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "X-Amz-Algorithm", valid_593932
  var valid_593933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "X-Amz-SignedHeaders", valid_593933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593934: Call_GetSubscriptionDefinition_593923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_593934.validator(path, query, header, formData, body)
  let scheme = call_593934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593934.url(scheme.get, call_593934.host, call_593934.base,
                         call_593934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593934, url, valid)

proc call*(call_593935: Call_GetSubscriptionDefinition_593923;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_593936 = newJObject()
  add(path_593936, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_593935.call(path_593936, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_593923(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_593924, base: "/",
    url: url_GetSubscriptionDefinition_593925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_593953 = ref object of OpenApiRestCall_592348
proc url_DeleteSubscriptionDefinition_593955(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_593954(path: JsonNode; query: JsonNode;
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
  var valid_593956 = path.getOrDefault("SubscriptionDefinitionId")
  valid_593956 = validateParameter(valid_593956, JString, required = true,
                                 default = nil)
  if valid_593956 != nil:
    section.add "SubscriptionDefinitionId", valid_593956
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
  var valid_593957 = header.getOrDefault("X-Amz-Signature")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-Signature", valid_593957
  var valid_593958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "X-Amz-Content-Sha256", valid_593958
  var valid_593959 = header.getOrDefault("X-Amz-Date")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "X-Amz-Date", valid_593959
  var valid_593960 = header.getOrDefault("X-Amz-Credential")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "X-Amz-Credential", valid_593960
  var valid_593961 = header.getOrDefault("X-Amz-Security-Token")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "X-Amz-Security-Token", valid_593961
  var valid_593962 = header.getOrDefault("X-Amz-Algorithm")
  valid_593962 = validateParameter(valid_593962, JString, required = false,
                                 default = nil)
  if valid_593962 != nil:
    section.add "X-Amz-Algorithm", valid_593962
  var valid_593963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-SignedHeaders", valid_593963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593964: Call_DeleteSubscriptionDefinition_593953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_593964.validator(path, query, header, formData, body)
  let scheme = call_593964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593964.url(scheme.get, call_593964.host, call_593964.base,
                         call_593964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593964, url, valid)

proc call*(call_593965: Call_DeleteSubscriptionDefinition_593953;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_593966 = newJObject()
  add(path_593966, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_593965.call(path_593966, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_593953(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_593954, base: "/",
    url: url_DeleteSubscriptionDefinition_593955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_593967 = ref object of OpenApiRestCall_592348
proc url_GetBulkDeploymentStatus_593969(protocol: Scheme; host: string; base: string;
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

proc validate_GetBulkDeploymentStatus_593968(path: JsonNode; query: JsonNode;
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
  var valid_593970 = path.getOrDefault("BulkDeploymentId")
  valid_593970 = validateParameter(valid_593970, JString, required = true,
                                 default = nil)
  if valid_593970 != nil:
    section.add "BulkDeploymentId", valid_593970
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
  var valid_593971 = header.getOrDefault("X-Amz-Signature")
  valid_593971 = validateParameter(valid_593971, JString, required = false,
                                 default = nil)
  if valid_593971 != nil:
    section.add "X-Amz-Signature", valid_593971
  var valid_593972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593972 = validateParameter(valid_593972, JString, required = false,
                                 default = nil)
  if valid_593972 != nil:
    section.add "X-Amz-Content-Sha256", valid_593972
  var valid_593973 = header.getOrDefault("X-Amz-Date")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Date", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Credential")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Credential", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Security-Token")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Security-Token", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Algorithm")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Algorithm", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-SignedHeaders", valid_593977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593978: Call_GetBulkDeploymentStatus_593967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_593978.validator(path, query, header, formData, body)
  let scheme = call_593978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593978.url(scheme.get, call_593978.host, call_593978.base,
                         call_593978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593978, url, valid)

proc call*(call_593979: Call_GetBulkDeploymentStatus_593967;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_593980 = newJObject()
  add(path_593980, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_593979.call(path_593980, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_593967(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_593968, base: "/",
    url: url_GetBulkDeploymentStatus_593969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_593995 = ref object of OpenApiRestCall_592348
proc url_UpdateConnectivityInfo_593997(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnectivityInfo_593996(path: JsonNode; query: JsonNode;
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
  var valid_593998 = path.getOrDefault("ThingName")
  valid_593998 = validateParameter(valid_593998, JString, required = true,
                                 default = nil)
  if valid_593998 != nil:
    section.add "ThingName", valid_593998
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
  var valid_593999 = header.getOrDefault("X-Amz-Signature")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Signature", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Content-Sha256", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Date")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Date", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Credential")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Credential", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Security-Token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Security-Token", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Algorithm")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Algorithm", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-SignedHeaders", valid_594005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594007: Call_UpdateConnectivityInfo_593995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_594007.validator(path, query, header, formData, body)
  let scheme = call_594007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594007.url(scheme.get, call_594007.host, call_594007.base,
                         call_594007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594007, url, valid)

proc call*(call_594008: Call_UpdateConnectivityInfo_593995; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_594009 = newJObject()
  var body_594010 = newJObject()
  add(path_594009, "ThingName", newJString(ThingName))
  if body != nil:
    body_594010 = body
  result = call_594008.call(path_594009, nil, nil, nil, body_594010)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_593995(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_593996, base: "/",
    url: url_UpdateConnectivityInfo_593997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_593981 = ref object of OpenApiRestCall_592348
proc url_GetConnectivityInfo_593983(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectivityInfo_593982(path: JsonNode; query: JsonNode;
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
  var valid_593984 = path.getOrDefault("ThingName")
  valid_593984 = validateParameter(valid_593984, JString, required = true,
                                 default = nil)
  if valid_593984 != nil:
    section.add "ThingName", valid_593984
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
  var valid_593985 = header.getOrDefault("X-Amz-Signature")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Signature", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Content-Sha256", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Date")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Date", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Credential")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Credential", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Security-Token")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Security-Token", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Algorithm")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Algorithm", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-SignedHeaders", valid_593991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593992: Call_GetConnectivityInfo_593981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_593992.validator(path, query, header, formData, body)
  let scheme = call_593992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593992.url(scheme.get, call_593992.host, call_593992.base,
                         call_593992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593992, url, valid)

proc call*(call_593993: Call_GetConnectivityInfo_593981; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_593994 = newJObject()
  add(path_593994, "ThingName", newJString(ThingName))
  result = call_593993.call(path_593994, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_593981(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_593982, base: "/",
    url: url_GetConnectivityInfo_593983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_594011 = ref object of OpenApiRestCall_592348
proc url_GetConnectorDefinitionVersion_594013(protocol: Scheme; host: string;
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

proc validate_GetConnectorDefinitionVersion_594012(path: JsonNode; query: JsonNode;
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
  var valid_594014 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_594014 = validateParameter(valid_594014, JString, required = true,
                                 default = nil)
  if valid_594014 != nil:
    section.add "ConnectorDefinitionVersionId", valid_594014
  var valid_594015 = path.getOrDefault("ConnectorDefinitionId")
  valid_594015 = validateParameter(valid_594015, JString, required = true,
                                 default = nil)
  if valid_594015 != nil:
    section.add "ConnectorDefinitionId", valid_594015
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594016 = query.getOrDefault("NextToken")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "NextToken", valid_594016
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
  var valid_594017 = header.getOrDefault("X-Amz-Signature")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Signature", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Content-Sha256", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Date")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Date", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Credential")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Credential", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Security-Token")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Security-Token", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Algorithm")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Algorithm", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-SignedHeaders", valid_594023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594024: Call_GetConnectorDefinitionVersion_594011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_594024.validator(path, query, header, formData, body)
  let scheme = call_594024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594024.url(scheme.get, call_594024.host, call_594024.base,
                         call_594024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594024, url, valid)

proc call*(call_594025: Call_GetConnectorDefinitionVersion_594011;
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
  var path_594026 = newJObject()
  var query_594027 = newJObject()
  add(path_594026, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_594027, "NextToken", newJString(NextToken))
  add(path_594026, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_594025.call(path_594026, query_594027, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_594011(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_594012, base: "/",
    url: url_GetConnectorDefinitionVersion_594013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_594028 = ref object of OpenApiRestCall_592348
proc url_GetCoreDefinitionVersion_594030(protocol: Scheme; host: string;
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

proc validate_GetCoreDefinitionVersion_594029(path: JsonNode; query: JsonNode;
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
  var valid_594031 = path.getOrDefault("CoreDefinitionVersionId")
  valid_594031 = validateParameter(valid_594031, JString, required = true,
                                 default = nil)
  if valid_594031 != nil:
    section.add "CoreDefinitionVersionId", valid_594031
  var valid_594032 = path.getOrDefault("CoreDefinitionId")
  valid_594032 = validateParameter(valid_594032, JString, required = true,
                                 default = nil)
  if valid_594032 != nil:
    section.add "CoreDefinitionId", valid_594032
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
  var valid_594033 = header.getOrDefault("X-Amz-Signature")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Signature", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Content-Sha256", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Credential")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Credential", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Security-Token")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Security-Token", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-SignedHeaders", valid_594039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594040: Call_GetCoreDefinitionVersion_594028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_594040.validator(path, query, header, formData, body)
  let scheme = call_594040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594040.url(scheme.get, call_594040.host, call_594040.base,
                         call_594040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594040, url, valid)

proc call*(call_594041: Call_GetCoreDefinitionVersion_594028;
          CoreDefinitionVersionId: string; CoreDefinitionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_594042 = newJObject()
  add(path_594042, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  add(path_594042, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_594041.call(path_594042, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_594028(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_594029, base: "/",
    url: url_GetCoreDefinitionVersion_594030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_594043 = ref object of OpenApiRestCall_592348
proc url_GetDeploymentStatus_594045(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStatus_594044(path: JsonNode; query: JsonNode;
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
  var valid_594046 = path.getOrDefault("GroupId")
  valid_594046 = validateParameter(valid_594046, JString, required = true,
                                 default = nil)
  if valid_594046 != nil:
    section.add "GroupId", valid_594046
  var valid_594047 = path.getOrDefault("DeploymentId")
  valid_594047 = validateParameter(valid_594047, JString, required = true,
                                 default = nil)
  if valid_594047 != nil:
    section.add "DeploymentId", valid_594047
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
  var valid_594048 = header.getOrDefault("X-Amz-Signature")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Signature", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Date")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Date", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Credential")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Credential", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Algorithm")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Algorithm", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-SignedHeaders", valid_594054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_GetDeploymentStatus_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_GetDeploymentStatus_594043; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_594057 = newJObject()
  add(path_594057, "GroupId", newJString(GroupId))
  add(path_594057, "DeploymentId", newJString(DeploymentId))
  result = call_594056.call(path_594057, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_594043(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_594044, base: "/",
    url: url_GetDeploymentStatus_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_594058 = ref object of OpenApiRestCall_592348
proc url_GetDeviceDefinitionVersion_594060(protocol: Scheme; host: string;
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

proc validate_GetDeviceDefinitionVersion_594059(path: JsonNode; query: JsonNode;
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
  var valid_594061 = path.getOrDefault("DeviceDefinitionId")
  valid_594061 = validateParameter(valid_594061, JString, required = true,
                                 default = nil)
  if valid_594061 != nil:
    section.add "DeviceDefinitionId", valid_594061
  var valid_594062 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = nil)
  if valid_594062 != nil:
    section.add "DeviceDefinitionVersionId", valid_594062
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594063 = query.getOrDefault("NextToken")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "NextToken", valid_594063
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
  var valid_594064 = header.getOrDefault("X-Amz-Signature")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Signature", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Content-Sha256", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Date")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Date", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Credential")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Credential", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Security-Token")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Security-Token", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Algorithm")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Algorithm", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-SignedHeaders", valid_594070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594071: Call_GetDeviceDefinitionVersion_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_594071.validator(path, query, header, formData, body)
  let scheme = call_594071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594071.url(scheme.get, call_594071.host, call_594071.base,
                         call_594071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594071, url, valid)

proc call*(call_594072: Call_GetDeviceDefinitionVersion_594058;
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
  var path_594073 = newJObject()
  var query_594074 = newJObject()
  add(path_594073, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_594074, "NextToken", newJString(NextToken))
  add(path_594073, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_594072.call(path_594073, query_594074, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_594058(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_594059, base: "/",
    url: url_GetDeviceDefinitionVersion_594060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_594075 = ref object of OpenApiRestCall_592348
proc url_GetFunctionDefinitionVersion_594077(protocol: Scheme; host: string;
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

proc validate_GetFunctionDefinitionVersion_594076(path: JsonNode; query: JsonNode;
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
  var valid_594078 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "FunctionDefinitionVersionId", valid_594078
  var valid_594079 = path.getOrDefault("FunctionDefinitionId")
  valid_594079 = validateParameter(valid_594079, JString, required = true,
                                 default = nil)
  if valid_594079 != nil:
    section.add "FunctionDefinitionId", valid_594079
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594080 = query.getOrDefault("NextToken")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "NextToken", valid_594080
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
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Content-Sha256", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Date")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Date", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Security-Token")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Security-Token", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Algorithm")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Algorithm", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-SignedHeaders", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_GetFunctionDefinitionVersion_594075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_GetFunctionDefinitionVersion_594075;
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
  var path_594090 = newJObject()
  var query_594091 = newJObject()
  add(path_594090, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_594091, "NextToken", newJString(NextToken))
  add(path_594090, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_594089.call(path_594090, query_594091, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_594075(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_594076, base: "/",
    url: url_GetFunctionDefinitionVersion_594077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_594092 = ref object of OpenApiRestCall_592348
proc url_GetGroupCertificateAuthority_594094(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_594093(path: JsonNode; query: JsonNode;
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
  var valid_594095 = path.getOrDefault("GroupId")
  valid_594095 = validateParameter(valid_594095, JString, required = true,
                                 default = nil)
  if valid_594095 != nil:
    section.add "GroupId", valid_594095
  var valid_594096 = path.getOrDefault("CertificateAuthorityId")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "CertificateAuthorityId", valid_594096
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
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Content-Sha256", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Credential")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Credential", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Algorithm")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Algorithm", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-SignedHeaders", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594104: Call_GetGroupCertificateAuthority_594092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_594104.validator(path, query, header, formData, body)
  let scheme = call_594104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594104.url(scheme.get, call_594104.host, call_594104.base,
                         call_594104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594104, url, valid)

proc call*(call_594105: Call_GetGroupCertificateAuthority_594092; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_594106 = newJObject()
  add(path_594106, "GroupId", newJString(GroupId))
  add(path_594106, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_594105.call(path_594106, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_594092(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_594093, base: "/",
    url: url_GetGroupCertificateAuthority_594094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_594121 = ref object of OpenApiRestCall_592348
proc url_UpdateGroupCertificateConfiguration_594123(protocol: Scheme; host: string;
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

proc validate_UpdateGroupCertificateConfiguration_594122(path: JsonNode;
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
  var valid_594124 = path.getOrDefault("GroupId")
  valid_594124 = validateParameter(valid_594124, JString, required = true,
                                 default = nil)
  if valid_594124 != nil:
    section.add "GroupId", valid_594124
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
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Content-Sha256", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Date")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Date", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Security-Token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Security-Token", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Algorithm")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Algorithm", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-SignedHeaders", valid_594131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594133: Call_UpdateGroupCertificateConfiguration_594121;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_594133.validator(path, query, header, formData, body)
  let scheme = call_594133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594133.url(scheme.get, call_594133.host, call_594133.base,
                         call_594133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594133, url, valid)

proc call*(call_594134: Call_UpdateGroupCertificateConfiguration_594121;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_594135 = newJObject()
  var body_594136 = newJObject()
  add(path_594135, "GroupId", newJString(GroupId))
  if body != nil:
    body_594136 = body
  result = call_594134.call(path_594135, nil, nil, nil, body_594136)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_594121(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_594122, base: "/",
    url: url_UpdateGroupCertificateConfiguration_594123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_594107 = ref object of OpenApiRestCall_592348
proc url_GetGroupCertificateConfiguration_594109(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateConfiguration_594108(path: JsonNode;
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
  var valid_594110 = path.getOrDefault("GroupId")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = nil)
  if valid_594110 != nil:
    section.add "GroupId", valid_594110
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
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Content-Sha256", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Date")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Date", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Security-Token")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Security-Token", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Algorithm")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Algorithm", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-SignedHeaders", valid_594117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594118: Call_GetGroupCertificateConfiguration_594107;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_594118.validator(path, query, header, formData, body)
  let scheme = call_594118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594118.url(scheme.get, call_594118.host, call_594118.base,
                         call_594118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594118, url, valid)

proc call*(call_594119: Call_GetGroupCertificateConfiguration_594107;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_594120 = newJObject()
  add(path_594120, "GroupId", newJString(GroupId))
  result = call_594119.call(path_594120, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_594107(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_594108, base: "/",
    url: url_GetGroupCertificateConfiguration_594109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_594137 = ref object of OpenApiRestCall_592348
proc url_GetGroupVersion_594139(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupVersion_594138(path: JsonNode; query: JsonNode;
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
  var valid_594140 = path.getOrDefault("GroupVersionId")
  valid_594140 = validateParameter(valid_594140, JString, required = true,
                                 default = nil)
  if valid_594140 != nil:
    section.add "GroupVersionId", valid_594140
  var valid_594141 = path.getOrDefault("GroupId")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "GroupId", valid_594141
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
  var valid_594142 = header.getOrDefault("X-Amz-Signature")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Signature", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Content-Sha256", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Date")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Date", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Credential")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Credential", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Security-Token")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Security-Token", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Algorithm")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Algorithm", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-SignedHeaders", valid_594148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594149: Call_GetGroupVersion_594137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_594149.validator(path, query, header, formData, body)
  let scheme = call_594149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594149.url(scheme.get, call_594149.host, call_594149.base,
                         call_594149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594149, url, valid)

proc call*(call_594150: Call_GetGroupVersion_594137; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_594151 = newJObject()
  add(path_594151, "GroupVersionId", newJString(GroupVersionId))
  add(path_594151, "GroupId", newJString(GroupId))
  result = call_594150.call(path_594151, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_594137(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_594138, base: "/", url: url_GetGroupVersion_594139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_594152 = ref object of OpenApiRestCall_592348
proc url_GetLoggerDefinitionVersion_594154(protocol: Scheme; host: string;
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

proc validate_GetLoggerDefinitionVersion_594153(path: JsonNode; query: JsonNode;
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
  var valid_594155 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_594155 = validateParameter(valid_594155, JString, required = true,
                                 default = nil)
  if valid_594155 != nil:
    section.add "LoggerDefinitionVersionId", valid_594155
  var valid_594156 = path.getOrDefault("LoggerDefinitionId")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = nil)
  if valid_594156 != nil:
    section.add "LoggerDefinitionId", valid_594156
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594157 = query.getOrDefault("NextToken")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "NextToken", valid_594157
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
  var valid_594158 = header.getOrDefault("X-Amz-Signature")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Signature", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Content-Sha256", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Date")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Date", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Credential")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Credential", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Security-Token")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Security-Token", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Algorithm")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Algorithm", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-SignedHeaders", valid_594164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594165: Call_GetLoggerDefinitionVersion_594152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_594165.validator(path, query, header, formData, body)
  let scheme = call_594165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594165.url(scheme.get, call_594165.host, call_594165.base,
                         call_594165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594165, url, valid)

proc call*(call_594166: Call_GetLoggerDefinitionVersion_594152;
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
  var path_594167 = newJObject()
  var query_594168 = newJObject()
  add(path_594167, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_594168, "NextToken", newJString(NextToken))
  add(path_594167, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_594166.call(path_594167, query_594168, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_594152(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_594153, base: "/",
    url: url_GetLoggerDefinitionVersion_594154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_594169 = ref object of OpenApiRestCall_592348
proc url_GetResourceDefinitionVersion_594171(protocol: Scheme; host: string;
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

proc validate_GetResourceDefinitionVersion_594170(path: JsonNode; query: JsonNode;
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
  var valid_594172 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_594172 = validateParameter(valid_594172, JString, required = true,
                                 default = nil)
  if valid_594172 != nil:
    section.add "ResourceDefinitionVersionId", valid_594172
  var valid_594173 = path.getOrDefault("ResourceDefinitionId")
  valid_594173 = validateParameter(valid_594173, JString, required = true,
                                 default = nil)
  if valid_594173 != nil:
    section.add "ResourceDefinitionId", valid_594173
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
  var valid_594174 = header.getOrDefault("X-Amz-Signature")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Signature", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Content-Sha256", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Date")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Date", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Credential")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Credential", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Security-Token")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Security-Token", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Algorithm")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Algorithm", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-SignedHeaders", valid_594180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594181: Call_GetResourceDefinitionVersion_594169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_594181.validator(path, query, header, formData, body)
  let scheme = call_594181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594181.url(scheme.get, call_594181.host, call_594181.base,
                         call_594181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594181, url, valid)

proc call*(call_594182: Call_GetResourceDefinitionVersion_594169;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_594183 = newJObject()
  add(path_594183, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_594183, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_594182.call(path_594183, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_594169(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_594170, base: "/",
    url: url_GetResourceDefinitionVersion_594171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_594184 = ref object of OpenApiRestCall_592348
proc url_GetSubscriptionDefinitionVersion_594186(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinitionVersion_594185(path: JsonNode;
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
  var valid_594187 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_594187 = validateParameter(valid_594187, JString, required = true,
                                 default = nil)
  if valid_594187 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_594187
  var valid_594188 = path.getOrDefault("SubscriptionDefinitionId")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "SubscriptionDefinitionId", valid_594188
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594189 = query.getOrDefault("NextToken")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "NextToken", valid_594189
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
  var valid_594190 = header.getOrDefault("X-Amz-Signature")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Signature", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Content-Sha256", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Date")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Date", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Credential")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Credential", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Security-Token")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Security-Token", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Algorithm")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Algorithm", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594197: Call_GetSubscriptionDefinitionVersion_594184;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_594197.validator(path, query, header, formData, body)
  let scheme = call_594197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594197.url(scheme.get, call_594197.host, call_594197.base,
                         call_594197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594197, url, valid)

proc call*(call_594198: Call_GetSubscriptionDefinitionVersion_594184;
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
  var path_594199 = newJObject()
  var query_594200 = newJObject()
  add(path_594199, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_594200, "NextToken", newJString(NextToken))
  add(path_594199, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_594198.call(path_594199, query_594200, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_594184(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_594185, base: "/",
    url: url_GetSubscriptionDefinitionVersion_594186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_594201 = ref object of OpenApiRestCall_592348
proc url_ListBulkDeploymentDetailedReports_594203(protocol: Scheme; host: string;
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

proc validate_ListBulkDeploymentDetailedReports_594202(path: JsonNode;
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
  var valid_594204 = path.getOrDefault("BulkDeploymentId")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = nil)
  if valid_594204 != nil:
    section.add "BulkDeploymentId", valid_594204
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_594205 = query.getOrDefault("MaxResults")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "MaxResults", valid_594205
  var valid_594206 = query.getOrDefault("NextToken")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "NextToken", valid_594206
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
  var valid_594207 = header.getOrDefault("X-Amz-Signature")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Signature", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Content-Sha256", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Credential")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Credential", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Security-Token")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Security-Token", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-SignedHeaders", valid_594213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594214: Call_ListBulkDeploymentDetailedReports_594201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_594214.validator(path, query, header, formData, body)
  let scheme = call_594214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594214.url(scheme.get, call_594214.host, call_594214.base,
                         call_594214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594214, url, valid)

proc call*(call_594215: Call_ListBulkDeploymentDetailedReports_594201;
          BulkDeploymentId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_594216 = newJObject()
  var query_594217 = newJObject()
  add(query_594217, "MaxResults", newJString(MaxResults))
  add(query_594217, "NextToken", newJString(NextToken))
  add(path_594216, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_594215.call(path_594216, query_594217, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_594201(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_594202, base: "/",
    url: url_ListBulkDeploymentDetailedReports_594203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_594233 = ref object of OpenApiRestCall_592348
proc url_StartBulkDeployment_594235(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBulkDeployment_594234(path: JsonNode; query: JsonNode;
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
  var valid_594236 = header.getOrDefault("X-Amz-Signature")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Signature", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Content-Sha256", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Date")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Date", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Credential")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Credential", valid_594239
  var valid_594240 = header.getOrDefault("X-Amzn-Client-Token")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amzn-Client-Token", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Security-Token")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Security-Token", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Algorithm")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Algorithm", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-SignedHeaders", valid_594243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594245: Call_StartBulkDeployment_594233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_594245.validator(path, query, header, formData, body)
  let scheme = call_594245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594245.url(scheme.get, call_594245.host, call_594245.base,
                         call_594245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594245, url, valid)

proc call*(call_594246: Call_StartBulkDeployment_594233; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_594247 = newJObject()
  if body != nil:
    body_594247 = body
  result = call_594246.call(nil, nil, nil, nil, body_594247)

var startBulkDeployment* = Call_StartBulkDeployment_594233(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_594234, base: "/",
    url: url_StartBulkDeployment_594235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_594218 = ref object of OpenApiRestCall_592348
proc url_ListBulkDeployments_594220(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBulkDeployments_594219(path: JsonNode; query: JsonNode;
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
  var valid_594221 = query.getOrDefault("MaxResults")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "MaxResults", valid_594221
  var valid_594222 = query.getOrDefault("NextToken")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "NextToken", valid_594222
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
  var valid_594223 = header.getOrDefault("X-Amz-Signature")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Signature", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Date")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Date", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Credential")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Credential", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Algorithm")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Algorithm", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_ListBulkDeployments_594218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_ListBulkDeployments_594218; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_594232 = newJObject()
  add(query_594232, "MaxResults", newJString(MaxResults))
  add(query_594232, "NextToken", newJString(NextToken))
  result = call_594231.call(nil, query_594232, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_594218(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_594219, base: "/",
    url: url_ListBulkDeployments_594220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594262 = ref object of OpenApiRestCall_592348
proc url_TagResource_594264(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594265 = path.getOrDefault("resource-arn")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "resource-arn", valid_594265
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
  var valid_594266 = header.getOrDefault("X-Amz-Signature")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Signature", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Content-Sha256", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Date")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Date", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Credential")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Credential", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Security-Token")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Security-Token", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Algorithm")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Algorithm", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-SignedHeaders", valid_594272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594274: Call_TagResource_594262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_594274.validator(path, query, header, formData, body)
  let scheme = call_594274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594274.url(scheme.get, call_594274.host, call_594274.base,
                         call_594274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594274, url, valid)

proc call*(call_594275: Call_TagResource_594262; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_594276 = newJObject()
  var body_594277 = newJObject()
  add(path_594276, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_594277 = body
  result = call_594275.call(path_594276, nil, nil, nil, body_594277)

var tagResource* = Call_TagResource_594262(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_594263,
                                        base: "/", url: url_TagResource_594264,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594248 = ref object of OpenApiRestCall_592348
proc url_ListTagsForResource_594250(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594249(path: JsonNode; query: JsonNode;
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
  var valid_594251 = path.getOrDefault("resource-arn")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = nil)
  if valid_594251 != nil:
    section.add "resource-arn", valid_594251
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
  var valid_594252 = header.getOrDefault("X-Amz-Signature")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Signature", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Content-Sha256", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Date")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Date", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Credential")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Credential", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Security-Token")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Security-Token", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Algorithm")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Algorithm", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-SignedHeaders", valid_594258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594259: Call_ListTagsForResource_594248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_594259.validator(path, query, header, formData, body)
  let scheme = call_594259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594259.url(scheme.get, call_594259.host, call_594259.base,
                         call_594259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594259, url, valid)

proc call*(call_594260: Call_ListTagsForResource_594248; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_594261 = newJObject()
  add(path_594261, "resource-arn", newJString(resourceArn))
  result = call_594260.call(path_594261, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594248(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_594249, base: "/",
    url: url_ListTagsForResource_594250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_594278 = ref object of OpenApiRestCall_592348
proc url_ResetDeployments_594280(protocol: Scheme; host: string; base: string;
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

proc validate_ResetDeployments_594279(path: JsonNode; query: JsonNode;
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
  var valid_594281 = path.getOrDefault("GroupId")
  valid_594281 = validateParameter(valid_594281, JString, required = true,
                                 default = nil)
  if valid_594281 != nil:
    section.add "GroupId", valid_594281
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
  var valid_594282 = header.getOrDefault("X-Amz-Signature")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Signature", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Content-Sha256", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Date")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Date", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Credential")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Credential", valid_594285
  var valid_594286 = header.getOrDefault("X-Amzn-Client-Token")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amzn-Client-Token", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Algorithm")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Algorithm", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-SignedHeaders", valid_594289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594291: Call_ResetDeployments_594278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_594291.validator(path, query, header, formData, body)
  let scheme = call_594291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594291.url(scheme.get, call_594291.host, call_594291.base,
                         call_594291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594291, url, valid)

proc call*(call_594292: Call_ResetDeployments_594278; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_594293 = newJObject()
  var body_594294 = newJObject()
  add(path_594293, "GroupId", newJString(GroupId))
  if body != nil:
    body_594294 = body
  result = call_594292.call(path_594293, nil, nil, nil, body_594294)

var resetDeployments* = Call_ResetDeployments_594278(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_594279, base: "/",
    url: url_ResetDeployments_594280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_594295 = ref object of OpenApiRestCall_592348
proc url_StopBulkDeployment_594297(protocol: Scheme; host: string; base: string;
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

proc validate_StopBulkDeployment_594296(path: JsonNode; query: JsonNode;
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
  var valid_594298 = path.getOrDefault("BulkDeploymentId")
  valid_594298 = validateParameter(valid_594298, JString, required = true,
                                 default = nil)
  if valid_594298 != nil:
    section.add "BulkDeploymentId", valid_594298
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
  var valid_594299 = header.getOrDefault("X-Amz-Signature")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Signature", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Content-Sha256", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Credential")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Credential", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Security-Token")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Security-Token", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Algorithm")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Algorithm", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-SignedHeaders", valid_594305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594306: Call_StopBulkDeployment_594295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_594306.validator(path, query, header, formData, body)
  let scheme = call_594306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594306.url(scheme.get, call_594306.host, call_594306.base,
                         call_594306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594306, url, valid)

proc call*(call_594307: Call_StopBulkDeployment_594295; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_594308 = newJObject()
  add(path_594308, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_594307.call(path_594308, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_594295(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_594296, base: "/",
    url: url_StopBulkDeployment_594297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594309 = ref object of OpenApiRestCall_592348
proc url_UntagResource_594311(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594312 = path.getOrDefault("resource-arn")
  valid_594312 = validateParameter(valid_594312, JString, required = true,
                                 default = nil)
  if valid_594312 != nil:
    section.add "resource-arn", valid_594312
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594313 = query.getOrDefault("tagKeys")
  valid_594313 = validateParameter(valid_594313, JArray, required = true, default = nil)
  if valid_594313 != nil:
    section.add "tagKeys", valid_594313
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
  var valid_594314 = header.getOrDefault("X-Amz-Signature")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Signature", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Content-Sha256", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Credential")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Credential", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Security-Token")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Security-Token", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Algorithm")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Algorithm", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-SignedHeaders", valid_594320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594321: Call_UntagResource_594309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_594321.validator(path, query, header, formData, body)
  let scheme = call_594321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594321.url(scheme.get, call_594321.host, call_594321.base,
                         call_594321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594321, url, valid)

proc call*(call_594322: Call_UntagResource_594309; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_594323 = newJObject()
  var query_594324 = newJObject()
  add(path_594323, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_594324.add "tagKeys", tagKeys
  result = call_594322.call(path_594323, query_594324, nil, nil, nil)

var untagResource* = Call_UntagResource_594309(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_594310,
    base: "/", url: url_UntagResource_594311, schemes: {Scheme.Https, Scheme.Http})
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
