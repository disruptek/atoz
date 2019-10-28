
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

  OpenApiRestCall_590348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590348): Option[Scheme] {.used.} =
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
  Call_AssociateRoleToGroup_590957 = ref object of OpenApiRestCall_590348
proc url_AssociateRoleToGroup_590959(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRoleToGroup_590958(path: JsonNode; query: JsonNode;
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
  var valid_590960 = path.getOrDefault("GroupId")
  valid_590960 = validateParameter(valid_590960, JString, required = true,
                                 default = nil)
  if valid_590960 != nil:
    section.add "GroupId", valid_590960
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
  var valid_590961 = header.getOrDefault("X-Amz-Signature")
  valid_590961 = validateParameter(valid_590961, JString, required = false,
                                 default = nil)
  if valid_590961 != nil:
    section.add "X-Amz-Signature", valid_590961
  var valid_590962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590962 = validateParameter(valid_590962, JString, required = false,
                                 default = nil)
  if valid_590962 != nil:
    section.add "X-Amz-Content-Sha256", valid_590962
  var valid_590963 = header.getOrDefault("X-Amz-Date")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Date", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Credential")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Credential", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Security-Token")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Security-Token", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Algorithm")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Algorithm", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-SignedHeaders", valid_590967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590969: Call_AssociateRoleToGroup_590957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ## 
  let valid = call_590969.validator(path, query, header, formData, body)
  let scheme = call_590969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590969.url(scheme.get, call_590969.host, call_590969.base,
                         call_590969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590969, url, valid)

proc call*(call_590970: Call_AssociateRoleToGroup_590957; GroupId: string;
          body: JsonNode): Recallable =
  ## associateRoleToGroup
  ## Associates a role with a group. Your Greengrass core will use the role to access AWS cloud services. The role's permissions should allow Greengrass core Lambda functions to perform actions against the cloud.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_590971 = newJObject()
  var body_590972 = newJObject()
  add(path_590971, "GroupId", newJString(GroupId))
  if body != nil:
    body_590972 = body
  result = call_590970.call(path_590971, nil, nil, nil, body_590972)

var associateRoleToGroup* = Call_AssociateRoleToGroup_590957(
    name: "associateRoleToGroup", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_AssociateRoleToGroup_590958, base: "/",
    url: url_AssociateRoleToGroup_590959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssociatedRole_590687 = ref object of OpenApiRestCall_590348
proc url_GetAssociatedRole_590689(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssociatedRole_590688(path: JsonNode; query: JsonNode;
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
  var valid_590815 = path.getOrDefault("GroupId")
  valid_590815 = validateParameter(valid_590815, JString, required = true,
                                 default = nil)
  if valid_590815 != nil:
    section.add "GroupId", valid_590815
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
  var valid_590816 = header.getOrDefault("X-Amz-Signature")
  valid_590816 = validateParameter(valid_590816, JString, required = false,
                                 default = nil)
  if valid_590816 != nil:
    section.add "X-Amz-Signature", valid_590816
  var valid_590817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "X-Amz-Content-Sha256", valid_590817
  var valid_590818 = header.getOrDefault("X-Amz-Date")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "X-Amz-Date", valid_590818
  var valid_590819 = header.getOrDefault("X-Amz-Credential")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Credential", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Security-Token")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Security-Token", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Algorithm")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Algorithm", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-SignedHeaders", valid_590822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590845: Call_GetAssociatedRole_590687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the role associated with a particular group.
  ## 
  let valid = call_590845.validator(path, query, header, formData, body)
  let scheme = call_590845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590845.url(scheme.get, call_590845.host, call_590845.base,
                         call_590845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590845, url, valid)

proc call*(call_590916: Call_GetAssociatedRole_590687; GroupId: string): Recallable =
  ## getAssociatedRole
  ## Retrieves the role associated with a particular group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_590917 = newJObject()
  add(path_590917, "GroupId", newJString(GroupId))
  result = call_590916.call(path_590917, nil, nil, nil, nil)

var getAssociatedRole* = Call_GetAssociatedRole_590687(name: "getAssociatedRole",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/role",
    validator: validate_GetAssociatedRole_590688, base: "/",
    url: url_GetAssociatedRole_590689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRoleFromGroup_590973 = ref object of OpenApiRestCall_590348
proc url_DisassociateRoleFromGroup_590975(protocol: Scheme; host: string;
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

proc validate_DisassociateRoleFromGroup_590974(path: JsonNode; query: JsonNode;
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
  var valid_590976 = path.getOrDefault("GroupId")
  valid_590976 = validateParameter(valid_590976, JString, required = true,
                                 default = nil)
  if valid_590976 != nil:
    section.add "GroupId", valid_590976
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
  var valid_590977 = header.getOrDefault("X-Amz-Signature")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Signature", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Content-Sha256", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Date")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Date", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Credential")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Credential", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Security-Token")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Security-Token", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Algorithm")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Algorithm", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-SignedHeaders", valid_590983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_DisassociateRoleFromGroup_590973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the role from a group.
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_DisassociateRoleFromGroup_590973; GroupId: string): Recallable =
  ## disassociateRoleFromGroup
  ## Disassociates the role from a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_590986 = newJObject()
  add(path_590986, "GroupId", newJString(GroupId))
  result = call_590985.call(path_590986, nil, nil, nil, nil)

var disassociateRoleFromGroup* = Call_DisassociateRoleFromGroup_590973(
    name: "disassociateRoleFromGroup", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/role",
    validator: validate_DisassociateRoleFromGroup_590974, base: "/",
    url: url_DisassociateRoleFromGroup_590975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceRoleToAccount_590999 = ref object of OpenApiRestCall_590348
proc url_AssociateServiceRoleToAccount_591001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateServiceRoleToAccount_591000(path: JsonNode; query: JsonNode;
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
  var valid_591002 = header.getOrDefault("X-Amz-Signature")
  valid_591002 = validateParameter(valid_591002, JString, required = false,
                                 default = nil)
  if valid_591002 != nil:
    section.add "X-Amz-Signature", valid_591002
  var valid_591003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591003 = validateParameter(valid_591003, JString, required = false,
                                 default = nil)
  if valid_591003 != nil:
    section.add "X-Amz-Content-Sha256", valid_591003
  var valid_591004 = header.getOrDefault("X-Amz-Date")
  valid_591004 = validateParameter(valid_591004, JString, required = false,
                                 default = nil)
  if valid_591004 != nil:
    section.add "X-Amz-Date", valid_591004
  var valid_591005 = header.getOrDefault("X-Amz-Credential")
  valid_591005 = validateParameter(valid_591005, JString, required = false,
                                 default = nil)
  if valid_591005 != nil:
    section.add "X-Amz-Credential", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Security-Token")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Security-Token", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Algorithm")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Algorithm", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-SignedHeaders", valid_591008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591010: Call_AssociateServiceRoleToAccount_590999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ## 
  let valid = call_591010.validator(path, query, header, formData, body)
  let scheme = call_591010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591010.url(scheme.get, call_591010.host, call_591010.base,
                         call_591010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591010, url, valid)

proc call*(call_591011: Call_AssociateServiceRoleToAccount_590999; body: JsonNode): Recallable =
  ## associateServiceRoleToAccount
  ## Associates a role with your account. AWS IoT Greengrass will use the role to access your Lambda functions and AWS IoT resources. This is necessary for deployments to succeed. The role must have at least minimum permissions in the policy ''AWSGreengrassResourceAccessRolePolicy''.
  ##   body: JObject (required)
  var body_591012 = newJObject()
  if body != nil:
    body_591012 = body
  result = call_591011.call(nil, nil, nil, nil, body_591012)

var associateServiceRoleToAccount* = Call_AssociateServiceRoleToAccount_590999(
    name: "associateServiceRoleToAccount", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_AssociateServiceRoleToAccount_591000, base: "/",
    url: url_AssociateServiceRoleToAccount_591001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceRoleForAccount_590987 = ref object of OpenApiRestCall_590348
proc url_GetServiceRoleForAccount_590989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceRoleForAccount_590988(path: JsonNode; query: JsonNode;
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
  var valid_590990 = header.getOrDefault("X-Amz-Signature")
  valid_590990 = validateParameter(valid_590990, JString, required = false,
                                 default = nil)
  if valid_590990 != nil:
    section.add "X-Amz-Signature", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Content-Sha256", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Date")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Date", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Credential")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Credential", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Security-Token")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Security-Token", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Algorithm")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Algorithm", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-SignedHeaders", valid_590996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590997: Call_GetServiceRoleForAccount_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the service role that is attached to your account.
  ## 
  let valid = call_590997.validator(path, query, header, formData, body)
  let scheme = call_590997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590997.url(scheme.get, call_590997.host, call_590997.base,
                         call_590997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590997, url, valid)

proc call*(call_590998: Call_GetServiceRoleForAccount_590987): Recallable =
  ## getServiceRoleForAccount
  ## Retrieves the service role that is attached to your account.
  result = call_590998.call(nil, nil, nil, nil, nil)

var getServiceRoleForAccount* = Call_GetServiceRoleForAccount_590987(
    name: "getServiceRoleForAccount", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_GetServiceRoleForAccount_590988, base: "/",
    url: url_GetServiceRoleForAccount_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceRoleFromAccount_591013 = ref object of OpenApiRestCall_590348
proc url_DisassociateServiceRoleFromAccount_591015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateServiceRoleFromAccount_591014(path: JsonNode;
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
  var valid_591016 = header.getOrDefault("X-Amz-Signature")
  valid_591016 = validateParameter(valid_591016, JString, required = false,
                                 default = nil)
  if valid_591016 != nil:
    section.add "X-Amz-Signature", valid_591016
  var valid_591017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-Content-Sha256", valid_591017
  var valid_591018 = header.getOrDefault("X-Amz-Date")
  valid_591018 = validateParameter(valid_591018, JString, required = false,
                                 default = nil)
  if valid_591018 != nil:
    section.add "X-Amz-Date", valid_591018
  var valid_591019 = header.getOrDefault("X-Amz-Credential")
  valid_591019 = validateParameter(valid_591019, JString, required = false,
                                 default = nil)
  if valid_591019 != nil:
    section.add "X-Amz-Credential", valid_591019
  var valid_591020 = header.getOrDefault("X-Amz-Security-Token")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "X-Amz-Security-Token", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Algorithm")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Algorithm", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-SignedHeaders", valid_591022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591023: Call_DisassociateServiceRoleFromAccount_591013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  ## 
  let valid = call_591023.validator(path, query, header, formData, body)
  let scheme = call_591023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591023.url(scheme.get, call_591023.host, call_591023.base,
                         call_591023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591023, url, valid)

proc call*(call_591024: Call_DisassociateServiceRoleFromAccount_591013): Recallable =
  ## disassociateServiceRoleFromAccount
  ## Disassociates the service role from your account. Without a service role, deployments will not work.
  result = call_591024.call(nil, nil, nil, nil, nil)

var disassociateServiceRoleFromAccount* = Call_DisassociateServiceRoleFromAccount_591013(
    name: "disassociateServiceRoleFromAccount", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com", route: "/greengrass/servicerole",
    validator: validate_DisassociateServiceRoleFromAccount_591014, base: "/",
    url: url_DisassociateServiceRoleFromAccount_591015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinition_591040 = ref object of OpenApiRestCall_590348
proc url_CreateConnectorDefinition_591042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConnectorDefinition_591041(path: JsonNode; query: JsonNode;
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
  var valid_591043 = header.getOrDefault("X-Amz-Signature")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-Signature", valid_591043
  var valid_591044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591044 = validateParameter(valid_591044, JString, required = false,
                                 default = nil)
  if valid_591044 != nil:
    section.add "X-Amz-Content-Sha256", valid_591044
  var valid_591045 = header.getOrDefault("X-Amz-Date")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-Date", valid_591045
  var valid_591046 = header.getOrDefault("X-Amz-Credential")
  valid_591046 = validateParameter(valid_591046, JString, required = false,
                                 default = nil)
  if valid_591046 != nil:
    section.add "X-Amz-Credential", valid_591046
  var valid_591047 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591047 = validateParameter(valid_591047, JString, required = false,
                                 default = nil)
  if valid_591047 != nil:
    section.add "X-Amzn-Client-Token", valid_591047
  var valid_591048 = header.getOrDefault("X-Amz-Security-Token")
  valid_591048 = validateParameter(valid_591048, JString, required = false,
                                 default = nil)
  if valid_591048 != nil:
    section.add "X-Amz-Security-Token", valid_591048
  var valid_591049 = header.getOrDefault("X-Amz-Algorithm")
  valid_591049 = validateParameter(valid_591049, JString, required = false,
                                 default = nil)
  if valid_591049 != nil:
    section.add "X-Amz-Algorithm", valid_591049
  var valid_591050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "X-Amz-SignedHeaders", valid_591050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591052: Call_CreateConnectorDefinition_591040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ## 
  let valid = call_591052.validator(path, query, header, formData, body)
  let scheme = call_591052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591052.url(scheme.get, call_591052.host, call_591052.base,
                         call_591052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591052, url, valid)

proc call*(call_591053: Call_CreateConnectorDefinition_591040; body: JsonNode): Recallable =
  ## createConnectorDefinition
  ## Creates a connector definition. You may provide the initial version of the connector definition now or use ''CreateConnectorDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_591054 = newJObject()
  if body != nil:
    body_591054 = body
  result = call_591053.call(nil, nil, nil, nil, body_591054)

var createConnectorDefinition* = Call_CreateConnectorDefinition_591040(
    name: "createConnectorDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_CreateConnectorDefinition_591041, base: "/",
    url: url_CreateConnectorDefinition_591042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitions_591025 = ref object of OpenApiRestCall_590348
proc url_ListConnectorDefinitions_591027(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConnectorDefinitions_591026(path: JsonNode; query: JsonNode;
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
  var valid_591028 = query.getOrDefault("MaxResults")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "MaxResults", valid_591028
  var valid_591029 = query.getOrDefault("NextToken")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "NextToken", valid_591029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591030 = header.getOrDefault("X-Amz-Signature")
  valid_591030 = validateParameter(valid_591030, JString, required = false,
                                 default = nil)
  if valid_591030 != nil:
    section.add "X-Amz-Signature", valid_591030
  var valid_591031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "X-Amz-Content-Sha256", valid_591031
  var valid_591032 = header.getOrDefault("X-Amz-Date")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "X-Amz-Date", valid_591032
  var valid_591033 = header.getOrDefault("X-Amz-Credential")
  valid_591033 = validateParameter(valid_591033, JString, required = false,
                                 default = nil)
  if valid_591033 != nil:
    section.add "X-Amz-Credential", valid_591033
  var valid_591034 = header.getOrDefault("X-Amz-Security-Token")
  valid_591034 = validateParameter(valid_591034, JString, required = false,
                                 default = nil)
  if valid_591034 != nil:
    section.add "X-Amz-Security-Token", valid_591034
  var valid_591035 = header.getOrDefault("X-Amz-Algorithm")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-Algorithm", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-SignedHeaders", valid_591036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591037: Call_ListConnectorDefinitions_591025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connector definitions.
  ## 
  let valid = call_591037.validator(path, query, header, formData, body)
  let scheme = call_591037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591037.url(scheme.get, call_591037.host, call_591037.base,
                         call_591037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591037, url, valid)

proc call*(call_591038: Call_ListConnectorDefinitions_591025;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConnectorDefinitions
  ## Retrieves a list of connector definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591039 = newJObject()
  add(query_591039, "MaxResults", newJString(MaxResults))
  add(query_591039, "NextToken", newJString(NextToken))
  result = call_591038.call(nil, query_591039, nil, nil, nil)

var listConnectorDefinitions* = Call_ListConnectorDefinitions_591025(
    name: "listConnectorDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors",
    validator: validate_ListConnectorDefinitions_591026, base: "/",
    url: url_ListConnectorDefinitions_591027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnectorDefinitionVersion_591072 = ref object of OpenApiRestCall_590348
proc url_CreateConnectorDefinitionVersion_591074(protocol: Scheme; host: string;
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

proc validate_CreateConnectorDefinitionVersion_591073(path: JsonNode;
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
  var valid_591075 = path.getOrDefault("ConnectorDefinitionId")
  valid_591075 = validateParameter(valid_591075, JString, required = true,
                                 default = nil)
  if valid_591075 != nil:
    section.add "ConnectorDefinitionId", valid_591075
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
  var valid_591076 = header.getOrDefault("X-Amz-Signature")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Signature", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-Content-Sha256", valid_591077
  var valid_591078 = header.getOrDefault("X-Amz-Date")
  valid_591078 = validateParameter(valid_591078, JString, required = false,
                                 default = nil)
  if valid_591078 != nil:
    section.add "X-Amz-Date", valid_591078
  var valid_591079 = header.getOrDefault("X-Amz-Credential")
  valid_591079 = validateParameter(valid_591079, JString, required = false,
                                 default = nil)
  if valid_591079 != nil:
    section.add "X-Amz-Credential", valid_591079
  var valid_591080 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591080 = validateParameter(valid_591080, JString, required = false,
                                 default = nil)
  if valid_591080 != nil:
    section.add "X-Amzn-Client-Token", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Security-Token")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Security-Token", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Algorithm")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Algorithm", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-SignedHeaders", valid_591083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591085: Call_CreateConnectorDefinitionVersion_591072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a connector definition which has already been defined.
  ## 
  let valid = call_591085.validator(path, query, header, formData, body)
  let scheme = call_591085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591085.url(scheme.get, call_591085.host, call_591085.base,
                         call_591085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591085, url, valid)

proc call*(call_591086: Call_CreateConnectorDefinitionVersion_591072;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## createConnectorDefinitionVersion
  ## Creates a version of a connector definition which has already been defined.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_591087 = newJObject()
  var body_591088 = newJObject()
  add(path_591087, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_591088 = body
  result = call_591086.call(path_591087, nil, nil, nil, body_591088)

var createConnectorDefinitionVersion* = Call_CreateConnectorDefinitionVersion_591072(
    name: "createConnectorDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_CreateConnectorDefinitionVersion_591073, base: "/",
    url: url_CreateConnectorDefinitionVersion_591074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConnectorDefinitionVersions_591055 = ref object of OpenApiRestCall_590348
proc url_ListConnectorDefinitionVersions_591057(protocol: Scheme; host: string;
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

proc validate_ListConnectorDefinitionVersions_591056(path: JsonNode;
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
  var valid_591058 = path.getOrDefault("ConnectorDefinitionId")
  valid_591058 = validateParameter(valid_591058, JString, required = true,
                                 default = nil)
  if valid_591058 != nil:
    section.add "ConnectorDefinitionId", valid_591058
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591059 = query.getOrDefault("MaxResults")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "MaxResults", valid_591059
  var valid_591060 = query.getOrDefault("NextToken")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "NextToken", valid_591060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591061 = header.getOrDefault("X-Amz-Signature")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-Signature", valid_591061
  var valid_591062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591062 = validateParameter(valid_591062, JString, required = false,
                                 default = nil)
  if valid_591062 != nil:
    section.add "X-Amz-Content-Sha256", valid_591062
  var valid_591063 = header.getOrDefault("X-Amz-Date")
  valid_591063 = validateParameter(valid_591063, JString, required = false,
                                 default = nil)
  if valid_591063 != nil:
    section.add "X-Amz-Date", valid_591063
  var valid_591064 = header.getOrDefault("X-Amz-Credential")
  valid_591064 = validateParameter(valid_591064, JString, required = false,
                                 default = nil)
  if valid_591064 != nil:
    section.add "X-Amz-Credential", valid_591064
  var valid_591065 = header.getOrDefault("X-Amz-Security-Token")
  valid_591065 = validateParameter(valid_591065, JString, required = false,
                                 default = nil)
  if valid_591065 != nil:
    section.add "X-Amz-Security-Token", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Algorithm")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Algorithm", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-SignedHeaders", valid_591067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591068: Call_ListConnectorDefinitionVersions_591055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a connector definition, which are containers for connectors. Connectors run on the Greengrass core and contain built-in integration with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_591068.validator(path, query, header, formData, body)
  let scheme = call_591068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591068.url(scheme.get, call_591068.host, call_591068.base,
                         call_591068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591068, url, valid)

proc call*(call_591069: Call_ListConnectorDefinitionVersions_591055;
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
  var path_591070 = newJObject()
  var query_591071 = newJObject()
  add(query_591071, "MaxResults", newJString(MaxResults))
  add(query_591071, "NextToken", newJString(NextToken))
  add(path_591070, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_591069.call(path_591070, query_591071, nil, nil, nil)

var listConnectorDefinitionVersions* = Call_ListConnectorDefinitionVersions_591055(
    name: "listConnectorDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions",
    validator: validate_ListConnectorDefinitionVersions_591056, base: "/",
    url: url_ListConnectorDefinitionVersions_591057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinition_591104 = ref object of OpenApiRestCall_590348
proc url_CreateCoreDefinition_591106(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCoreDefinition_591105(path: JsonNode; query: JsonNode;
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
  var valid_591107 = header.getOrDefault("X-Amz-Signature")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "X-Amz-Signature", valid_591107
  var valid_591108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "X-Amz-Content-Sha256", valid_591108
  var valid_591109 = header.getOrDefault("X-Amz-Date")
  valid_591109 = validateParameter(valid_591109, JString, required = false,
                                 default = nil)
  if valid_591109 != nil:
    section.add "X-Amz-Date", valid_591109
  var valid_591110 = header.getOrDefault("X-Amz-Credential")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Credential", valid_591110
  var valid_591111 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amzn-Client-Token", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Security-Token")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Security-Token", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Algorithm")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Algorithm", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-SignedHeaders", valid_591114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591116: Call_CreateCoreDefinition_591104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_591116.validator(path, query, header, formData, body)
  let scheme = call_591116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591116.url(scheme.get, call_591116.host, call_591116.base,
                         call_591116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591116, url, valid)

proc call*(call_591117: Call_CreateCoreDefinition_591104; body: JsonNode): Recallable =
  ## createCoreDefinition
  ## Creates a core definition. You may provide the initial version of the core definition now or use ''CreateCoreDefinitionVersion'' at a later time. Greengrass groups must each contain exactly one Greengrass core.
  ##   body: JObject (required)
  var body_591118 = newJObject()
  if body != nil:
    body_591118 = body
  result = call_591117.call(nil, nil, nil, nil, body_591118)

var createCoreDefinition* = Call_CreateCoreDefinition_591104(
    name: "createCoreDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_CreateCoreDefinition_591105, base: "/",
    url: url_CreateCoreDefinition_591106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitions_591089 = ref object of OpenApiRestCall_590348
proc url_ListCoreDefinitions_591091(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCoreDefinitions_591090(path: JsonNode; query: JsonNode;
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
  var valid_591092 = query.getOrDefault("MaxResults")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "MaxResults", valid_591092
  var valid_591093 = query.getOrDefault("NextToken")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "NextToken", valid_591093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591094 = header.getOrDefault("X-Amz-Signature")
  valid_591094 = validateParameter(valid_591094, JString, required = false,
                                 default = nil)
  if valid_591094 != nil:
    section.add "X-Amz-Signature", valid_591094
  var valid_591095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591095 = validateParameter(valid_591095, JString, required = false,
                                 default = nil)
  if valid_591095 != nil:
    section.add "X-Amz-Content-Sha256", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Date")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Date", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Credential")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Credential", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Security-Token")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Security-Token", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Algorithm")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Algorithm", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-SignedHeaders", valid_591100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591101: Call_ListCoreDefinitions_591089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of core definitions.
  ## 
  let valid = call_591101.validator(path, query, header, formData, body)
  let scheme = call_591101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591101.url(scheme.get, call_591101.host, call_591101.base,
                         call_591101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591101, url, valid)

proc call*(call_591102: Call_ListCoreDefinitions_591089; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listCoreDefinitions
  ## Retrieves a list of core definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591103 = newJObject()
  add(query_591103, "MaxResults", newJString(MaxResults))
  add(query_591103, "NextToken", newJString(NextToken))
  result = call_591102.call(nil, query_591103, nil, nil, nil)

var listCoreDefinitions* = Call_ListCoreDefinitions_591089(
    name: "listCoreDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores",
    validator: validate_ListCoreDefinitions_591090, base: "/",
    url: url_ListCoreDefinitions_591091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCoreDefinitionVersion_591136 = ref object of OpenApiRestCall_590348
proc url_CreateCoreDefinitionVersion_591138(protocol: Scheme; host: string;
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

proc validate_CreateCoreDefinitionVersion_591137(path: JsonNode; query: JsonNode;
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
  var valid_591139 = path.getOrDefault("CoreDefinitionId")
  valid_591139 = validateParameter(valid_591139, JString, required = true,
                                 default = nil)
  if valid_591139 != nil:
    section.add "CoreDefinitionId", valid_591139
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
  var valid_591140 = header.getOrDefault("X-Amz-Signature")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Signature", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Content-Sha256", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Date")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Date", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Credential")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Credential", valid_591143
  var valid_591144 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amzn-Client-Token", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Security-Token")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Security-Token", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Algorithm")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Algorithm", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-SignedHeaders", valid_591147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591149: Call_CreateCoreDefinitionVersion_591136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_CreateCoreDefinitionVersion_591136;
          CoreDefinitionId: string; body: JsonNode): Recallable =
  ## createCoreDefinitionVersion
  ## Creates a version of a core definition that has already been defined. Greengrass groups must each contain exactly one Greengrass core.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_591151 = newJObject()
  var body_591152 = newJObject()
  add(path_591151, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_591152 = body
  result = call_591150.call(path_591151, nil, nil, nil, body_591152)

var createCoreDefinitionVersion* = Call_CreateCoreDefinitionVersion_591136(
    name: "createCoreDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_CreateCoreDefinitionVersion_591137, base: "/",
    url: url_CreateCoreDefinitionVersion_591138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCoreDefinitionVersions_591119 = ref object of OpenApiRestCall_590348
proc url_ListCoreDefinitionVersions_591121(protocol: Scheme; host: string;
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

proc validate_ListCoreDefinitionVersions_591120(path: JsonNode; query: JsonNode;
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
  var valid_591122 = path.getOrDefault("CoreDefinitionId")
  valid_591122 = validateParameter(valid_591122, JString, required = true,
                                 default = nil)
  if valid_591122 != nil:
    section.add "CoreDefinitionId", valid_591122
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591123 = query.getOrDefault("MaxResults")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "MaxResults", valid_591123
  var valid_591124 = query.getOrDefault("NextToken")
  valid_591124 = validateParameter(valid_591124, JString, required = false,
                                 default = nil)
  if valid_591124 != nil:
    section.add "NextToken", valid_591124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591125 = header.getOrDefault("X-Amz-Signature")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "X-Amz-Signature", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Content-Sha256", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Date")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Date", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Credential")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Credential", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Security-Token")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Security-Token", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Algorithm")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Algorithm", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-SignedHeaders", valid_591131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591132: Call_ListCoreDefinitionVersions_591119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a core definition.
  ## 
  let valid = call_591132.validator(path, query, header, formData, body)
  let scheme = call_591132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591132.url(scheme.get, call_591132.host, call_591132.base,
                         call_591132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591132, url, valid)

proc call*(call_591133: Call_ListCoreDefinitionVersions_591119;
          CoreDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCoreDefinitionVersions
  ## Lists the versions of a core definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_591134 = newJObject()
  var query_591135 = newJObject()
  add(query_591135, "MaxResults", newJString(MaxResults))
  add(query_591135, "NextToken", newJString(NextToken))
  add(path_591134, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_591133.call(path_591134, query_591135, nil, nil, nil)

var listCoreDefinitionVersions* = Call_ListCoreDefinitionVersions_591119(
    name: "listCoreDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}/versions",
    validator: validate_ListCoreDefinitionVersions_591120, base: "/",
    url: url_ListCoreDefinitionVersions_591121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_591170 = ref object of OpenApiRestCall_590348
proc url_CreateDeployment_591172(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_591171(path: JsonNode; query: JsonNode;
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
  var valid_591173 = path.getOrDefault("GroupId")
  valid_591173 = validateParameter(valid_591173, JString, required = true,
                                 default = nil)
  if valid_591173 != nil:
    section.add "GroupId", valid_591173
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
  var valid_591174 = header.getOrDefault("X-Amz-Signature")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Signature", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Content-Sha256", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Date")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Date", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Credential")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Credential", valid_591177
  var valid_591178 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amzn-Client-Token", valid_591178
  var valid_591179 = header.getOrDefault("X-Amz-Security-Token")
  valid_591179 = validateParameter(valid_591179, JString, required = false,
                                 default = nil)
  if valid_591179 != nil:
    section.add "X-Amz-Security-Token", valid_591179
  var valid_591180 = header.getOrDefault("X-Amz-Algorithm")
  valid_591180 = validateParameter(valid_591180, JString, required = false,
                                 default = nil)
  if valid_591180 != nil:
    section.add "X-Amz-Algorithm", valid_591180
  var valid_591181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591181 = validateParameter(valid_591181, JString, required = false,
                                 default = nil)
  if valid_591181 != nil:
    section.add "X-Amz-SignedHeaders", valid_591181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591183: Call_CreateDeployment_591170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ## 
  let valid = call_591183.validator(path, query, header, formData, body)
  let scheme = call_591183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591183.url(scheme.get, call_591183.host, call_591183.base,
                         call_591183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591183, url, valid)

proc call*(call_591184: Call_CreateDeployment_591170; GroupId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a deployment. ''CreateDeployment'' requests are idempotent with respect to the ''X-Amzn-Client-Token'' token and the request parameters.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_591185 = newJObject()
  var body_591186 = newJObject()
  add(path_591185, "GroupId", newJString(GroupId))
  if body != nil:
    body_591186 = body
  result = call_591184.call(path_591185, nil, nil, nil, body_591186)

var createDeployment* = Call_CreateDeployment_591170(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_CreateDeployment_591171, base: "/",
    url: url_CreateDeployment_591172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_591153 = ref object of OpenApiRestCall_590348
proc url_ListDeployments_591155(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_591154(path: JsonNode; query: JsonNode;
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
  var valid_591156 = path.getOrDefault("GroupId")
  valid_591156 = validateParameter(valid_591156, JString, required = true,
                                 default = nil)
  if valid_591156 != nil:
    section.add "GroupId", valid_591156
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591157 = query.getOrDefault("MaxResults")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "MaxResults", valid_591157
  var valid_591158 = query.getOrDefault("NextToken")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "NextToken", valid_591158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591159 = header.getOrDefault("X-Amz-Signature")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Signature", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Content-Sha256", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Date")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Date", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-Credential")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-Credential", valid_591162
  var valid_591163 = header.getOrDefault("X-Amz-Security-Token")
  valid_591163 = validateParameter(valid_591163, JString, required = false,
                                 default = nil)
  if valid_591163 != nil:
    section.add "X-Amz-Security-Token", valid_591163
  var valid_591164 = header.getOrDefault("X-Amz-Algorithm")
  valid_591164 = validateParameter(valid_591164, JString, required = false,
                                 default = nil)
  if valid_591164 != nil:
    section.add "X-Amz-Algorithm", valid_591164
  var valid_591165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591165 = validateParameter(valid_591165, JString, required = false,
                                 default = nil)
  if valid_591165 != nil:
    section.add "X-Amz-SignedHeaders", valid_591165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591166: Call_ListDeployments_591153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a history of deployments for the group.
  ## 
  let valid = call_591166.validator(path, query, header, formData, body)
  let scheme = call_591166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591166.url(scheme.get, call_591166.host, call_591166.base,
                         call_591166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591166, url, valid)

proc call*(call_591167: Call_ListDeployments_591153; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeployments
  ## Returns a history of deployments for the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_591168 = newJObject()
  var query_591169 = newJObject()
  add(path_591168, "GroupId", newJString(GroupId))
  add(query_591169, "MaxResults", newJString(MaxResults))
  add(query_591169, "NextToken", newJString(NextToken))
  result = call_591167.call(path_591168, query_591169, nil, nil, nil)

var listDeployments* = Call_ListDeployments_591153(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments",
    validator: validate_ListDeployments_591154, base: "/", url: url_ListDeployments_591155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinition_591202 = ref object of OpenApiRestCall_590348
proc url_CreateDeviceDefinition_591204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeviceDefinition_591203(path: JsonNode; query: JsonNode;
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
  var valid_591205 = header.getOrDefault("X-Amz-Signature")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Signature", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Content-Sha256", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Date")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Date", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Credential")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Credential", valid_591208
  var valid_591209 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amzn-Client-Token", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Security-Token")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Security-Token", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Algorithm")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Algorithm", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-SignedHeaders", valid_591212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591214: Call_CreateDeviceDefinition_591202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ## 
  let valid = call_591214.validator(path, query, header, formData, body)
  let scheme = call_591214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591214.url(scheme.get, call_591214.host, call_591214.base,
                         call_591214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591214, url, valid)

proc call*(call_591215: Call_CreateDeviceDefinition_591202; body: JsonNode): Recallable =
  ## createDeviceDefinition
  ## Creates a device definition. You may provide the initial version of the device definition now or use ''CreateDeviceDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_591216 = newJObject()
  if body != nil:
    body_591216 = body
  result = call_591215.call(nil, nil, nil, nil, body_591216)

var createDeviceDefinition* = Call_CreateDeviceDefinition_591202(
    name: "createDeviceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_CreateDeviceDefinition_591203, base: "/",
    url: url_CreateDeviceDefinition_591204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitions_591187 = ref object of OpenApiRestCall_590348
proc url_ListDeviceDefinitions_591189(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeviceDefinitions_591188(path: JsonNode; query: JsonNode;
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
  var valid_591190 = query.getOrDefault("MaxResults")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "MaxResults", valid_591190
  var valid_591191 = query.getOrDefault("NextToken")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "NextToken", valid_591191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591192 = header.getOrDefault("X-Amz-Signature")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Signature", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-Content-Sha256", valid_591193
  var valid_591194 = header.getOrDefault("X-Amz-Date")
  valid_591194 = validateParameter(valid_591194, JString, required = false,
                                 default = nil)
  if valid_591194 != nil:
    section.add "X-Amz-Date", valid_591194
  var valid_591195 = header.getOrDefault("X-Amz-Credential")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "X-Amz-Credential", valid_591195
  var valid_591196 = header.getOrDefault("X-Amz-Security-Token")
  valid_591196 = validateParameter(valid_591196, JString, required = false,
                                 default = nil)
  if valid_591196 != nil:
    section.add "X-Amz-Security-Token", valid_591196
  var valid_591197 = header.getOrDefault("X-Amz-Algorithm")
  valid_591197 = validateParameter(valid_591197, JString, required = false,
                                 default = nil)
  if valid_591197 != nil:
    section.add "X-Amz-Algorithm", valid_591197
  var valid_591198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591198 = validateParameter(valid_591198, JString, required = false,
                                 default = nil)
  if valid_591198 != nil:
    section.add "X-Amz-SignedHeaders", valid_591198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591199: Call_ListDeviceDefinitions_591187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of device definitions.
  ## 
  let valid = call_591199.validator(path, query, header, formData, body)
  let scheme = call_591199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591199.url(scheme.get, call_591199.host, call_591199.base,
                         call_591199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591199, url, valid)

proc call*(call_591200: Call_ListDeviceDefinitions_591187; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listDeviceDefinitions
  ## Retrieves a list of device definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591201 = newJObject()
  add(query_591201, "MaxResults", newJString(MaxResults))
  add(query_591201, "NextToken", newJString(NextToken))
  result = call_591200.call(nil, query_591201, nil, nil, nil)

var listDeviceDefinitions* = Call_ListDeviceDefinitions_591187(
    name: "listDeviceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices",
    validator: validate_ListDeviceDefinitions_591188, base: "/",
    url: url_ListDeviceDefinitions_591189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeviceDefinitionVersion_591234 = ref object of OpenApiRestCall_590348
proc url_CreateDeviceDefinitionVersion_591236(protocol: Scheme; host: string;
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

proc validate_CreateDeviceDefinitionVersion_591235(path: JsonNode; query: JsonNode;
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
  var valid_591237 = path.getOrDefault("DeviceDefinitionId")
  valid_591237 = validateParameter(valid_591237, JString, required = true,
                                 default = nil)
  if valid_591237 != nil:
    section.add "DeviceDefinitionId", valid_591237
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
  var valid_591238 = header.getOrDefault("X-Amz-Signature")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Signature", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Content-Sha256", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Date")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Date", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Credential")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Credential", valid_591241
  var valid_591242 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amzn-Client-Token", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Security-Token")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Security-Token", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Algorithm")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Algorithm", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-SignedHeaders", valid_591245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591247: Call_CreateDeviceDefinitionVersion_591234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a device definition that has already been defined.
  ## 
  let valid = call_591247.validator(path, query, header, formData, body)
  let scheme = call_591247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591247.url(scheme.get, call_591247.host, call_591247.base,
                         call_591247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591247, url, valid)

proc call*(call_591248: Call_CreateDeviceDefinitionVersion_591234;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## createDeviceDefinitionVersion
  ## Creates a version of a device definition that has already been defined.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_591249 = newJObject()
  var body_591250 = newJObject()
  add(path_591249, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_591250 = body
  result = call_591248.call(path_591249, nil, nil, nil, body_591250)

var createDeviceDefinitionVersion* = Call_CreateDeviceDefinitionVersion_591234(
    name: "createDeviceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_CreateDeviceDefinitionVersion_591235, base: "/",
    url: url_CreateDeviceDefinitionVersion_591236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeviceDefinitionVersions_591217 = ref object of OpenApiRestCall_590348
proc url_ListDeviceDefinitionVersions_591219(protocol: Scheme; host: string;
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

proc validate_ListDeviceDefinitionVersions_591218(path: JsonNode; query: JsonNode;
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
  var valid_591220 = path.getOrDefault("DeviceDefinitionId")
  valid_591220 = validateParameter(valid_591220, JString, required = true,
                                 default = nil)
  if valid_591220 != nil:
    section.add "DeviceDefinitionId", valid_591220
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591221 = query.getOrDefault("MaxResults")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "MaxResults", valid_591221
  var valid_591222 = query.getOrDefault("NextToken")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "NextToken", valid_591222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591223 = header.getOrDefault("X-Amz-Signature")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Signature", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Content-Sha256", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-Date")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-Date", valid_591225
  var valid_591226 = header.getOrDefault("X-Amz-Credential")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "X-Amz-Credential", valid_591226
  var valid_591227 = header.getOrDefault("X-Amz-Security-Token")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Security-Token", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Algorithm")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Algorithm", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-SignedHeaders", valid_591229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591230: Call_ListDeviceDefinitionVersions_591217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a device definition.
  ## 
  let valid = call_591230.validator(path, query, header, formData, body)
  let scheme = call_591230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591230.url(scheme.get, call_591230.host, call_591230.base,
                         call_591230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591230, url, valid)

proc call*(call_591231: Call_ListDeviceDefinitionVersions_591217;
          DeviceDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDeviceDefinitionVersions
  ## Lists the versions of a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_591232 = newJObject()
  var query_591233 = newJObject()
  add(path_591232, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_591233, "MaxResults", newJString(MaxResults))
  add(query_591233, "NextToken", newJString(NextToken))
  result = call_591231.call(path_591232, query_591233, nil, nil, nil)

var listDeviceDefinitionVersions* = Call_ListDeviceDefinitionVersions_591217(
    name: "listDeviceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions",
    validator: validate_ListDeviceDefinitionVersions_591218, base: "/",
    url: url_ListDeviceDefinitionVersions_591219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinition_591266 = ref object of OpenApiRestCall_590348
proc url_CreateFunctionDefinition_591268(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFunctionDefinition_591267(path: JsonNode; query: JsonNode;
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
  var valid_591269 = header.getOrDefault("X-Amz-Signature")
  valid_591269 = validateParameter(valid_591269, JString, required = false,
                                 default = nil)
  if valid_591269 != nil:
    section.add "X-Amz-Signature", valid_591269
  var valid_591270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591270 = validateParameter(valid_591270, JString, required = false,
                                 default = nil)
  if valid_591270 != nil:
    section.add "X-Amz-Content-Sha256", valid_591270
  var valid_591271 = header.getOrDefault("X-Amz-Date")
  valid_591271 = validateParameter(valid_591271, JString, required = false,
                                 default = nil)
  if valid_591271 != nil:
    section.add "X-Amz-Date", valid_591271
  var valid_591272 = header.getOrDefault("X-Amz-Credential")
  valid_591272 = validateParameter(valid_591272, JString, required = false,
                                 default = nil)
  if valid_591272 != nil:
    section.add "X-Amz-Credential", valid_591272
  var valid_591273 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amzn-Client-Token", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-Security-Token")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Security-Token", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Algorithm")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Algorithm", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-SignedHeaders", valid_591276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591278: Call_CreateFunctionDefinition_591266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ## 
  let valid = call_591278.validator(path, query, header, formData, body)
  let scheme = call_591278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591278.url(scheme.get, call_591278.host, call_591278.base,
                         call_591278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591278, url, valid)

proc call*(call_591279: Call_CreateFunctionDefinition_591266; body: JsonNode): Recallable =
  ## createFunctionDefinition
  ## Creates a Lambda function definition which contains a list of Lambda functions and their configurations to be used in a group. You can create an initial version of the definition by providing a list of Lambda functions and their configurations now, or use ''CreateFunctionDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_591280 = newJObject()
  if body != nil:
    body_591280 = body
  result = call_591279.call(nil, nil, nil, nil, body_591280)

var createFunctionDefinition* = Call_CreateFunctionDefinition_591266(
    name: "createFunctionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_CreateFunctionDefinition_591267, base: "/",
    url: url_CreateFunctionDefinition_591268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitions_591251 = ref object of OpenApiRestCall_590348
proc url_ListFunctionDefinitions_591253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctionDefinitions_591252(path: JsonNode; query: JsonNode;
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
  var valid_591254 = query.getOrDefault("MaxResults")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "MaxResults", valid_591254
  var valid_591255 = query.getOrDefault("NextToken")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "NextToken", valid_591255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591256 = header.getOrDefault("X-Amz-Signature")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Signature", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Content-Sha256", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Date")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Date", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Credential")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Credential", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Security-Token")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Security-Token", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Algorithm")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Algorithm", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-SignedHeaders", valid_591262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591263: Call_ListFunctionDefinitions_591251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of Lambda function definitions.
  ## 
  let valid = call_591263.validator(path, query, header, formData, body)
  let scheme = call_591263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591263.url(scheme.get, call_591263.host, call_591263.base,
                         call_591263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591263, url, valid)

proc call*(call_591264: Call_ListFunctionDefinitions_591251;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFunctionDefinitions
  ## Retrieves a list of Lambda function definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591265 = newJObject()
  add(query_591265, "MaxResults", newJString(MaxResults))
  add(query_591265, "NextToken", newJString(NextToken))
  result = call_591264.call(nil, query_591265, nil, nil, nil)

var listFunctionDefinitions* = Call_ListFunctionDefinitions_591251(
    name: "listFunctionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions",
    validator: validate_ListFunctionDefinitions_591252, base: "/",
    url: url_ListFunctionDefinitions_591253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunctionDefinitionVersion_591298 = ref object of OpenApiRestCall_590348
proc url_CreateFunctionDefinitionVersion_591300(protocol: Scheme; host: string;
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

proc validate_CreateFunctionDefinitionVersion_591299(path: JsonNode;
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
  var valid_591301 = path.getOrDefault("FunctionDefinitionId")
  valid_591301 = validateParameter(valid_591301, JString, required = true,
                                 default = nil)
  if valid_591301 != nil:
    section.add "FunctionDefinitionId", valid_591301
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
  var valid_591302 = header.getOrDefault("X-Amz-Signature")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-Signature", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Content-Sha256", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Date")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Date", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Credential")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Credential", valid_591305
  var valid_591306 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amzn-Client-Token", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Security-Token")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Security-Token", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Algorithm")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Algorithm", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-SignedHeaders", valid_591309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591311: Call_CreateFunctionDefinitionVersion_591298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a Lambda function definition that has already been defined.
  ## 
  let valid = call_591311.validator(path, query, header, formData, body)
  let scheme = call_591311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591311.url(scheme.get, call_591311.host, call_591311.base,
                         call_591311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591311, url, valid)

proc call*(call_591312: Call_CreateFunctionDefinitionVersion_591298;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## createFunctionDefinitionVersion
  ## Creates a version of a Lambda function definition that has already been defined.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_591313 = newJObject()
  var body_591314 = newJObject()
  add(path_591313, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_591314 = body
  result = call_591312.call(path_591313, nil, nil, nil, body_591314)

var createFunctionDefinitionVersion* = Call_CreateFunctionDefinitionVersion_591298(
    name: "createFunctionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_CreateFunctionDefinitionVersion_591299, base: "/",
    url: url_CreateFunctionDefinitionVersion_591300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionDefinitionVersions_591281 = ref object of OpenApiRestCall_590348
proc url_ListFunctionDefinitionVersions_591283(protocol: Scheme; host: string;
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

proc validate_ListFunctionDefinitionVersions_591282(path: JsonNode;
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
  var valid_591284 = path.getOrDefault("FunctionDefinitionId")
  valid_591284 = validateParameter(valid_591284, JString, required = true,
                                 default = nil)
  if valid_591284 != nil:
    section.add "FunctionDefinitionId", valid_591284
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591285 = query.getOrDefault("MaxResults")
  valid_591285 = validateParameter(valid_591285, JString, required = false,
                                 default = nil)
  if valid_591285 != nil:
    section.add "MaxResults", valid_591285
  var valid_591286 = query.getOrDefault("NextToken")
  valid_591286 = validateParameter(valid_591286, JString, required = false,
                                 default = nil)
  if valid_591286 != nil:
    section.add "NextToken", valid_591286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591287 = header.getOrDefault("X-Amz-Signature")
  valid_591287 = validateParameter(valid_591287, JString, required = false,
                                 default = nil)
  if valid_591287 != nil:
    section.add "X-Amz-Signature", valid_591287
  var valid_591288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Content-Sha256", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Date")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Date", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Credential")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Credential", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Security-Token")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Security-Token", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Algorithm")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Algorithm", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-SignedHeaders", valid_591293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591294: Call_ListFunctionDefinitionVersions_591281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a Lambda function definition.
  ## 
  let valid = call_591294.validator(path, query, header, formData, body)
  let scheme = call_591294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591294.url(scheme.get, call_591294.host, call_591294.base,
                         call_591294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591294, url, valid)

proc call*(call_591295: Call_ListFunctionDefinitionVersions_591281;
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
  var path_591296 = newJObject()
  var query_591297 = newJObject()
  add(query_591297, "MaxResults", newJString(MaxResults))
  add(query_591297, "NextToken", newJString(NextToken))
  add(path_591296, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_591295.call(path_591296, query_591297, nil, nil, nil)

var listFunctionDefinitionVersions* = Call_ListFunctionDefinitionVersions_591281(
    name: "listFunctionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions",
    validator: validate_ListFunctionDefinitionVersions_591282, base: "/",
    url: url_ListFunctionDefinitionVersions_591283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_591330 = ref object of OpenApiRestCall_590348
proc url_CreateGroup_591332(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGroup_591331(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591333 = header.getOrDefault("X-Amz-Signature")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Signature", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Content-Sha256", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-Date")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-Date", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Credential")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Credential", valid_591336
  var valid_591337 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amzn-Client-Token", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Security-Token")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Security-Token", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Algorithm")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Algorithm", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-SignedHeaders", valid_591340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591342: Call_CreateGroup_591330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ## 
  let valid = call_591342.validator(path, query, header, formData, body)
  let scheme = call_591342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591342.url(scheme.get, call_591342.host, call_591342.base,
                         call_591342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591342, url, valid)

proc call*(call_591343: Call_CreateGroup_591330; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group. You may provide the initial version of the group or use ''CreateGroupVersion'' at a later time. Tip: You can use the ''gg_group_setup'' package (https://github.com/awslabs/aws-greengrass-group-setup) as a library or command-line application to create and deploy Greengrass groups.
  ##   body: JObject (required)
  var body_591344 = newJObject()
  if body != nil:
    body_591344 = body
  result = call_591343.call(nil, nil, nil, nil, body_591344)

var createGroup* = Call_CreateGroup_591330(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups",
                                        validator: validate_CreateGroup_591331,
                                        base: "/", url: url_CreateGroup_591332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_591315 = ref object of OpenApiRestCall_590348
proc url_ListGroups_591317(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGroups_591316(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591318 = query.getOrDefault("MaxResults")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "MaxResults", valid_591318
  var valid_591319 = query.getOrDefault("NextToken")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "NextToken", valid_591319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591320 = header.getOrDefault("X-Amz-Signature")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-Signature", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Content-Sha256", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Date")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Date", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Credential")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Credential", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Security-Token")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Security-Token", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Algorithm")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Algorithm", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-SignedHeaders", valid_591326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591327: Call_ListGroups_591315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of groups.
  ## 
  let valid = call_591327.validator(path, query, header, formData, body)
  let scheme = call_591327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591327.url(scheme.get, call_591327.host, call_591327.base,
                         call_591327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591327, url, valid)

proc call*(call_591328: Call_ListGroups_591315; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listGroups
  ## Retrieves a list of groups.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591329 = newJObject()
  add(query_591329, "MaxResults", newJString(MaxResults))
  add(query_591329, "NextToken", newJString(NextToken))
  result = call_591328.call(nil, query_591329, nil, nil, nil)

var listGroups* = Call_ListGroups_591315(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "greengrass.amazonaws.com",
                                      route: "/greengrass/groups",
                                      validator: validate_ListGroups_591316,
                                      base: "/", url: url_ListGroups_591317,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupCertificateAuthority_591359 = ref object of OpenApiRestCall_590348
proc url_CreateGroupCertificateAuthority_591361(protocol: Scheme; host: string;
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

proc validate_CreateGroupCertificateAuthority_591360(path: JsonNode;
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
  var valid_591362 = path.getOrDefault("GroupId")
  valid_591362 = validateParameter(valid_591362, JString, required = true,
                                 default = nil)
  if valid_591362 != nil:
    section.add "GroupId", valid_591362
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
  var valid_591363 = header.getOrDefault("X-Amz-Signature")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-Signature", valid_591363
  var valid_591364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Content-Sha256", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-Date")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-Date", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Credential")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Credential", valid_591366
  var valid_591367 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amzn-Client-Token", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Security-Token")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Security-Token", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Algorithm")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Algorithm", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-SignedHeaders", valid_591370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591371: Call_CreateGroupCertificateAuthority_591359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ## 
  let valid = call_591371.validator(path, query, header, formData, body)
  let scheme = call_591371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591371.url(scheme.get, call_591371.host, call_591371.base,
                         call_591371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591371, url, valid)

proc call*(call_591372: Call_CreateGroupCertificateAuthority_591359;
          GroupId: string): Recallable =
  ## createGroupCertificateAuthority
  ## Creates a CA for the group. If a CA already exists, it will rotate the existing CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_591373 = newJObject()
  add(path_591373, "GroupId", newJString(GroupId))
  result = call_591372.call(path_591373, nil, nil, nil, nil)

var createGroupCertificateAuthority* = Call_CreateGroupCertificateAuthority_591359(
    name: "createGroupCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_CreateGroupCertificateAuthority_591360, base: "/",
    url: url_CreateGroupCertificateAuthority_591361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupCertificateAuthorities_591345 = ref object of OpenApiRestCall_590348
proc url_ListGroupCertificateAuthorities_591347(protocol: Scheme; host: string;
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

proc validate_ListGroupCertificateAuthorities_591346(path: JsonNode;
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
  var valid_591348 = path.getOrDefault("GroupId")
  valid_591348 = validateParameter(valid_591348, JString, required = true,
                                 default = nil)
  if valid_591348 != nil:
    section.add "GroupId", valid_591348
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
  var valid_591349 = header.getOrDefault("X-Amz-Signature")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Signature", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-Content-Sha256", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Date")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Date", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Credential")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Credential", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Security-Token")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Security-Token", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-Algorithm")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-Algorithm", valid_591354
  var valid_591355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-SignedHeaders", valid_591355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591356: Call_ListGroupCertificateAuthorities_591345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current CAs for a group.
  ## 
  let valid = call_591356.validator(path, query, header, formData, body)
  let scheme = call_591356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591356.url(scheme.get, call_591356.host, call_591356.base,
                         call_591356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591356, url, valid)

proc call*(call_591357: Call_ListGroupCertificateAuthorities_591345;
          GroupId: string): Recallable =
  ## listGroupCertificateAuthorities
  ## Retrieves the current CAs for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_591358 = newJObject()
  add(path_591358, "GroupId", newJString(GroupId))
  result = call_591357.call(path_591358, nil, nil, nil, nil)

var listGroupCertificateAuthorities* = Call_ListGroupCertificateAuthorities_591345(
    name: "listGroupCertificateAuthorities", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/certificateauthorities",
    validator: validate_ListGroupCertificateAuthorities_591346, base: "/",
    url: url_ListGroupCertificateAuthorities_591347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupVersion_591391 = ref object of OpenApiRestCall_590348
proc url_CreateGroupVersion_591393(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupVersion_591392(path: JsonNode; query: JsonNode;
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
  var valid_591394 = path.getOrDefault("GroupId")
  valid_591394 = validateParameter(valid_591394, JString, required = true,
                                 default = nil)
  if valid_591394 != nil:
    section.add "GroupId", valid_591394
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
  var valid_591395 = header.getOrDefault("X-Amz-Signature")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-Signature", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Content-Sha256", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Date")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Date", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Credential")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Credential", valid_591398
  var valid_591399 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amzn-Client-Token", valid_591399
  var valid_591400 = header.getOrDefault("X-Amz-Security-Token")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "X-Amz-Security-Token", valid_591400
  var valid_591401 = header.getOrDefault("X-Amz-Algorithm")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Algorithm", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-SignedHeaders", valid_591402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591404: Call_CreateGroupVersion_591391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a group which has already been defined.
  ## 
  let valid = call_591404.validator(path, query, header, formData, body)
  let scheme = call_591404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591404.url(scheme.get, call_591404.host, call_591404.base,
                         call_591404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591404, url, valid)

proc call*(call_591405: Call_CreateGroupVersion_591391; GroupId: string;
          body: JsonNode): Recallable =
  ## createGroupVersion
  ## Creates a version of a group which has already been defined.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_591406 = newJObject()
  var body_591407 = newJObject()
  add(path_591406, "GroupId", newJString(GroupId))
  if body != nil:
    body_591407 = body
  result = call_591405.call(path_591406, nil, nil, nil, body_591407)

var createGroupVersion* = Call_CreateGroupVersion_591391(
    name: "createGroupVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_CreateGroupVersion_591392, base: "/",
    url: url_CreateGroupVersion_591393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupVersions_591374 = ref object of OpenApiRestCall_590348
proc url_ListGroupVersions_591376(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupVersions_591375(path: JsonNode; query: JsonNode;
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
  var valid_591377 = path.getOrDefault("GroupId")
  valid_591377 = validateParameter(valid_591377, JString, required = true,
                                 default = nil)
  if valid_591377 != nil:
    section.add "GroupId", valid_591377
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591378 = query.getOrDefault("MaxResults")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "MaxResults", valid_591378
  var valid_591379 = query.getOrDefault("NextToken")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "NextToken", valid_591379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591380 = header.getOrDefault("X-Amz-Signature")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = nil)
  if valid_591380 != nil:
    section.add "X-Amz-Signature", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Content-Sha256", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Date")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Date", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-Credential")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-Credential", valid_591383
  var valid_591384 = header.getOrDefault("X-Amz-Security-Token")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Security-Token", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Algorithm")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Algorithm", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-SignedHeaders", valid_591386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591387: Call_ListGroupVersions_591374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a group.
  ## 
  let valid = call_591387.validator(path, query, header, formData, body)
  let scheme = call_591387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591387.url(scheme.get, call_591387.host, call_591387.base,
                         call_591387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591387, url, valid)

proc call*(call_591388: Call_ListGroupVersions_591374; GroupId: string;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupVersions
  ## Lists the versions of a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var path_591389 = newJObject()
  var query_591390 = newJObject()
  add(path_591389, "GroupId", newJString(GroupId))
  add(query_591390, "MaxResults", newJString(MaxResults))
  add(query_591390, "NextToken", newJString(NextToken))
  result = call_591388.call(path_591389, query_591390, nil, nil, nil)

var listGroupVersions* = Call_ListGroupVersions_591374(name: "listGroupVersions",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions",
    validator: validate_ListGroupVersions_591375, base: "/",
    url: url_ListGroupVersions_591376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinition_591423 = ref object of OpenApiRestCall_590348
proc url_CreateLoggerDefinition_591425(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLoggerDefinition_591424(path: JsonNode; query: JsonNode;
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
  var valid_591426 = header.getOrDefault("X-Amz-Signature")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-Signature", valid_591426
  var valid_591427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591427 = validateParameter(valid_591427, JString, required = false,
                                 default = nil)
  if valid_591427 != nil:
    section.add "X-Amz-Content-Sha256", valid_591427
  var valid_591428 = header.getOrDefault("X-Amz-Date")
  valid_591428 = validateParameter(valid_591428, JString, required = false,
                                 default = nil)
  if valid_591428 != nil:
    section.add "X-Amz-Date", valid_591428
  var valid_591429 = header.getOrDefault("X-Amz-Credential")
  valid_591429 = validateParameter(valid_591429, JString, required = false,
                                 default = nil)
  if valid_591429 != nil:
    section.add "X-Amz-Credential", valid_591429
  var valid_591430 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591430 = validateParameter(valid_591430, JString, required = false,
                                 default = nil)
  if valid_591430 != nil:
    section.add "X-Amzn-Client-Token", valid_591430
  var valid_591431 = header.getOrDefault("X-Amz-Security-Token")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Security-Token", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-Algorithm")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-Algorithm", valid_591432
  var valid_591433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591433 = validateParameter(valid_591433, JString, required = false,
                                 default = nil)
  if valid_591433 != nil:
    section.add "X-Amz-SignedHeaders", valid_591433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591435: Call_CreateLoggerDefinition_591423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ## 
  let valid = call_591435.validator(path, query, header, formData, body)
  let scheme = call_591435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591435.url(scheme.get, call_591435.host, call_591435.base,
                         call_591435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591435, url, valid)

proc call*(call_591436: Call_CreateLoggerDefinition_591423; body: JsonNode): Recallable =
  ## createLoggerDefinition
  ## Creates a logger definition. You may provide the initial version of the logger definition now or use ''CreateLoggerDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_591437 = newJObject()
  if body != nil:
    body_591437 = body
  result = call_591436.call(nil, nil, nil, nil, body_591437)

var createLoggerDefinition* = Call_CreateLoggerDefinition_591423(
    name: "createLoggerDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_CreateLoggerDefinition_591424, base: "/",
    url: url_CreateLoggerDefinition_591425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitions_591408 = ref object of OpenApiRestCall_590348
proc url_ListLoggerDefinitions_591410(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLoggerDefinitions_591409(path: JsonNode; query: JsonNode;
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
  var valid_591411 = query.getOrDefault("MaxResults")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "MaxResults", valid_591411
  var valid_591412 = query.getOrDefault("NextToken")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "NextToken", valid_591412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591413 = header.getOrDefault("X-Amz-Signature")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = nil)
  if valid_591413 != nil:
    section.add "X-Amz-Signature", valid_591413
  var valid_591414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591414 = validateParameter(valid_591414, JString, required = false,
                                 default = nil)
  if valid_591414 != nil:
    section.add "X-Amz-Content-Sha256", valid_591414
  var valid_591415 = header.getOrDefault("X-Amz-Date")
  valid_591415 = validateParameter(valid_591415, JString, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "X-Amz-Date", valid_591415
  var valid_591416 = header.getOrDefault("X-Amz-Credential")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Credential", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-Security-Token")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-Security-Token", valid_591417
  var valid_591418 = header.getOrDefault("X-Amz-Algorithm")
  valid_591418 = validateParameter(valid_591418, JString, required = false,
                                 default = nil)
  if valid_591418 != nil:
    section.add "X-Amz-Algorithm", valid_591418
  var valid_591419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "X-Amz-SignedHeaders", valid_591419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591420: Call_ListLoggerDefinitions_591408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of logger definitions.
  ## 
  let valid = call_591420.validator(path, query, header, formData, body)
  let scheme = call_591420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591420.url(scheme.get, call_591420.host, call_591420.base,
                         call_591420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591420, url, valid)

proc call*(call_591421: Call_ListLoggerDefinitions_591408; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listLoggerDefinitions
  ## Retrieves a list of logger definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591422 = newJObject()
  add(query_591422, "MaxResults", newJString(MaxResults))
  add(query_591422, "NextToken", newJString(NextToken))
  result = call_591421.call(nil, query_591422, nil, nil, nil)

var listLoggerDefinitions* = Call_ListLoggerDefinitions_591408(
    name: "listLoggerDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers",
    validator: validate_ListLoggerDefinitions_591409, base: "/",
    url: url_ListLoggerDefinitions_591410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoggerDefinitionVersion_591455 = ref object of OpenApiRestCall_590348
proc url_CreateLoggerDefinitionVersion_591457(protocol: Scheme; host: string;
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

proc validate_CreateLoggerDefinitionVersion_591456(path: JsonNode; query: JsonNode;
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
  var valid_591458 = path.getOrDefault("LoggerDefinitionId")
  valid_591458 = validateParameter(valid_591458, JString, required = true,
                                 default = nil)
  if valid_591458 != nil:
    section.add "LoggerDefinitionId", valid_591458
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
  var valid_591459 = header.getOrDefault("X-Amz-Signature")
  valid_591459 = validateParameter(valid_591459, JString, required = false,
                                 default = nil)
  if valid_591459 != nil:
    section.add "X-Amz-Signature", valid_591459
  var valid_591460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Content-Sha256", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Date")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Date", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-Credential")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-Credential", valid_591462
  var valid_591463 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amzn-Client-Token", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-Security-Token")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Security-Token", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Algorithm")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Algorithm", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-SignedHeaders", valid_591466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591468: Call_CreateLoggerDefinitionVersion_591455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a logger definition that has already been defined.
  ## 
  let valid = call_591468.validator(path, query, header, formData, body)
  let scheme = call_591468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591468.url(scheme.get, call_591468.host, call_591468.base,
                         call_591468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591468, url, valid)

proc call*(call_591469: Call_CreateLoggerDefinitionVersion_591455;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## createLoggerDefinitionVersion
  ## Creates a version of a logger definition that has already been defined.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_591470 = newJObject()
  var body_591471 = newJObject()
  add(path_591470, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_591471 = body
  result = call_591469.call(path_591470, nil, nil, nil, body_591471)

var createLoggerDefinitionVersion* = Call_CreateLoggerDefinitionVersion_591455(
    name: "createLoggerDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_CreateLoggerDefinitionVersion_591456, base: "/",
    url: url_CreateLoggerDefinitionVersion_591457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggerDefinitionVersions_591438 = ref object of OpenApiRestCall_590348
proc url_ListLoggerDefinitionVersions_591440(protocol: Scheme; host: string;
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

proc validate_ListLoggerDefinitionVersions_591439(path: JsonNode; query: JsonNode;
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
  var valid_591441 = path.getOrDefault("LoggerDefinitionId")
  valid_591441 = validateParameter(valid_591441, JString, required = true,
                                 default = nil)
  if valid_591441 != nil:
    section.add "LoggerDefinitionId", valid_591441
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591442 = query.getOrDefault("MaxResults")
  valid_591442 = validateParameter(valid_591442, JString, required = false,
                                 default = nil)
  if valid_591442 != nil:
    section.add "MaxResults", valid_591442
  var valid_591443 = query.getOrDefault("NextToken")
  valid_591443 = validateParameter(valid_591443, JString, required = false,
                                 default = nil)
  if valid_591443 != nil:
    section.add "NextToken", valid_591443
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591444 = header.getOrDefault("X-Amz-Signature")
  valid_591444 = validateParameter(valid_591444, JString, required = false,
                                 default = nil)
  if valid_591444 != nil:
    section.add "X-Amz-Signature", valid_591444
  var valid_591445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-Content-Sha256", valid_591445
  var valid_591446 = header.getOrDefault("X-Amz-Date")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Date", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-Credential")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-Credential", valid_591447
  var valid_591448 = header.getOrDefault("X-Amz-Security-Token")
  valid_591448 = validateParameter(valid_591448, JString, required = false,
                                 default = nil)
  if valid_591448 != nil:
    section.add "X-Amz-Security-Token", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Algorithm")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Algorithm", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-SignedHeaders", valid_591450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591451: Call_ListLoggerDefinitionVersions_591438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a logger definition.
  ## 
  let valid = call_591451.validator(path, query, header, formData, body)
  let scheme = call_591451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591451.url(scheme.get, call_591451.host, call_591451.base,
                         call_591451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591451, url, valid)

proc call*(call_591452: Call_ListLoggerDefinitionVersions_591438;
          LoggerDefinitionId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLoggerDefinitionVersions
  ## Lists the versions of a logger definition.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_591453 = newJObject()
  var query_591454 = newJObject()
  add(query_591454, "MaxResults", newJString(MaxResults))
  add(query_591454, "NextToken", newJString(NextToken))
  add(path_591453, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_591452.call(path_591453, query_591454, nil, nil, nil)

var listLoggerDefinitionVersions* = Call_ListLoggerDefinitionVersions_591438(
    name: "listLoggerDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions",
    validator: validate_ListLoggerDefinitionVersions_591439, base: "/",
    url: url_ListLoggerDefinitionVersions_591440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinition_591487 = ref object of OpenApiRestCall_590348
proc url_CreateResourceDefinition_591489(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceDefinition_591488(path: JsonNode; query: JsonNode;
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
  var valid_591490 = header.getOrDefault("X-Amz-Signature")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "X-Amz-Signature", valid_591490
  var valid_591491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "X-Amz-Content-Sha256", valid_591491
  var valid_591492 = header.getOrDefault("X-Amz-Date")
  valid_591492 = validateParameter(valid_591492, JString, required = false,
                                 default = nil)
  if valid_591492 != nil:
    section.add "X-Amz-Date", valid_591492
  var valid_591493 = header.getOrDefault("X-Amz-Credential")
  valid_591493 = validateParameter(valid_591493, JString, required = false,
                                 default = nil)
  if valid_591493 != nil:
    section.add "X-Amz-Credential", valid_591493
  var valid_591494 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591494 = validateParameter(valid_591494, JString, required = false,
                                 default = nil)
  if valid_591494 != nil:
    section.add "X-Amzn-Client-Token", valid_591494
  var valid_591495 = header.getOrDefault("X-Amz-Security-Token")
  valid_591495 = validateParameter(valid_591495, JString, required = false,
                                 default = nil)
  if valid_591495 != nil:
    section.add "X-Amz-Security-Token", valid_591495
  var valid_591496 = header.getOrDefault("X-Amz-Algorithm")
  valid_591496 = validateParameter(valid_591496, JString, required = false,
                                 default = nil)
  if valid_591496 != nil:
    section.add "X-Amz-Algorithm", valid_591496
  var valid_591497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591497 = validateParameter(valid_591497, JString, required = false,
                                 default = nil)
  if valid_591497 != nil:
    section.add "X-Amz-SignedHeaders", valid_591497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591499: Call_CreateResourceDefinition_591487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ## 
  let valid = call_591499.validator(path, query, header, formData, body)
  let scheme = call_591499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591499.url(scheme.get, call_591499.host, call_591499.base,
                         call_591499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591499, url, valid)

proc call*(call_591500: Call_CreateResourceDefinition_591487; body: JsonNode): Recallable =
  ## createResourceDefinition
  ## Creates a resource definition which contains a list of resources to be used in a group. You can create an initial version of the definition by providing a list of resources now, or use ''CreateResourceDefinitionVersion'' later.
  ##   body: JObject (required)
  var body_591501 = newJObject()
  if body != nil:
    body_591501 = body
  result = call_591500.call(nil, nil, nil, nil, body_591501)

var createResourceDefinition* = Call_CreateResourceDefinition_591487(
    name: "createResourceDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_CreateResourceDefinition_591488, base: "/",
    url: url_CreateResourceDefinition_591489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitions_591472 = ref object of OpenApiRestCall_590348
proc url_ListResourceDefinitions_591474(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceDefinitions_591473(path: JsonNode; query: JsonNode;
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
  var valid_591475 = query.getOrDefault("MaxResults")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "MaxResults", valid_591475
  var valid_591476 = query.getOrDefault("NextToken")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "NextToken", valid_591476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591477 = header.getOrDefault("X-Amz-Signature")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-Signature", valid_591477
  var valid_591478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591478 = validateParameter(valid_591478, JString, required = false,
                                 default = nil)
  if valid_591478 != nil:
    section.add "X-Amz-Content-Sha256", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Date")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Date", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Credential")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Credential", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-Security-Token")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-Security-Token", valid_591481
  var valid_591482 = header.getOrDefault("X-Amz-Algorithm")
  valid_591482 = validateParameter(valid_591482, JString, required = false,
                                 default = nil)
  if valid_591482 != nil:
    section.add "X-Amz-Algorithm", valid_591482
  var valid_591483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591483 = validateParameter(valid_591483, JString, required = false,
                                 default = nil)
  if valid_591483 != nil:
    section.add "X-Amz-SignedHeaders", valid_591483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591484: Call_ListResourceDefinitions_591472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource definitions.
  ## 
  let valid = call_591484.validator(path, query, header, formData, body)
  let scheme = call_591484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591484.url(scheme.get, call_591484.host, call_591484.base,
                         call_591484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591484, url, valid)

proc call*(call_591485: Call_ListResourceDefinitions_591472;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDefinitions
  ## Retrieves a list of resource definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591486 = newJObject()
  add(query_591486, "MaxResults", newJString(MaxResults))
  add(query_591486, "NextToken", newJString(NextToken))
  result = call_591485.call(nil, query_591486, nil, nil, nil)

var listResourceDefinitions* = Call_ListResourceDefinitions_591472(
    name: "listResourceDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources",
    validator: validate_ListResourceDefinitions_591473, base: "/",
    url: url_ListResourceDefinitions_591474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDefinitionVersion_591519 = ref object of OpenApiRestCall_590348
proc url_CreateResourceDefinitionVersion_591521(protocol: Scheme; host: string;
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

proc validate_CreateResourceDefinitionVersion_591520(path: JsonNode;
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
  var valid_591522 = path.getOrDefault("ResourceDefinitionId")
  valid_591522 = validateParameter(valid_591522, JString, required = true,
                                 default = nil)
  if valid_591522 != nil:
    section.add "ResourceDefinitionId", valid_591522
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
  var valid_591523 = header.getOrDefault("X-Amz-Signature")
  valid_591523 = validateParameter(valid_591523, JString, required = false,
                                 default = nil)
  if valid_591523 != nil:
    section.add "X-Amz-Signature", valid_591523
  var valid_591524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591524 = validateParameter(valid_591524, JString, required = false,
                                 default = nil)
  if valid_591524 != nil:
    section.add "X-Amz-Content-Sha256", valid_591524
  var valid_591525 = header.getOrDefault("X-Amz-Date")
  valid_591525 = validateParameter(valid_591525, JString, required = false,
                                 default = nil)
  if valid_591525 != nil:
    section.add "X-Amz-Date", valid_591525
  var valid_591526 = header.getOrDefault("X-Amz-Credential")
  valid_591526 = validateParameter(valid_591526, JString, required = false,
                                 default = nil)
  if valid_591526 != nil:
    section.add "X-Amz-Credential", valid_591526
  var valid_591527 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591527 = validateParameter(valid_591527, JString, required = false,
                                 default = nil)
  if valid_591527 != nil:
    section.add "X-Amzn-Client-Token", valid_591527
  var valid_591528 = header.getOrDefault("X-Amz-Security-Token")
  valid_591528 = validateParameter(valid_591528, JString, required = false,
                                 default = nil)
  if valid_591528 != nil:
    section.add "X-Amz-Security-Token", valid_591528
  var valid_591529 = header.getOrDefault("X-Amz-Algorithm")
  valid_591529 = validateParameter(valid_591529, JString, required = false,
                                 default = nil)
  if valid_591529 != nil:
    section.add "X-Amz-Algorithm", valid_591529
  var valid_591530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591530 = validateParameter(valid_591530, JString, required = false,
                                 default = nil)
  if valid_591530 != nil:
    section.add "X-Amz-SignedHeaders", valid_591530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591532: Call_CreateResourceDefinitionVersion_591519;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a resource definition that has already been defined.
  ## 
  let valid = call_591532.validator(path, query, header, formData, body)
  let scheme = call_591532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591532.url(scheme.get, call_591532.host, call_591532.base,
                         call_591532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591532, url, valid)

proc call*(call_591533: Call_CreateResourceDefinitionVersion_591519;
          body: JsonNode; ResourceDefinitionId: string): Recallable =
  ## createResourceDefinitionVersion
  ## Creates a version of a resource definition that has already been defined.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_591534 = newJObject()
  var body_591535 = newJObject()
  if body != nil:
    body_591535 = body
  add(path_591534, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_591533.call(path_591534, nil, nil, nil, body_591535)

var createResourceDefinitionVersion* = Call_CreateResourceDefinitionVersion_591519(
    name: "createResourceDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_CreateResourceDefinitionVersion_591520, base: "/",
    url: url_CreateResourceDefinitionVersion_591521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDefinitionVersions_591502 = ref object of OpenApiRestCall_590348
proc url_ListResourceDefinitionVersions_591504(protocol: Scheme; host: string;
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

proc validate_ListResourceDefinitionVersions_591503(path: JsonNode;
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
  var valid_591505 = path.getOrDefault("ResourceDefinitionId")
  valid_591505 = validateParameter(valid_591505, JString, required = true,
                                 default = nil)
  if valid_591505 != nil:
    section.add "ResourceDefinitionId", valid_591505
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591506 = query.getOrDefault("MaxResults")
  valid_591506 = validateParameter(valid_591506, JString, required = false,
                                 default = nil)
  if valid_591506 != nil:
    section.add "MaxResults", valid_591506
  var valid_591507 = query.getOrDefault("NextToken")
  valid_591507 = validateParameter(valid_591507, JString, required = false,
                                 default = nil)
  if valid_591507 != nil:
    section.add "NextToken", valid_591507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591508 = header.getOrDefault("X-Amz-Signature")
  valid_591508 = validateParameter(valid_591508, JString, required = false,
                                 default = nil)
  if valid_591508 != nil:
    section.add "X-Amz-Signature", valid_591508
  var valid_591509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591509 = validateParameter(valid_591509, JString, required = false,
                                 default = nil)
  if valid_591509 != nil:
    section.add "X-Amz-Content-Sha256", valid_591509
  var valid_591510 = header.getOrDefault("X-Amz-Date")
  valid_591510 = validateParameter(valid_591510, JString, required = false,
                                 default = nil)
  if valid_591510 != nil:
    section.add "X-Amz-Date", valid_591510
  var valid_591511 = header.getOrDefault("X-Amz-Credential")
  valid_591511 = validateParameter(valid_591511, JString, required = false,
                                 default = nil)
  if valid_591511 != nil:
    section.add "X-Amz-Credential", valid_591511
  var valid_591512 = header.getOrDefault("X-Amz-Security-Token")
  valid_591512 = validateParameter(valid_591512, JString, required = false,
                                 default = nil)
  if valid_591512 != nil:
    section.add "X-Amz-Security-Token", valid_591512
  var valid_591513 = header.getOrDefault("X-Amz-Algorithm")
  valid_591513 = validateParameter(valid_591513, JString, required = false,
                                 default = nil)
  if valid_591513 != nil:
    section.add "X-Amz-Algorithm", valid_591513
  var valid_591514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591514 = validateParameter(valid_591514, JString, required = false,
                                 default = nil)
  if valid_591514 != nil:
    section.add "X-Amz-SignedHeaders", valid_591514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591515: Call_ListResourceDefinitionVersions_591502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of a resource definition.
  ## 
  let valid = call_591515.validator(path, query, header, formData, body)
  let scheme = call_591515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591515.url(scheme.get, call_591515.host, call_591515.base,
                         call_591515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591515, url, valid)

proc call*(call_591516: Call_ListResourceDefinitionVersions_591502;
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
  var path_591517 = newJObject()
  var query_591518 = newJObject()
  add(query_591518, "MaxResults", newJString(MaxResults))
  add(query_591518, "NextToken", newJString(NextToken))
  add(path_591517, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_591516.call(path_591517, query_591518, nil, nil, nil)

var listResourceDefinitionVersions* = Call_ListResourceDefinitionVersions_591502(
    name: "listResourceDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions",
    validator: validate_ListResourceDefinitionVersions_591503, base: "/",
    url: url_ListResourceDefinitionVersions_591504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSoftwareUpdateJob_591536 = ref object of OpenApiRestCall_590348
proc url_CreateSoftwareUpdateJob_591538(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSoftwareUpdateJob_591537(path: JsonNode; query: JsonNode;
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
  var valid_591539 = header.getOrDefault("X-Amz-Signature")
  valid_591539 = validateParameter(valid_591539, JString, required = false,
                                 default = nil)
  if valid_591539 != nil:
    section.add "X-Amz-Signature", valid_591539
  var valid_591540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591540 = validateParameter(valid_591540, JString, required = false,
                                 default = nil)
  if valid_591540 != nil:
    section.add "X-Amz-Content-Sha256", valid_591540
  var valid_591541 = header.getOrDefault("X-Amz-Date")
  valid_591541 = validateParameter(valid_591541, JString, required = false,
                                 default = nil)
  if valid_591541 != nil:
    section.add "X-Amz-Date", valid_591541
  var valid_591542 = header.getOrDefault("X-Amz-Credential")
  valid_591542 = validateParameter(valid_591542, JString, required = false,
                                 default = nil)
  if valid_591542 != nil:
    section.add "X-Amz-Credential", valid_591542
  var valid_591543 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591543 = validateParameter(valid_591543, JString, required = false,
                                 default = nil)
  if valid_591543 != nil:
    section.add "X-Amzn-Client-Token", valid_591543
  var valid_591544 = header.getOrDefault("X-Amz-Security-Token")
  valid_591544 = validateParameter(valid_591544, JString, required = false,
                                 default = nil)
  if valid_591544 != nil:
    section.add "X-Amz-Security-Token", valid_591544
  var valid_591545 = header.getOrDefault("X-Amz-Algorithm")
  valid_591545 = validateParameter(valid_591545, JString, required = false,
                                 default = nil)
  if valid_591545 != nil:
    section.add "X-Amz-Algorithm", valid_591545
  var valid_591546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591546 = validateParameter(valid_591546, JString, required = false,
                                 default = nil)
  if valid_591546 != nil:
    section.add "X-Amz-SignedHeaders", valid_591546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591548: Call_CreateSoftwareUpdateJob_591536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ## 
  let valid = call_591548.validator(path, query, header, formData, body)
  let scheme = call_591548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591548.url(scheme.get, call_591548.host, call_591548.base,
                         call_591548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591548, url, valid)

proc call*(call_591549: Call_CreateSoftwareUpdateJob_591536; body: JsonNode): Recallable =
  ## createSoftwareUpdateJob
  ## Creates a software update for a core or group of cores (specified as an IoT thing group.) Use this to update the OTA Agent as well as the Greengrass core software. It makes use of the IoT Jobs feature which provides additional commands to manage a Greengrass core software update job.
  ##   body: JObject (required)
  var body_591550 = newJObject()
  if body != nil:
    body_591550 = body
  result = call_591549.call(nil, nil, nil, nil, body_591550)

var createSoftwareUpdateJob* = Call_CreateSoftwareUpdateJob_591536(
    name: "createSoftwareUpdateJob", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/updates",
    validator: validate_CreateSoftwareUpdateJob_591537, base: "/",
    url: url_CreateSoftwareUpdateJob_591538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinition_591566 = ref object of OpenApiRestCall_590348
proc url_CreateSubscriptionDefinition_591568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSubscriptionDefinition_591567(path: JsonNode; query: JsonNode;
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
  var valid_591569 = header.getOrDefault("X-Amz-Signature")
  valid_591569 = validateParameter(valid_591569, JString, required = false,
                                 default = nil)
  if valid_591569 != nil:
    section.add "X-Amz-Signature", valid_591569
  var valid_591570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591570 = validateParameter(valid_591570, JString, required = false,
                                 default = nil)
  if valid_591570 != nil:
    section.add "X-Amz-Content-Sha256", valid_591570
  var valid_591571 = header.getOrDefault("X-Amz-Date")
  valid_591571 = validateParameter(valid_591571, JString, required = false,
                                 default = nil)
  if valid_591571 != nil:
    section.add "X-Amz-Date", valid_591571
  var valid_591572 = header.getOrDefault("X-Amz-Credential")
  valid_591572 = validateParameter(valid_591572, JString, required = false,
                                 default = nil)
  if valid_591572 != nil:
    section.add "X-Amz-Credential", valid_591572
  var valid_591573 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591573 = validateParameter(valid_591573, JString, required = false,
                                 default = nil)
  if valid_591573 != nil:
    section.add "X-Amzn-Client-Token", valid_591573
  var valid_591574 = header.getOrDefault("X-Amz-Security-Token")
  valid_591574 = validateParameter(valid_591574, JString, required = false,
                                 default = nil)
  if valid_591574 != nil:
    section.add "X-Amz-Security-Token", valid_591574
  var valid_591575 = header.getOrDefault("X-Amz-Algorithm")
  valid_591575 = validateParameter(valid_591575, JString, required = false,
                                 default = nil)
  if valid_591575 != nil:
    section.add "X-Amz-Algorithm", valid_591575
  var valid_591576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591576 = validateParameter(valid_591576, JString, required = false,
                                 default = nil)
  if valid_591576 != nil:
    section.add "X-Amz-SignedHeaders", valid_591576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591578: Call_CreateSubscriptionDefinition_591566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ## 
  let valid = call_591578.validator(path, query, header, formData, body)
  let scheme = call_591578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591578.url(scheme.get, call_591578.host, call_591578.base,
                         call_591578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591578, url, valid)

proc call*(call_591579: Call_CreateSubscriptionDefinition_591566; body: JsonNode): Recallable =
  ## createSubscriptionDefinition
  ## Creates a subscription definition. You may provide the initial version of the subscription definition now or use ''CreateSubscriptionDefinitionVersion'' at a later time.
  ##   body: JObject (required)
  var body_591580 = newJObject()
  if body != nil:
    body_591580 = body
  result = call_591579.call(nil, nil, nil, nil, body_591580)

var createSubscriptionDefinition* = Call_CreateSubscriptionDefinition_591566(
    name: "createSubscriptionDefinition", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_CreateSubscriptionDefinition_591567, base: "/",
    url: url_CreateSubscriptionDefinition_591568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitions_591551 = ref object of OpenApiRestCall_590348
proc url_ListSubscriptionDefinitions_591553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscriptionDefinitions_591552(path: JsonNode; query: JsonNode;
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
  var valid_591554 = query.getOrDefault("MaxResults")
  valid_591554 = validateParameter(valid_591554, JString, required = false,
                                 default = nil)
  if valid_591554 != nil:
    section.add "MaxResults", valid_591554
  var valid_591555 = query.getOrDefault("NextToken")
  valid_591555 = validateParameter(valid_591555, JString, required = false,
                                 default = nil)
  if valid_591555 != nil:
    section.add "NextToken", valid_591555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591556 = header.getOrDefault("X-Amz-Signature")
  valid_591556 = validateParameter(valid_591556, JString, required = false,
                                 default = nil)
  if valid_591556 != nil:
    section.add "X-Amz-Signature", valid_591556
  var valid_591557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591557 = validateParameter(valid_591557, JString, required = false,
                                 default = nil)
  if valid_591557 != nil:
    section.add "X-Amz-Content-Sha256", valid_591557
  var valid_591558 = header.getOrDefault("X-Amz-Date")
  valid_591558 = validateParameter(valid_591558, JString, required = false,
                                 default = nil)
  if valid_591558 != nil:
    section.add "X-Amz-Date", valid_591558
  var valid_591559 = header.getOrDefault("X-Amz-Credential")
  valid_591559 = validateParameter(valid_591559, JString, required = false,
                                 default = nil)
  if valid_591559 != nil:
    section.add "X-Amz-Credential", valid_591559
  var valid_591560 = header.getOrDefault("X-Amz-Security-Token")
  valid_591560 = validateParameter(valid_591560, JString, required = false,
                                 default = nil)
  if valid_591560 != nil:
    section.add "X-Amz-Security-Token", valid_591560
  var valid_591561 = header.getOrDefault("X-Amz-Algorithm")
  valid_591561 = validateParameter(valid_591561, JString, required = false,
                                 default = nil)
  if valid_591561 != nil:
    section.add "X-Amz-Algorithm", valid_591561
  var valid_591562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "X-Amz-SignedHeaders", valid_591562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591563: Call_ListSubscriptionDefinitions_591551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of subscription definitions.
  ## 
  let valid = call_591563.validator(path, query, header, formData, body)
  let scheme = call_591563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591563.url(scheme.get, call_591563.host, call_591563.base,
                         call_591563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591563, url, valid)

proc call*(call_591564: Call_ListSubscriptionDefinitions_591551;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscriptionDefinitions
  ## Retrieves a list of subscription definitions.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_591565 = newJObject()
  add(query_591565, "MaxResults", newJString(MaxResults))
  add(query_591565, "NextToken", newJString(NextToken))
  result = call_591564.call(nil, query_591565, nil, nil, nil)

var listSubscriptionDefinitions* = Call_ListSubscriptionDefinitions_591551(
    name: "listSubscriptionDefinitions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions",
    validator: validate_ListSubscriptionDefinitions_591552, base: "/",
    url: url_ListSubscriptionDefinitions_591553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubscriptionDefinitionVersion_591598 = ref object of OpenApiRestCall_590348
proc url_CreateSubscriptionDefinitionVersion_591600(protocol: Scheme; host: string;
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

proc validate_CreateSubscriptionDefinitionVersion_591599(path: JsonNode;
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
  var valid_591601 = path.getOrDefault("SubscriptionDefinitionId")
  valid_591601 = validateParameter(valid_591601, JString, required = true,
                                 default = nil)
  if valid_591601 != nil:
    section.add "SubscriptionDefinitionId", valid_591601
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
  var valid_591602 = header.getOrDefault("X-Amz-Signature")
  valid_591602 = validateParameter(valid_591602, JString, required = false,
                                 default = nil)
  if valid_591602 != nil:
    section.add "X-Amz-Signature", valid_591602
  var valid_591603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591603 = validateParameter(valid_591603, JString, required = false,
                                 default = nil)
  if valid_591603 != nil:
    section.add "X-Amz-Content-Sha256", valid_591603
  var valid_591604 = header.getOrDefault("X-Amz-Date")
  valid_591604 = validateParameter(valid_591604, JString, required = false,
                                 default = nil)
  if valid_591604 != nil:
    section.add "X-Amz-Date", valid_591604
  var valid_591605 = header.getOrDefault("X-Amz-Credential")
  valid_591605 = validateParameter(valid_591605, JString, required = false,
                                 default = nil)
  if valid_591605 != nil:
    section.add "X-Amz-Credential", valid_591605
  var valid_591606 = header.getOrDefault("X-Amzn-Client-Token")
  valid_591606 = validateParameter(valid_591606, JString, required = false,
                                 default = nil)
  if valid_591606 != nil:
    section.add "X-Amzn-Client-Token", valid_591606
  var valid_591607 = header.getOrDefault("X-Amz-Security-Token")
  valid_591607 = validateParameter(valid_591607, JString, required = false,
                                 default = nil)
  if valid_591607 != nil:
    section.add "X-Amz-Security-Token", valid_591607
  var valid_591608 = header.getOrDefault("X-Amz-Algorithm")
  valid_591608 = validateParameter(valid_591608, JString, required = false,
                                 default = nil)
  if valid_591608 != nil:
    section.add "X-Amz-Algorithm", valid_591608
  var valid_591609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591609 = validateParameter(valid_591609, JString, required = false,
                                 default = nil)
  if valid_591609 != nil:
    section.add "X-Amz-SignedHeaders", valid_591609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591611: Call_CreateSubscriptionDefinitionVersion_591598;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a version of a subscription definition which has already been defined.
  ## 
  let valid = call_591611.validator(path, query, header, formData, body)
  let scheme = call_591611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591611.url(scheme.get, call_591611.host, call_591611.base,
                         call_591611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591611, url, valid)

proc call*(call_591612: Call_CreateSubscriptionDefinitionVersion_591598;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## createSubscriptionDefinitionVersion
  ## Creates a version of a subscription definition which has already been defined.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_591613 = newJObject()
  var body_591614 = newJObject()
  add(path_591613, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_591614 = body
  result = call_591612.call(path_591613, nil, nil, nil, body_591614)

var createSubscriptionDefinitionVersion* = Call_CreateSubscriptionDefinitionVersion_591598(
    name: "createSubscriptionDefinitionVersion", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_CreateSubscriptionDefinitionVersion_591599, base: "/",
    url: url_CreateSubscriptionDefinitionVersion_591600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscriptionDefinitionVersions_591581 = ref object of OpenApiRestCall_590348
proc url_ListSubscriptionDefinitionVersions_591583(protocol: Scheme; host: string;
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

proc validate_ListSubscriptionDefinitionVersions_591582(path: JsonNode;
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
  var valid_591584 = path.getOrDefault("SubscriptionDefinitionId")
  valid_591584 = validateParameter(valid_591584, JString, required = true,
                                 default = nil)
  if valid_591584 != nil:
    section.add "SubscriptionDefinitionId", valid_591584
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_591585 = query.getOrDefault("MaxResults")
  valid_591585 = validateParameter(valid_591585, JString, required = false,
                                 default = nil)
  if valid_591585 != nil:
    section.add "MaxResults", valid_591585
  var valid_591586 = query.getOrDefault("NextToken")
  valid_591586 = validateParameter(valid_591586, JString, required = false,
                                 default = nil)
  if valid_591586 != nil:
    section.add "NextToken", valid_591586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591587 = header.getOrDefault("X-Amz-Signature")
  valid_591587 = validateParameter(valid_591587, JString, required = false,
                                 default = nil)
  if valid_591587 != nil:
    section.add "X-Amz-Signature", valid_591587
  var valid_591588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591588 = validateParameter(valid_591588, JString, required = false,
                                 default = nil)
  if valid_591588 != nil:
    section.add "X-Amz-Content-Sha256", valid_591588
  var valid_591589 = header.getOrDefault("X-Amz-Date")
  valid_591589 = validateParameter(valid_591589, JString, required = false,
                                 default = nil)
  if valid_591589 != nil:
    section.add "X-Amz-Date", valid_591589
  var valid_591590 = header.getOrDefault("X-Amz-Credential")
  valid_591590 = validateParameter(valid_591590, JString, required = false,
                                 default = nil)
  if valid_591590 != nil:
    section.add "X-Amz-Credential", valid_591590
  var valid_591591 = header.getOrDefault("X-Amz-Security-Token")
  valid_591591 = validateParameter(valid_591591, JString, required = false,
                                 default = nil)
  if valid_591591 != nil:
    section.add "X-Amz-Security-Token", valid_591591
  var valid_591592 = header.getOrDefault("X-Amz-Algorithm")
  valid_591592 = validateParameter(valid_591592, JString, required = false,
                                 default = nil)
  if valid_591592 != nil:
    section.add "X-Amz-Algorithm", valid_591592
  var valid_591593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591593 = validateParameter(valid_591593, JString, required = false,
                                 default = nil)
  if valid_591593 != nil:
    section.add "X-Amz-SignedHeaders", valid_591593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591594: Call_ListSubscriptionDefinitionVersions_591581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the versions of a subscription definition.
  ## 
  let valid = call_591594.validator(path, query, header, formData, body)
  let scheme = call_591594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591594.url(scheme.get, call_591594.host, call_591594.base,
                         call_591594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591594, url, valid)

proc call*(call_591595: Call_ListSubscriptionDefinitionVersions_591581;
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
  var path_591596 = newJObject()
  var query_591597 = newJObject()
  add(query_591597, "MaxResults", newJString(MaxResults))
  add(query_591597, "NextToken", newJString(NextToken))
  add(path_591596, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_591595.call(path_591596, query_591597, nil, nil, nil)

var listSubscriptionDefinitionVersions* = Call_ListSubscriptionDefinitionVersions_591581(
    name: "listSubscriptionDefinitionVersions", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions",
    validator: validate_ListSubscriptionDefinitionVersions_591582, base: "/",
    url: url_ListSubscriptionDefinitionVersions_591583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectorDefinition_591629 = ref object of OpenApiRestCall_590348
proc url_UpdateConnectorDefinition_591631(protocol: Scheme; host: string;
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

proc validate_UpdateConnectorDefinition_591630(path: JsonNode; query: JsonNode;
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
  var valid_591632 = path.getOrDefault("ConnectorDefinitionId")
  valid_591632 = validateParameter(valid_591632, JString, required = true,
                                 default = nil)
  if valid_591632 != nil:
    section.add "ConnectorDefinitionId", valid_591632
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
  var valid_591633 = header.getOrDefault("X-Amz-Signature")
  valid_591633 = validateParameter(valid_591633, JString, required = false,
                                 default = nil)
  if valid_591633 != nil:
    section.add "X-Amz-Signature", valid_591633
  var valid_591634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591634 = validateParameter(valid_591634, JString, required = false,
                                 default = nil)
  if valid_591634 != nil:
    section.add "X-Amz-Content-Sha256", valid_591634
  var valid_591635 = header.getOrDefault("X-Amz-Date")
  valid_591635 = validateParameter(valid_591635, JString, required = false,
                                 default = nil)
  if valid_591635 != nil:
    section.add "X-Amz-Date", valid_591635
  var valid_591636 = header.getOrDefault("X-Amz-Credential")
  valid_591636 = validateParameter(valid_591636, JString, required = false,
                                 default = nil)
  if valid_591636 != nil:
    section.add "X-Amz-Credential", valid_591636
  var valid_591637 = header.getOrDefault("X-Amz-Security-Token")
  valid_591637 = validateParameter(valid_591637, JString, required = false,
                                 default = nil)
  if valid_591637 != nil:
    section.add "X-Amz-Security-Token", valid_591637
  var valid_591638 = header.getOrDefault("X-Amz-Algorithm")
  valid_591638 = validateParameter(valid_591638, JString, required = false,
                                 default = nil)
  if valid_591638 != nil:
    section.add "X-Amz-Algorithm", valid_591638
  var valid_591639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591639 = validateParameter(valid_591639, JString, required = false,
                                 default = nil)
  if valid_591639 != nil:
    section.add "X-Amz-SignedHeaders", valid_591639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591641: Call_UpdateConnectorDefinition_591629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connector definition.
  ## 
  let valid = call_591641.validator(path, query, header, formData, body)
  let scheme = call_591641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591641.url(scheme.get, call_591641.host, call_591641.base,
                         call_591641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591641, url, valid)

proc call*(call_591642: Call_UpdateConnectorDefinition_591629;
          ConnectorDefinitionId: string; body: JsonNode): Recallable =
  ## updateConnectorDefinition
  ## Updates a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  ##   body: JObject (required)
  var path_591643 = newJObject()
  var body_591644 = newJObject()
  add(path_591643, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  if body != nil:
    body_591644 = body
  result = call_591642.call(path_591643, nil, nil, nil, body_591644)

var updateConnectorDefinition* = Call_UpdateConnectorDefinition_591629(
    name: "updateConnectorDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_UpdateConnectorDefinition_591630, base: "/",
    url: url_UpdateConnectorDefinition_591631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinition_591615 = ref object of OpenApiRestCall_590348
proc url_GetConnectorDefinition_591617(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectorDefinition_591616(path: JsonNode; query: JsonNode;
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
  var valid_591618 = path.getOrDefault("ConnectorDefinitionId")
  valid_591618 = validateParameter(valid_591618, JString, required = true,
                                 default = nil)
  if valid_591618 != nil:
    section.add "ConnectorDefinitionId", valid_591618
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
  var valid_591619 = header.getOrDefault("X-Amz-Signature")
  valid_591619 = validateParameter(valid_591619, JString, required = false,
                                 default = nil)
  if valid_591619 != nil:
    section.add "X-Amz-Signature", valid_591619
  var valid_591620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591620 = validateParameter(valid_591620, JString, required = false,
                                 default = nil)
  if valid_591620 != nil:
    section.add "X-Amz-Content-Sha256", valid_591620
  var valid_591621 = header.getOrDefault("X-Amz-Date")
  valid_591621 = validateParameter(valid_591621, JString, required = false,
                                 default = nil)
  if valid_591621 != nil:
    section.add "X-Amz-Date", valid_591621
  var valid_591622 = header.getOrDefault("X-Amz-Credential")
  valid_591622 = validateParameter(valid_591622, JString, required = false,
                                 default = nil)
  if valid_591622 != nil:
    section.add "X-Amz-Credential", valid_591622
  var valid_591623 = header.getOrDefault("X-Amz-Security-Token")
  valid_591623 = validateParameter(valid_591623, JString, required = false,
                                 default = nil)
  if valid_591623 != nil:
    section.add "X-Amz-Security-Token", valid_591623
  var valid_591624 = header.getOrDefault("X-Amz-Algorithm")
  valid_591624 = validateParameter(valid_591624, JString, required = false,
                                 default = nil)
  if valid_591624 != nil:
    section.add "X-Amz-Algorithm", valid_591624
  var valid_591625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591625 = validateParameter(valid_591625, JString, required = false,
                                 default = nil)
  if valid_591625 != nil:
    section.add "X-Amz-SignedHeaders", valid_591625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591626: Call_GetConnectorDefinition_591615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition.
  ## 
  let valid = call_591626.validator(path, query, header, formData, body)
  let scheme = call_591626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591626.url(scheme.get, call_591626.host, call_591626.base,
                         call_591626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591626, url, valid)

proc call*(call_591627: Call_GetConnectorDefinition_591615;
          ConnectorDefinitionId: string): Recallable =
  ## getConnectorDefinition
  ## Retrieves information about a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_591628 = newJObject()
  add(path_591628, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_591627.call(path_591628, nil, nil, nil, nil)

var getConnectorDefinition* = Call_GetConnectorDefinition_591615(
    name: "getConnectorDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_GetConnectorDefinition_591616, base: "/",
    url: url_GetConnectorDefinition_591617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnectorDefinition_591645 = ref object of OpenApiRestCall_590348
proc url_DeleteConnectorDefinition_591647(protocol: Scheme; host: string;
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

proc validate_DeleteConnectorDefinition_591646(path: JsonNode; query: JsonNode;
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
  var valid_591648 = path.getOrDefault("ConnectorDefinitionId")
  valid_591648 = validateParameter(valid_591648, JString, required = true,
                                 default = nil)
  if valid_591648 != nil:
    section.add "ConnectorDefinitionId", valid_591648
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
  var valid_591649 = header.getOrDefault("X-Amz-Signature")
  valid_591649 = validateParameter(valid_591649, JString, required = false,
                                 default = nil)
  if valid_591649 != nil:
    section.add "X-Amz-Signature", valid_591649
  var valid_591650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591650 = validateParameter(valid_591650, JString, required = false,
                                 default = nil)
  if valid_591650 != nil:
    section.add "X-Amz-Content-Sha256", valid_591650
  var valid_591651 = header.getOrDefault("X-Amz-Date")
  valid_591651 = validateParameter(valid_591651, JString, required = false,
                                 default = nil)
  if valid_591651 != nil:
    section.add "X-Amz-Date", valid_591651
  var valid_591652 = header.getOrDefault("X-Amz-Credential")
  valid_591652 = validateParameter(valid_591652, JString, required = false,
                                 default = nil)
  if valid_591652 != nil:
    section.add "X-Amz-Credential", valid_591652
  var valid_591653 = header.getOrDefault("X-Amz-Security-Token")
  valid_591653 = validateParameter(valid_591653, JString, required = false,
                                 default = nil)
  if valid_591653 != nil:
    section.add "X-Amz-Security-Token", valid_591653
  var valid_591654 = header.getOrDefault("X-Amz-Algorithm")
  valid_591654 = validateParameter(valid_591654, JString, required = false,
                                 default = nil)
  if valid_591654 != nil:
    section.add "X-Amz-Algorithm", valid_591654
  var valid_591655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591655 = validateParameter(valid_591655, JString, required = false,
                                 default = nil)
  if valid_591655 != nil:
    section.add "X-Amz-SignedHeaders", valid_591655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591656: Call_DeleteConnectorDefinition_591645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connector definition.
  ## 
  let valid = call_591656.validator(path, query, header, formData, body)
  let scheme = call_591656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591656.url(scheme.get, call_591656.host, call_591656.base,
                         call_591656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591656, url, valid)

proc call*(call_591657: Call_DeleteConnectorDefinition_591645;
          ConnectorDefinitionId: string): Recallable =
  ## deleteConnectorDefinition
  ## Deletes a connector definition.
  ##   ConnectorDefinitionId: string (required)
  ##                        : The ID of the connector definition.
  var path_591658 = newJObject()
  add(path_591658, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_591657.call(path_591658, nil, nil, nil, nil)

var deleteConnectorDefinition* = Call_DeleteConnectorDefinition_591645(
    name: "deleteConnectorDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/connectors/{ConnectorDefinitionId}",
    validator: validate_DeleteConnectorDefinition_591646, base: "/",
    url: url_DeleteConnectorDefinition_591647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCoreDefinition_591673 = ref object of OpenApiRestCall_590348
proc url_UpdateCoreDefinition_591675(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCoreDefinition_591674(path: JsonNode; query: JsonNode;
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
  var valid_591676 = path.getOrDefault("CoreDefinitionId")
  valid_591676 = validateParameter(valid_591676, JString, required = true,
                                 default = nil)
  if valid_591676 != nil:
    section.add "CoreDefinitionId", valid_591676
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
  var valid_591677 = header.getOrDefault("X-Amz-Signature")
  valid_591677 = validateParameter(valid_591677, JString, required = false,
                                 default = nil)
  if valid_591677 != nil:
    section.add "X-Amz-Signature", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-Content-Sha256", valid_591678
  var valid_591679 = header.getOrDefault("X-Amz-Date")
  valid_591679 = validateParameter(valid_591679, JString, required = false,
                                 default = nil)
  if valid_591679 != nil:
    section.add "X-Amz-Date", valid_591679
  var valid_591680 = header.getOrDefault("X-Amz-Credential")
  valid_591680 = validateParameter(valid_591680, JString, required = false,
                                 default = nil)
  if valid_591680 != nil:
    section.add "X-Amz-Credential", valid_591680
  var valid_591681 = header.getOrDefault("X-Amz-Security-Token")
  valid_591681 = validateParameter(valid_591681, JString, required = false,
                                 default = nil)
  if valid_591681 != nil:
    section.add "X-Amz-Security-Token", valid_591681
  var valid_591682 = header.getOrDefault("X-Amz-Algorithm")
  valid_591682 = validateParameter(valid_591682, JString, required = false,
                                 default = nil)
  if valid_591682 != nil:
    section.add "X-Amz-Algorithm", valid_591682
  var valid_591683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591683 = validateParameter(valid_591683, JString, required = false,
                                 default = nil)
  if valid_591683 != nil:
    section.add "X-Amz-SignedHeaders", valid_591683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591685: Call_UpdateCoreDefinition_591673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a core definition.
  ## 
  let valid = call_591685.validator(path, query, header, formData, body)
  let scheme = call_591685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591685.url(scheme.get, call_591685.host, call_591685.base,
                         call_591685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591685, url, valid)

proc call*(call_591686: Call_UpdateCoreDefinition_591673; CoreDefinitionId: string;
          body: JsonNode): Recallable =
  ## updateCoreDefinition
  ## Updates a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  ##   body: JObject (required)
  var path_591687 = newJObject()
  var body_591688 = newJObject()
  add(path_591687, "CoreDefinitionId", newJString(CoreDefinitionId))
  if body != nil:
    body_591688 = body
  result = call_591686.call(path_591687, nil, nil, nil, body_591688)

var updateCoreDefinition* = Call_UpdateCoreDefinition_591673(
    name: "updateCoreDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_UpdateCoreDefinition_591674, base: "/",
    url: url_UpdateCoreDefinition_591675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinition_591659 = ref object of OpenApiRestCall_590348
proc url_GetCoreDefinition_591661(protocol: Scheme; host: string; base: string;
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

proc validate_GetCoreDefinition_591660(path: JsonNode; query: JsonNode;
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
  var valid_591662 = path.getOrDefault("CoreDefinitionId")
  valid_591662 = validateParameter(valid_591662, JString, required = true,
                                 default = nil)
  if valid_591662 != nil:
    section.add "CoreDefinitionId", valid_591662
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
  var valid_591663 = header.getOrDefault("X-Amz-Signature")
  valid_591663 = validateParameter(valid_591663, JString, required = false,
                                 default = nil)
  if valid_591663 != nil:
    section.add "X-Amz-Signature", valid_591663
  var valid_591664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591664 = validateParameter(valid_591664, JString, required = false,
                                 default = nil)
  if valid_591664 != nil:
    section.add "X-Amz-Content-Sha256", valid_591664
  var valid_591665 = header.getOrDefault("X-Amz-Date")
  valid_591665 = validateParameter(valid_591665, JString, required = false,
                                 default = nil)
  if valid_591665 != nil:
    section.add "X-Amz-Date", valid_591665
  var valid_591666 = header.getOrDefault("X-Amz-Credential")
  valid_591666 = validateParameter(valid_591666, JString, required = false,
                                 default = nil)
  if valid_591666 != nil:
    section.add "X-Amz-Credential", valid_591666
  var valid_591667 = header.getOrDefault("X-Amz-Security-Token")
  valid_591667 = validateParameter(valid_591667, JString, required = false,
                                 default = nil)
  if valid_591667 != nil:
    section.add "X-Amz-Security-Token", valid_591667
  var valid_591668 = header.getOrDefault("X-Amz-Algorithm")
  valid_591668 = validateParameter(valid_591668, JString, required = false,
                                 default = nil)
  if valid_591668 != nil:
    section.add "X-Amz-Algorithm", valid_591668
  var valid_591669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591669 = validateParameter(valid_591669, JString, required = false,
                                 default = nil)
  if valid_591669 != nil:
    section.add "X-Amz-SignedHeaders", valid_591669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591670: Call_GetCoreDefinition_591659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_591670.validator(path, query, header, formData, body)
  let scheme = call_591670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591670.url(scheme.get, call_591670.host, call_591670.base,
                         call_591670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591670, url, valid)

proc call*(call_591671: Call_GetCoreDefinition_591659; CoreDefinitionId: string): Recallable =
  ## getCoreDefinition
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_591672 = newJObject()
  add(path_591672, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_591671.call(path_591672, nil, nil, nil, nil)

var getCoreDefinition* = Call_GetCoreDefinition_591659(name: "getCoreDefinition",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_GetCoreDefinition_591660, base: "/",
    url: url_GetCoreDefinition_591661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCoreDefinition_591689 = ref object of OpenApiRestCall_590348
proc url_DeleteCoreDefinition_591691(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCoreDefinition_591690(path: JsonNode; query: JsonNode;
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
  var valid_591692 = path.getOrDefault("CoreDefinitionId")
  valid_591692 = validateParameter(valid_591692, JString, required = true,
                                 default = nil)
  if valid_591692 != nil:
    section.add "CoreDefinitionId", valid_591692
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
  var valid_591693 = header.getOrDefault("X-Amz-Signature")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "X-Amz-Signature", valid_591693
  var valid_591694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591694 = validateParameter(valid_591694, JString, required = false,
                                 default = nil)
  if valid_591694 != nil:
    section.add "X-Amz-Content-Sha256", valid_591694
  var valid_591695 = header.getOrDefault("X-Amz-Date")
  valid_591695 = validateParameter(valid_591695, JString, required = false,
                                 default = nil)
  if valid_591695 != nil:
    section.add "X-Amz-Date", valid_591695
  var valid_591696 = header.getOrDefault("X-Amz-Credential")
  valid_591696 = validateParameter(valid_591696, JString, required = false,
                                 default = nil)
  if valid_591696 != nil:
    section.add "X-Amz-Credential", valid_591696
  var valid_591697 = header.getOrDefault("X-Amz-Security-Token")
  valid_591697 = validateParameter(valid_591697, JString, required = false,
                                 default = nil)
  if valid_591697 != nil:
    section.add "X-Amz-Security-Token", valid_591697
  var valid_591698 = header.getOrDefault("X-Amz-Algorithm")
  valid_591698 = validateParameter(valid_591698, JString, required = false,
                                 default = nil)
  if valid_591698 != nil:
    section.add "X-Amz-Algorithm", valid_591698
  var valid_591699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591699 = validateParameter(valid_591699, JString, required = false,
                                 default = nil)
  if valid_591699 != nil:
    section.add "X-Amz-SignedHeaders", valid_591699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591700: Call_DeleteCoreDefinition_591689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a core definition.
  ## 
  let valid = call_591700.validator(path, query, header, formData, body)
  let scheme = call_591700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591700.url(scheme.get, call_591700.host, call_591700.base,
                         call_591700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591700, url, valid)

proc call*(call_591701: Call_DeleteCoreDefinition_591689; CoreDefinitionId: string): Recallable =
  ## deleteCoreDefinition
  ## Deletes a core definition.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_591702 = newJObject()
  add(path_591702, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_591701.call(path_591702, nil, nil, nil, nil)

var deleteCoreDefinition* = Call_DeleteCoreDefinition_591689(
    name: "deleteCoreDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/cores/{CoreDefinitionId}",
    validator: validate_DeleteCoreDefinition_591690, base: "/",
    url: url_DeleteCoreDefinition_591691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeviceDefinition_591717 = ref object of OpenApiRestCall_590348
proc url_UpdateDeviceDefinition_591719(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeviceDefinition_591718(path: JsonNode; query: JsonNode;
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
  var valid_591720 = path.getOrDefault("DeviceDefinitionId")
  valid_591720 = validateParameter(valid_591720, JString, required = true,
                                 default = nil)
  if valid_591720 != nil:
    section.add "DeviceDefinitionId", valid_591720
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
  var valid_591721 = header.getOrDefault("X-Amz-Signature")
  valid_591721 = validateParameter(valid_591721, JString, required = false,
                                 default = nil)
  if valid_591721 != nil:
    section.add "X-Amz-Signature", valid_591721
  var valid_591722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591722 = validateParameter(valid_591722, JString, required = false,
                                 default = nil)
  if valid_591722 != nil:
    section.add "X-Amz-Content-Sha256", valid_591722
  var valid_591723 = header.getOrDefault("X-Amz-Date")
  valid_591723 = validateParameter(valid_591723, JString, required = false,
                                 default = nil)
  if valid_591723 != nil:
    section.add "X-Amz-Date", valid_591723
  var valid_591724 = header.getOrDefault("X-Amz-Credential")
  valid_591724 = validateParameter(valid_591724, JString, required = false,
                                 default = nil)
  if valid_591724 != nil:
    section.add "X-Amz-Credential", valid_591724
  var valid_591725 = header.getOrDefault("X-Amz-Security-Token")
  valid_591725 = validateParameter(valid_591725, JString, required = false,
                                 default = nil)
  if valid_591725 != nil:
    section.add "X-Amz-Security-Token", valid_591725
  var valid_591726 = header.getOrDefault("X-Amz-Algorithm")
  valid_591726 = validateParameter(valid_591726, JString, required = false,
                                 default = nil)
  if valid_591726 != nil:
    section.add "X-Amz-Algorithm", valid_591726
  var valid_591727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591727 = validateParameter(valid_591727, JString, required = false,
                                 default = nil)
  if valid_591727 != nil:
    section.add "X-Amz-SignedHeaders", valid_591727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591729: Call_UpdateDeviceDefinition_591717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a device definition.
  ## 
  let valid = call_591729.validator(path, query, header, formData, body)
  let scheme = call_591729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591729.url(scheme.get, call_591729.host, call_591729.base,
                         call_591729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591729, url, valid)

proc call*(call_591730: Call_UpdateDeviceDefinition_591717;
          DeviceDefinitionId: string; body: JsonNode): Recallable =
  ## updateDeviceDefinition
  ## Updates a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  ##   body: JObject (required)
  var path_591731 = newJObject()
  var body_591732 = newJObject()
  add(path_591731, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  if body != nil:
    body_591732 = body
  result = call_591730.call(path_591731, nil, nil, nil, body_591732)

var updateDeviceDefinition* = Call_UpdateDeviceDefinition_591717(
    name: "updateDeviceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_UpdateDeviceDefinition_591718, base: "/",
    url: url_UpdateDeviceDefinition_591719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinition_591703 = ref object of OpenApiRestCall_590348
proc url_GetDeviceDefinition_591705(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeviceDefinition_591704(path: JsonNode; query: JsonNode;
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
  var valid_591706 = path.getOrDefault("DeviceDefinitionId")
  valid_591706 = validateParameter(valid_591706, JString, required = true,
                                 default = nil)
  if valid_591706 != nil:
    section.add "DeviceDefinitionId", valid_591706
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
  var valid_591707 = header.getOrDefault("X-Amz-Signature")
  valid_591707 = validateParameter(valid_591707, JString, required = false,
                                 default = nil)
  if valid_591707 != nil:
    section.add "X-Amz-Signature", valid_591707
  var valid_591708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591708 = validateParameter(valid_591708, JString, required = false,
                                 default = nil)
  if valid_591708 != nil:
    section.add "X-Amz-Content-Sha256", valid_591708
  var valid_591709 = header.getOrDefault("X-Amz-Date")
  valid_591709 = validateParameter(valid_591709, JString, required = false,
                                 default = nil)
  if valid_591709 != nil:
    section.add "X-Amz-Date", valid_591709
  var valid_591710 = header.getOrDefault("X-Amz-Credential")
  valid_591710 = validateParameter(valid_591710, JString, required = false,
                                 default = nil)
  if valid_591710 != nil:
    section.add "X-Amz-Credential", valid_591710
  var valid_591711 = header.getOrDefault("X-Amz-Security-Token")
  valid_591711 = validateParameter(valid_591711, JString, required = false,
                                 default = nil)
  if valid_591711 != nil:
    section.add "X-Amz-Security-Token", valid_591711
  var valid_591712 = header.getOrDefault("X-Amz-Algorithm")
  valid_591712 = validateParameter(valid_591712, JString, required = false,
                                 default = nil)
  if valid_591712 != nil:
    section.add "X-Amz-Algorithm", valid_591712
  var valid_591713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591713 = validateParameter(valid_591713, JString, required = false,
                                 default = nil)
  if valid_591713 != nil:
    section.add "X-Amz-SignedHeaders", valid_591713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591714: Call_GetDeviceDefinition_591703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition.
  ## 
  let valid = call_591714.validator(path, query, header, formData, body)
  let scheme = call_591714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591714.url(scheme.get, call_591714.host, call_591714.base,
                         call_591714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591714, url, valid)

proc call*(call_591715: Call_GetDeviceDefinition_591703; DeviceDefinitionId: string): Recallable =
  ## getDeviceDefinition
  ## Retrieves information about a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_591716 = newJObject()
  add(path_591716, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_591715.call(path_591716, nil, nil, nil, nil)

var getDeviceDefinition* = Call_GetDeviceDefinition_591703(
    name: "getDeviceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_GetDeviceDefinition_591704, base: "/",
    url: url_GetDeviceDefinition_591705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeviceDefinition_591733 = ref object of OpenApiRestCall_590348
proc url_DeleteDeviceDefinition_591735(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeviceDefinition_591734(path: JsonNode; query: JsonNode;
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
  var valid_591736 = path.getOrDefault("DeviceDefinitionId")
  valid_591736 = validateParameter(valid_591736, JString, required = true,
                                 default = nil)
  if valid_591736 != nil:
    section.add "DeviceDefinitionId", valid_591736
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
  var valid_591737 = header.getOrDefault("X-Amz-Signature")
  valid_591737 = validateParameter(valid_591737, JString, required = false,
                                 default = nil)
  if valid_591737 != nil:
    section.add "X-Amz-Signature", valid_591737
  var valid_591738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591738 = validateParameter(valid_591738, JString, required = false,
                                 default = nil)
  if valid_591738 != nil:
    section.add "X-Amz-Content-Sha256", valid_591738
  var valid_591739 = header.getOrDefault("X-Amz-Date")
  valid_591739 = validateParameter(valid_591739, JString, required = false,
                                 default = nil)
  if valid_591739 != nil:
    section.add "X-Amz-Date", valid_591739
  var valid_591740 = header.getOrDefault("X-Amz-Credential")
  valid_591740 = validateParameter(valid_591740, JString, required = false,
                                 default = nil)
  if valid_591740 != nil:
    section.add "X-Amz-Credential", valid_591740
  var valid_591741 = header.getOrDefault("X-Amz-Security-Token")
  valid_591741 = validateParameter(valid_591741, JString, required = false,
                                 default = nil)
  if valid_591741 != nil:
    section.add "X-Amz-Security-Token", valid_591741
  var valid_591742 = header.getOrDefault("X-Amz-Algorithm")
  valid_591742 = validateParameter(valid_591742, JString, required = false,
                                 default = nil)
  if valid_591742 != nil:
    section.add "X-Amz-Algorithm", valid_591742
  var valid_591743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591743 = validateParameter(valid_591743, JString, required = false,
                                 default = nil)
  if valid_591743 != nil:
    section.add "X-Amz-SignedHeaders", valid_591743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591744: Call_DeleteDeviceDefinition_591733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a device definition.
  ## 
  let valid = call_591744.validator(path, query, header, formData, body)
  let scheme = call_591744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591744.url(scheme.get, call_591744.host, call_591744.base,
                         call_591744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591744, url, valid)

proc call*(call_591745: Call_DeleteDeviceDefinition_591733;
          DeviceDefinitionId: string): Recallable =
  ## deleteDeviceDefinition
  ## Deletes a device definition.
  ##   DeviceDefinitionId: string (required)
  ##                     : The ID of the device definition.
  var path_591746 = newJObject()
  add(path_591746, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  result = call_591745.call(path_591746, nil, nil, nil, nil)

var deleteDeviceDefinition* = Call_DeleteDeviceDefinition_591733(
    name: "deleteDeviceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/devices/{DeviceDefinitionId}",
    validator: validate_DeleteDeviceDefinition_591734, base: "/",
    url: url_DeleteDeviceDefinition_591735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionDefinition_591761 = ref object of OpenApiRestCall_590348
proc url_UpdateFunctionDefinition_591763(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionDefinition_591762(path: JsonNode; query: JsonNode;
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
  var valid_591764 = path.getOrDefault("FunctionDefinitionId")
  valid_591764 = validateParameter(valid_591764, JString, required = true,
                                 default = nil)
  if valid_591764 != nil:
    section.add "FunctionDefinitionId", valid_591764
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
  var valid_591765 = header.getOrDefault("X-Amz-Signature")
  valid_591765 = validateParameter(valid_591765, JString, required = false,
                                 default = nil)
  if valid_591765 != nil:
    section.add "X-Amz-Signature", valid_591765
  var valid_591766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591766 = validateParameter(valid_591766, JString, required = false,
                                 default = nil)
  if valid_591766 != nil:
    section.add "X-Amz-Content-Sha256", valid_591766
  var valid_591767 = header.getOrDefault("X-Amz-Date")
  valid_591767 = validateParameter(valid_591767, JString, required = false,
                                 default = nil)
  if valid_591767 != nil:
    section.add "X-Amz-Date", valid_591767
  var valid_591768 = header.getOrDefault("X-Amz-Credential")
  valid_591768 = validateParameter(valid_591768, JString, required = false,
                                 default = nil)
  if valid_591768 != nil:
    section.add "X-Amz-Credential", valid_591768
  var valid_591769 = header.getOrDefault("X-Amz-Security-Token")
  valid_591769 = validateParameter(valid_591769, JString, required = false,
                                 default = nil)
  if valid_591769 != nil:
    section.add "X-Amz-Security-Token", valid_591769
  var valid_591770 = header.getOrDefault("X-Amz-Algorithm")
  valid_591770 = validateParameter(valid_591770, JString, required = false,
                                 default = nil)
  if valid_591770 != nil:
    section.add "X-Amz-Algorithm", valid_591770
  var valid_591771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591771 = validateParameter(valid_591771, JString, required = false,
                                 default = nil)
  if valid_591771 != nil:
    section.add "X-Amz-SignedHeaders", valid_591771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591773: Call_UpdateFunctionDefinition_591761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Lambda function definition.
  ## 
  let valid = call_591773.validator(path, query, header, formData, body)
  let scheme = call_591773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591773.url(scheme.get, call_591773.host, call_591773.base,
                         call_591773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591773, url, valid)

proc call*(call_591774: Call_UpdateFunctionDefinition_591761;
          FunctionDefinitionId: string; body: JsonNode): Recallable =
  ## updateFunctionDefinition
  ## Updates a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  ##   body: JObject (required)
  var path_591775 = newJObject()
  var body_591776 = newJObject()
  add(path_591775, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  if body != nil:
    body_591776 = body
  result = call_591774.call(path_591775, nil, nil, nil, body_591776)

var updateFunctionDefinition* = Call_UpdateFunctionDefinition_591761(
    name: "updateFunctionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_UpdateFunctionDefinition_591762, base: "/",
    url: url_UpdateFunctionDefinition_591763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinition_591747 = ref object of OpenApiRestCall_590348
proc url_GetFunctionDefinition_591749(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionDefinition_591748(path: JsonNode; query: JsonNode;
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
  var valid_591750 = path.getOrDefault("FunctionDefinitionId")
  valid_591750 = validateParameter(valid_591750, JString, required = true,
                                 default = nil)
  if valid_591750 != nil:
    section.add "FunctionDefinitionId", valid_591750
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
  var valid_591751 = header.getOrDefault("X-Amz-Signature")
  valid_591751 = validateParameter(valid_591751, JString, required = false,
                                 default = nil)
  if valid_591751 != nil:
    section.add "X-Amz-Signature", valid_591751
  var valid_591752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591752 = validateParameter(valid_591752, JString, required = false,
                                 default = nil)
  if valid_591752 != nil:
    section.add "X-Amz-Content-Sha256", valid_591752
  var valid_591753 = header.getOrDefault("X-Amz-Date")
  valid_591753 = validateParameter(valid_591753, JString, required = false,
                                 default = nil)
  if valid_591753 != nil:
    section.add "X-Amz-Date", valid_591753
  var valid_591754 = header.getOrDefault("X-Amz-Credential")
  valid_591754 = validateParameter(valid_591754, JString, required = false,
                                 default = nil)
  if valid_591754 != nil:
    section.add "X-Amz-Credential", valid_591754
  var valid_591755 = header.getOrDefault("X-Amz-Security-Token")
  valid_591755 = validateParameter(valid_591755, JString, required = false,
                                 default = nil)
  if valid_591755 != nil:
    section.add "X-Amz-Security-Token", valid_591755
  var valid_591756 = header.getOrDefault("X-Amz-Algorithm")
  valid_591756 = validateParameter(valid_591756, JString, required = false,
                                 default = nil)
  if valid_591756 != nil:
    section.add "X-Amz-Algorithm", valid_591756
  var valid_591757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591757 = validateParameter(valid_591757, JString, required = false,
                                 default = nil)
  if valid_591757 != nil:
    section.add "X-Amz-SignedHeaders", valid_591757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591758: Call_GetFunctionDefinition_591747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ## 
  let valid = call_591758.validator(path, query, header, formData, body)
  let scheme = call_591758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591758.url(scheme.get, call_591758.host, call_591758.base,
                         call_591758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591758, url, valid)

proc call*(call_591759: Call_GetFunctionDefinition_591747;
          FunctionDefinitionId: string): Recallable =
  ## getFunctionDefinition
  ## Retrieves information about a Lambda function definition, including its creation time and latest version.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_591760 = newJObject()
  add(path_591760, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_591759.call(path_591760, nil, nil, nil, nil)

var getFunctionDefinition* = Call_GetFunctionDefinition_591747(
    name: "getFunctionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_GetFunctionDefinition_591748, base: "/",
    url: url_GetFunctionDefinition_591749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionDefinition_591777 = ref object of OpenApiRestCall_590348
proc url_DeleteFunctionDefinition_591779(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionDefinition_591778(path: JsonNode; query: JsonNode;
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
  var valid_591780 = path.getOrDefault("FunctionDefinitionId")
  valid_591780 = validateParameter(valid_591780, JString, required = true,
                                 default = nil)
  if valid_591780 != nil:
    section.add "FunctionDefinitionId", valid_591780
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
  var valid_591781 = header.getOrDefault("X-Amz-Signature")
  valid_591781 = validateParameter(valid_591781, JString, required = false,
                                 default = nil)
  if valid_591781 != nil:
    section.add "X-Amz-Signature", valid_591781
  var valid_591782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591782 = validateParameter(valid_591782, JString, required = false,
                                 default = nil)
  if valid_591782 != nil:
    section.add "X-Amz-Content-Sha256", valid_591782
  var valid_591783 = header.getOrDefault("X-Amz-Date")
  valid_591783 = validateParameter(valid_591783, JString, required = false,
                                 default = nil)
  if valid_591783 != nil:
    section.add "X-Amz-Date", valid_591783
  var valid_591784 = header.getOrDefault("X-Amz-Credential")
  valid_591784 = validateParameter(valid_591784, JString, required = false,
                                 default = nil)
  if valid_591784 != nil:
    section.add "X-Amz-Credential", valid_591784
  var valid_591785 = header.getOrDefault("X-Amz-Security-Token")
  valid_591785 = validateParameter(valid_591785, JString, required = false,
                                 default = nil)
  if valid_591785 != nil:
    section.add "X-Amz-Security-Token", valid_591785
  var valid_591786 = header.getOrDefault("X-Amz-Algorithm")
  valid_591786 = validateParameter(valid_591786, JString, required = false,
                                 default = nil)
  if valid_591786 != nil:
    section.add "X-Amz-Algorithm", valid_591786
  var valid_591787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591787 = validateParameter(valid_591787, JString, required = false,
                                 default = nil)
  if valid_591787 != nil:
    section.add "X-Amz-SignedHeaders", valid_591787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591788: Call_DeleteFunctionDefinition_591777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function definition.
  ## 
  let valid = call_591788.validator(path, query, header, formData, body)
  let scheme = call_591788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591788.url(scheme.get, call_591788.host, call_591788.base,
                         call_591788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591788, url, valid)

proc call*(call_591789: Call_DeleteFunctionDefinition_591777;
          FunctionDefinitionId: string): Recallable =
  ## deleteFunctionDefinition
  ## Deletes a Lambda function definition.
  ##   FunctionDefinitionId: string (required)
  ##                       : The ID of the Lambda function definition.
  var path_591790 = newJObject()
  add(path_591790, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_591789.call(path_591790, nil, nil, nil, nil)

var deleteFunctionDefinition* = Call_DeleteFunctionDefinition_591777(
    name: "deleteFunctionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/functions/{FunctionDefinitionId}",
    validator: validate_DeleteFunctionDefinition_591778, base: "/",
    url: url_DeleteFunctionDefinition_591779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_591805 = ref object of OpenApiRestCall_590348
proc url_UpdateGroup_591807(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_591806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591808 = path.getOrDefault("GroupId")
  valid_591808 = validateParameter(valid_591808, JString, required = true,
                                 default = nil)
  if valid_591808 != nil:
    section.add "GroupId", valid_591808
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
  var valid_591809 = header.getOrDefault("X-Amz-Signature")
  valid_591809 = validateParameter(valid_591809, JString, required = false,
                                 default = nil)
  if valid_591809 != nil:
    section.add "X-Amz-Signature", valid_591809
  var valid_591810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591810 = validateParameter(valid_591810, JString, required = false,
                                 default = nil)
  if valid_591810 != nil:
    section.add "X-Amz-Content-Sha256", valid_591810
  var valid_591811 = header.getOrDefault("X-Amz-Date")
  valid_591811 = validateParameter(valid_591811, JString, required = false,
                                 default = nil)
  if valid_591811 != nil:
    section.add "X-Amz-Date", valid_591811
  var valid_591812 = header.getOrDefault("X-Amz-Credential")
  valid_591812 = validateParameter(valid_591812, JString, required = false,
                                 default = nil)
  if valid_591812 != nil:
    section.add "X-Amz-Credential", valid_591812
  var valid_591813 = header.getOrDefault("X-Amz-Security-Token")
  valid_591813 = validateParameter(valid_591813, JString, required = false,
                                 default = nil)
  if valid_591813 != nil:
    section.add "X-Amz-Security-Token", valid_591813
  var valid_591814 = header.getOrDefault("X-Amz-Algorithm")
  valid_591814 = validateParameter(valid_591814, JString, required = false,
                                 default = nil)
  if valid_591814 != nil:
    section.add "X-Amz-Algorithm", valid_591814
  var valid_591815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591815 = validateParameter(valid_591815, JString, required = false,
                                 default = nil)
  if valid_591815 != nil:
    section.add "X-Amz-SignedHeaders", valid_591815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591817: Call_UpdateGroup_591805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group.
  ## 
  let valid = call_591817.validator(path, query, header, formData, body)
  let scheme = call_591817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591817.url(scheme.get, call_591817.host, call_591817.base,
                         call_591817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591817, url, valid)

proc call*(call_591818: Call_UpdateGroup_591805; GroupId: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_591819 = newJObject()
  var body_591820 = newJObject()
  add(path_591819, "GroupId", newJString(GroupId))
  if body != nil:
    body_591820 = body
  result = call_591818.call(path_591819, nil, nil, nil, body_591820)

var updateGroup* = Call_UpdateGroup_591805(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_UpdateGroup_591806,
                                        base: "/", url: url_UpdateGroup_591807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_591791 = ref object of OpenApiRestCall_590348
proc url_GetGroup_591793(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetGroup_591792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591794 = path.getOrDefault("GroupId")
  valid_591794 = validateParameter(valid_591794, JString, required = true,
                                 default = nil)
  if valid_591794 != nil:
    section.add "GroupId", valid_591794
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
  var valid_591795 = header.getOrDefault("X-Amz-Signature")
  valid_591795 = validateParameter(valid_591795, JString, required = false,
                                 default = nil)
  if valid_591795 != nil:
    section.add "X-Amz-Signature", valid_591795
  var valid_591796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591796 = validateParameter(valid_591796, JString, required = false,
                                 default = nil)
  if valid_591796 != nil:
    section.add "X-Amz-Content-Sha256", valid_591796
  var valid_591797 = header.getOrDefault("X-Amz-Date")
  valid_591797 = validateParameter(valid_591797, JString, required = false,
                                 default = nil)
  if valid_591797 != nil:
    section.add "X-Amz-Date", valid_591797
  var valid_591798 = header.getOrDefault("X-Amz-Credential")
  valid_591798 = validateParameter(valid_591798, JString, required = false,
                                 default = nil)
  if valid_591798 != nil:
    section.add "X-Amz-Credential", valid_591798
  var valid_591799 = header.getOrDefault("X-Amz-Security-Token")
  valid_591799 = validateParameter(valid_591799, JString, required = false,
                                 default = nil)
  if valid_591799 != nil:
    section.add "X-Amz-Security-Token", valid_591799
  var valid_591800 = header.getOrDefault("X-Amz-Algorithm")
  valid_591800 = validateParameter(valid_591800, JString, required = false,
                                 default = nil)
  if valid_591800 != nil:
    section.add "X-Amz-Algorithm", valid_591800
  var valid_591801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591801 = validateParameter(valid_591801, JString, required = false,
                                 default = nil)
  if valid_591801 != nil:
    section.add "X-Amz-SignedHeaders", valid_591801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591802: Call_GetGroup_591791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group.
  ## 
  let valid = call_591802.validator(path, query, header, formData, body)
  let scheme = call_591802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591802.url(scheme.get, call_591802.host, call_591802.base,
                         call_591802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591802, url, valid)

proc call*(call_591803: Call_GetGroup_591791; GroupId: string): Recallable =
  ## getGroup
  ## Retrieves information about a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_591804 = newJObject()
  add(path_591804, "GroupId", newJString(GroupId))
  result = call_591803.call(path_591804, nil, nil, nil, nil)

var getGroup* = Call_GetGroup_591791(name: "getGroup", meth: HttpMethod.HttpGet,
                                  host: "greengrass.amazonaws.com",
                                  route: "/greengrass/groups/{GroupId}",
                                  validator: validate_GetGroup_591792, base: "/",
                                  url: url_GetGroup_591793,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_591821 = ref object of OpenApiRestCall_590348
proc url_DeleteGroup_591823(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_591822(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591824 = path.getOrDefault("GroupId")
  valid_591824 = validateParameter(valid_591824, JString, required = true,
                                 default = nil)
  if valid_591824 != nil:
    section.add "GroupId", valid_591824
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
  var valid_591825 = header.getOrDefault("X-Amz-Signature")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-Signature", valid_591825
  var valid_591826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591826 = validateParameter(valid_591826, JString, required = false,
                                 default = nil)
  if valid_591826 != nil:
    section.add "X-Amz-Content-Sha256", valid_591826
  var valid_591827 = header.getOrDefault("X-Amz-Date")
  valid_591827 = validateParameter(valid_591827, JString, required = false,
                                 default = nil)
  if valid_591827 != nil:
    section.add "X-Amz-Date", valid_591827
  var valid_591828 = header.getOrDefault("X-Amz-Credential")
  valid_591828 = validateParameter(valid_591828, JString, required = false,
                                 default = nil)
  if valid_591828 != nil:
    section.add "X-Amz-Credential", valid_591828
  var valid_591829 = header.getOrDefault("X-Amz-Security-Token")
  valid_591829 = validateParameter(valid_591829, JString, required = false,
                                 default = nil)
  if valid_591829 != nil:
    section.add "X-Amz-Security-Token", valid_591829
  var valid_591830 = header.getOrDefault("X-Amz-Algorithm")
  valid_591830 = validateParameter(valid_591830, JString, required = false,
                                 default = nil)
  if valid_591830 != nil:
    section.add "X-Amz-Algorithm", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-SignedHeaders", valid_591831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591832: Call_DeleteGroup_591821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group.
  ## 
  let valid = call_591832.validator(path, query, header, formData, body)
  let scheme = call_591832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591832.url(scheme.get, call_591832.host, call_591832.base,
                         call_591832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591832, url, valid)

proc call*(call_591833: Call_DeleteGroup_591821; GroupId: string): Recallable =
  ## deleteGroup
  ## Deletes a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_591834 = newJObject()
  add(path_591834, "GroupId", newJString(GroupId))
  result = call_591833.call(path_591834, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_591821(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "greengrass.amazonaws.com",
                                        route: "/greengrass/groups/{GroupId}",
                                        validator: validate_DeleteGroup_591822,
                                        base: "/", url: url_DeleteGroup_591823,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoggerDefinition_591849 = ref object of OpenApiRestCall_590348
proc url_UpdateLoggerDefinition_591851(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLoggerDefinition_591850(path: JsonNode; query: JsonNode;
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
  var valid_591852 = path.getOrDefault("LoggerDefinitionId")
  valid_591852 = validateParameter(valid_591852, JString, required = true,
                                 default = nil)
  if valid_591852 != nil:
    section.add "LoggerDefinitionId", valid_591852
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
  var valid_591853 = header.getOrDefault("X-Amz-Signature")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "X-Amz-Signature", valid_591853
  var valid_591854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591854 = validateParameter(valid_591854, JString, required = false,
                                 default = nil)
  if valid_591854 != nil:
    section.add "X-Amz-Content-Sha256", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Date")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Date", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-Credential")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-Credential", valid_591856
  var valid_591857 = header.getOrDefault("X-Amz-Security-Token")
  valid_591857 = validateParameter(valid_591857, JString, required = false,
                                 default = nil)
  if valid_591857 != nil:
    section.add "X-Amz-Security-Token", valid_591857
  var valid_591858 = header.getOrDefault("X-Amz-Algorithm")
  valid_591858 = validateParameter(valid_591858, JString, required = false,
                                 default = nil)
  if valid_591858 != nil:
    section.add "X-Amz-Algorithm", valid_591858
  var valid_591859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591859 = validateParameter(valid_591859, JString, required = false,
                                 default = nil)
  if valid_591859 != nil:
    section.add "X-Amz-SignedHeaders", valid_591859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_UpdateLoggerDefinition_591849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a logger definition.
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591862: Call_UpdateLoggerDefinition_591849;
          LoggerDefinitionId: string; body: JsonNode): Recallable =
  ## updateLoggerDefinition
  ## Updates a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  ##   body: JObject (required)
  var path_591863 = newJObject()
  var body_591864 = newJObject()
  add(path_591863, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  if body != nil:
    body_591864 = body
  result = call_591862.call(path_591863, nil, nil, nil, body_591864)

var updateLoggerDefinition* = Call_UpdateLoggerDefinition_591849(
    name: "updateLoggerDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_UpdateLoggerDefinition_591850, base: "/",
    url: url_UpdateLoggerDefinition_591851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinition_591835 = ref object of OpenApiRestCall_590348
proc url_GetLoggerDefinition_591837(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoggerDefinition_591836(path: JsonNode; query: JsonNode;
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
  var valid_591838 = path.getOrDefault("LoggerDefinitionId")
  valid_591838 = validateParameter(valid_591838, JString, required = true,
                                 default = nil)
  if valid_591838 != nil:
    section.add "LoggerDefinitionId", valid_591838
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
  var valid_591839 = header.getOrDefault("X-Amz-Signature")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Signature", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Content-Sha256", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-Date")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-Date", valid_591841
  var valid_591842 = header.getOrDefault("X-Amz-Credential")
  valid_591842 = validateParameter(valid_591842, JString, required = false,
                                 default = nil)
  if valid_591842 != nil:
    section.add "X-Amz-Credential", valid_591842
  var valid_591843 = header.getOrDefault("X-Amz-Security-Token")
  valid_591843 = validateParameter(valid_591843, JString, required = false,
                                 default = nil)
  if valid_591843 != nil:
    section.add "X-Amz-Security-Token", valid_591843
  var valid_591844 = header.getOrDefault("X-Amz-Algorithm")
  valid_591844 = validateParameter(valid_591844, JString, required = false,
                                 default = nil)
  if valid_591844 != nil:
    section.add "X-Amz-Algorithm", valid_591844
  var valid_591845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591845 = validateParameter(valid_591845, JString, required = false,
                                 default = nil)
  if valid_591845 != nil:
    section.add "X-Amz-SignedHeaders", valid_591845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591846: Call_GetLoggerDefinition_591835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition.
  ## 
  let valid = call_591846.validator(path, query, header, formData, body)
  let scheme = call_591846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591846.url(scheme.get, call_591846.host, call_591846.base,
                         call_591846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591846, url, valid)

proc call*(call_591847: Call_GetLoggerDefinition_591835; LoggerDefinitionId: string): Recallable =
  ## getLoggerDefinition
  ## Retrieves information about a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_591848 = newJObject()
  add(path_591848, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_591847.call(path_591848, nil, nil, nil, nil)

var getLoggerDefinition* = Call_GetLoggerDefinition_591835(
    name: "getLoggerDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_GetLoggerDefinition_591836, base: "/",
    url: url_GetLoggerDefinition_591837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggerDefinition_591865 = ref object of OpenApiRestCall_590348
proc url_DeleteLoggerDefinition_591867(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoggerDefinition_591866(path: JsonNode; query: JsonNode;
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
  var valid_591868 = path.getOrDefault("LoggerDefinitionId")
  valid_591868 = validateParameter(valid_591868, JString, required = true,
                                 default = nil)
  if valid_591868 != nil:
    section.add "LoggerDefinitionId", valid_591868
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
  var valid_591869 = header.getOrDefault("X-Amz-Signature")
  valid_591869 = validateParameter(valid_591869, JString, required = false,
                                 default = nil)
  if valid_591869 != nil:
    section.add "X-Amz-Signature", valid_591869
  var valid_591870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591870 = validateParameter(valid_591870, JString, required = false,
                                 default = nil)
  if valid_591870 != nil:
    section.add "X-Amz-Content-Sha256", valid_591870
  var valid_591871 = header.getOrDefault("X-Amz-Date")
  valid_591871 = validateParameter(valid_591871, JString, required = false,
                                 default = nil)
  if valid_591871 != nil:
    section.add "X-Amz-Date", valid_591871
  var valid_591872 = header.getOrDefault("X-Amz-Credential")
  valid_591872 = validateParameter(valid_591872, JString, required = false,
                                 default = nil)
  if valid_591872 != nil:
    section.add "X-Amz-Credential", valid_591872
  var valid_591873 = header.getOrDefault("X-Amz-Security-Token")
  valid_591873 = validateParameter(valid_591873, JString, required = false,
                                 default = nil)
  if valid_591873 != nil:
    section.add "X-Amz-Security-Token", valid_591873
  var valid_591874 = header.getOrDefault("X-Amz-Algorithm")
  valid_591874 = validateParameter(valid_591874, JString, required = false,
                                 default = nil)
  if valid_591874 != nil:
    section.add "X-Amz-Algorithm", valid_591874
  var valid_591875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591875 = validateParameter(valid_591875, JString, required = false,
                                 default = nil)
  if valid_591875 != nil:
    section.add "X-Amz-SignedHeaders", valid_591875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591876: Call_DeleteLoggerDefinition_591865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a logger definition.
  ## 
  let valid = call_591876.validator(path, query, header, formData, body)
  let scheme = call_591876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591876.url(scheme.get, call_591876.host, call_591876.base,
                         call_591876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591876, url, valid)

proc call*(call_591877: Call_DeleteLoggerDefinition_591865;
          LoggerDefinitionId: string): Recallable =
  ## deleteLoggerDefinition
  ## Deletes a logger definition.
  ##   LoggerDefinitionId: string (required)
  ##                     : The ID of the logger definition.
  var path_591878 = newJObject()
  add(path_591878, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_591877.call(path_591878, nil, nil, nil, nil)

var deleteLoggerDefinition* = Call_DeleteLoggerDefinition_591865(
    name: "deleteLoggerDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/loggers/{LoggerDefinitionId}",
    validator: validate_DeleteLoggerDefinition_591866, base: "/",
    url: url_DeleteLoggerDefinition_591867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDefinition_591893 = ref object of OpenApiRestCall_590348
proc url_UpdateResourceDefinition_591895(protocol: Scheme; host: string;
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

proc validate_UpdateResourceDefinition_591894(path: JsonNode; query: JsonNode;
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
  var valid_591896 = path.getOrDefault("ResourceDefinitionId")
  valid_591896 = validateParameter(valid_591896, JString, required = true,
                                 default = nil)
  if valid_591896 != nil:
    section.add "ResourceDefinitionId", valid_591896
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
  var valid_591897 = header.getOrDefault("X-Amz-Signature")
  valid_591897 = validateParameter(valid_591897, JString, required = false,
                                 default = nil)
  if valid_591897 != nil:
    section.add "X-Amz-Signature", valid_591897
  var valid_591898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591898 = validateParameter(valid_591898, JString, required = false,
                                 default = nil)
  if valid_591898 != nil:
    section.add "X-Amz-Content-Sha256", valid_591898
  var valid_591899 = header.getOrDefault("X-Amz-Date")
  valid_591899 = validateParameter(valid_591899, JString, required = false,
                                 default = nil)
  if valid_591899 != nil:
    section.add "X-Amz-Date", valid_591899
  var valid_591900 = header.getOrDefault("X-Amz-Credential")
  valid_591900 = validateParameter(valid_591900, JString, required = false,
                                 default = nil)
  if valid_591900 != nil:
    section.add "X-Amz-Credential", valid_591900
  var valid_591901 = header.getOrDefault("X-Amz-Security-Token")
  valid_591901 = validateParameter(valid_591901, JString, required = false,
                                 default = nil)
  if valid_591901 != nil:
    section.add "X-Amz-Security-Token", valid_591901
  var valid_591902 = header.getOrDefault("X-Amz-Algorithm")
  valid_591902 = validateParameter(valid_591902, JString, required = false,
                                 default = nil)
  if valid_591902 != nil:
    section.add "X-Amz-Algorithm", valid_591902
  var valid_591903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591903 = validateParameter(valid_591903, JString, required = false,
                                 default = nil)
  if valid_591903 != nil:
    section.add "X-Amz-SignedHeaders", valid_591903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591905: Call_UpdateResourceDefinition_591893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a resource definition.
  ## 
  let valid = call_591905.validator(path, query, header, formData, body)
  let scheme = call_591905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591905.url(scheme.get, call_591905.host, call_591905.base,
                         call_591905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591905, url, valid)

proc call*(call_591906: Call_UpdateResourceDefinition_591893; body: JsonNode;
          ResourceDefinitionId: string): Recallable =
  ## updateResourceDefinition
  ## Updates a resource definition.
  ##   body: JObject (required)
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_591907 = newJObject()
  var body_591908 = newJObject()
  if body != nil:
    body_591908 = body
  add(path_591907, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_591906.call(path_591907, nil, nil, nil, body_591908)

var updateResourceDefinition* = Call_UpdateResourceDefinition_591893(
    name: "updateResourceDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_UpdateResourceDefinition_591894, base: "/",
    url: url_UpdateResourceDefinition_591895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinition_591879 = ref object of OpenApiRestCall_590348
proc url_GetResourceDefinition_591881(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceDefinition_591880(path: JsonNode; query: JsonNode;
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
  var valid_591882 = path.getOrDefault("ResourceDefinitionId")
  valid_591882 = validateParameter(valid_591882, JString, required = true,
                                 default = nil)
  if valid_591882 != nil:
    section.add "ResourceDefinitionId", valid_591882
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
  var valid_591883 = header.getOrDefault("X-Amz-Signature")
  valid_591883 = validateParameter(valid_591883, JString, required = false,
                                 default = nil)
  if valid_591883 != nil:
    section.add "X-Amz-Signature", valid_591883
  var valid_591884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591884 = validateParameter(valid_591884, JString, required = false,
                                 default = nil)
  if valid_591884 != nil:
    section.add "X-Amz-Content-Sha256", valid_591884
  var valid_591885 = header.getOrDefault("X-Amz-Date")
  valid_591885 = validateParameter(valid_591885, JString, required = false,
                                 default = nil)
  if valid_591885 != nil:
    section.add "X-Amz-Date", valid_591885
  var valid_591886 = header.getOrDefault("X-Amz-Credential")
  valid_591886 = validateParameter(valid_591886, JString, required = false,
                                 default = nil)
  if valid_591886 != nil:
    section.add "X-Amz-Credential", valid_591886
  var valid_591887 = header.getOrDefault("X-Amz-Security-Token")
  valid_591887 = validateParameter(valid_591887, JString, required = false,
                                 default = nil)
  if valid_591887 != nil:
    section.add "X-Amz-Security-Token", valid_591887
  var valid_591888 = header.getOrDefault("X-Amz-Algorithm")
  valid_591888 = validateParameter(valid_591888, JString, required = false,
                                 default = nil)
  if valid_591888 != nil:
    section.add "X-Amz-Algorithm", valid_591888
  var valid_591889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591889 = validateParameter(valid_591889, JString, required = false,
                                 default = nil)
  if valid_591889 != nil:
    section.add "X-Amz-SignedHeaders", valid_591889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591890: Call_GetResourceDefinition_591879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ## 
  let valid = call_591890.validator(path, query, header, formData, body)
  let scheme = call_591890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591890.url(scheme.get, call_591890.host, call_591890.base,
                         call_591890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591890, url, valid)

proc call*(call_591891: Call_GetResourceDefinition_591879;
          ResourceDefinitionId: string): Recallable =
  ## getResourceDefinition
  ## Retrieves information about a resource definition, including its creation time and latest version.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_591892 = newJObject()
  add(path_591892, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_591891.call(path_591892, nil, nil, nil, nil)

var getResourceDefinition* = Call_GetResourceDefinition_591879(
    name: "getResourceDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_GetResourceDefinition_591880, base: "/",
    url: url_GetResourceDefinition_591881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDefinition_591909 = ref object of OpenApiRestCall_590348
proc url_DeleteResourceDefinition_591911(protocol: Scheme; host: string;
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

proc validate_DeleteResourceDefinition_591910(path: JsonNode; query: JsonNode;
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
  var valid_591912 = path.getOrDefault("ResourceDefinitionId")
  valid_591912 = validateParameter(valid_591912, JString, required = true,
                                 default = nil)
  if valid_591912 != nil:
    section.add "ResourceDefinitionId", valid_591912
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
  var valid_591913 = header.getOrDefault("X-Amz-Signature")
  valid_591913 = validateParameter(valid_591913, JString, required = false,
                                 default = nil)
  if valid_591913 != nil:
    section.add "X-Amz-Signature", valid_591913
  var valid_591914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591914 = validateParameter(valid_591914, JString, required = false,
                                 default = nil)
  if valid_591914 != nil:
    section.add "X-Amz-Content-Sha256", valid_591914
  var valid_591915 = header.getOrDefault("X-Amz-Date")
  valid_591915 = validateParameter(valid_591915, JString, required = false,
                                 default = nil)
  if valid_591915 != nil:
    section.add "X-Amz-Date", valid_591915
  var valid_591916 = header.getOrDefault("X-Amz-Credential")
  valid_591916 = validateParameter(valid_591916, JString, required = false,
                                 default = nil)
  if valid_591916 != nil:
    section.add "X-Amz-Credential", valid_591916
  var valid_591917 = header.getOrDefault("X-Amz-Security-Token")
  valid_591917 = validateParameter(valid_591917, JString, required = false,
                                 default = nil)
  if valid_591917 != nil:
    section.add "X-Amz-Security-Token", valid_591917
  var valid_591918 = header.getOrDefault("X-Amz-Algorithm")
  valid_591918 = validateParameter(valid_591918, JString, required = false,
                                 default = nil)
  if valid_591918 != nil:
    section.add "X-Amz-Algorithm", valid_591918
  var valid_591919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591919 = validateParameter(valid_591919, JString, required = false,
                                 default = nil)
  if valid_591919 != nil:
    section.add "X-Amz-SignedHeaders", valid_591919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591920: Call_DeleteResourceDefinition_591909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resource definition.
  ## 
  let valid = call_591920.validator(path, query, header, formData, body)
  let scheme = call_591920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591920.url(scheme.get, call_591920.host, call_591920.base,
                         call_591920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591920, url, valid)

proc call*(call_591921: Call_DeleteResourceDefinition_591909;
          ResourceDefinitionId: string): Recallable =
  ## deleteResourceDefinition
  ## Deletes a resource definition.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_591922 = newJObject()
  add(path_591922, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_591921.call(path_591922, nil, nil, nil, nil)

var deleteResourceDefinition* = Call_DeleteResourceDefinition_591909(
    name: "deleteResourceDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/resources/{ResourceDefinitionId}",
    validator: validate_DeleteResourceDefinition_591910, base: "/",
    url: url_DeleteResourceDefinition_591911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubscriptionDefinition_591937 = ref object of OpenApiRestCall_590348
proc url_UpdateSubscriptionDefinition_591939(protocol: Scheme; host: string;
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

proc validate_UpdateSubscriptionDefinition_591938(path: JsonNode; query: JsonNode;
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
  var valid_591940 = path.getOrDefault("SubscriptionDefinitionId")
  valid_591940 = validateParameter(valid_591940, JString, required = true,
                                 default = nil)
  if valid_591940 != nil:
    section.add "SubscriptionDefinitionId", valid_591940
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
  var valid_591941 = header.getOrDefault("X-Amz-Signature")
  valid_591941 = validateParameter(valid_591941, JString, required = false,
                                 default = nil)
  if valid_591941 != nil:
    section.add "X-Amz-Signature", valid_591941
  var valid_591942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591942 = validateParameter(valid_591942, JString, required = false,
                                 default = nil)
  if valid_591942 != nil:
    section.add "X-Amz-Content-Sha256", valid_591942
  var valid_591943 = header.getOrDefault("X-Amz-Date")
  valid_591943 = validateParameter(valid_591943, JString, required = false,
                                 default = nil)
  if valid_591943 != nil:
    section.add "X-Amz-Date", valid_591943
  var valid_591944 = header.getOrDefault("X-Amz-Credential")
  valid_591944 = validateParameter(valid_591944, JString, required = false,
                                 default = nil)
  if valid_591944 != nil:
    section.add "X-Amz-Credential", valid_591944
  var valid_591945 = header.getOrDefault("X-Amz-Security-Token")
  valid_591945 = validateParameter(valid_591945, JString, required = false,
                                 default = nil)
  if valid_591945 != nil:
    section.add "X-Amz-Security-Token", valid_591945
  var valid_591946 = header.getOrDefault("X-Amz-Algorithm")
  valid_591946 = validateParameter(valid_591946, JString, required = false,
                                 default = nil)
  if valid_591946 != nil:
    section.add "X-Amz-Algorithm", valid_591946
  var valid_591947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591947 = validateParameter(valid_591947, JString, required = false,
                                 default = nil)
  if valid_591947 != nil:
    section.add "X-Amz-SignedHeaders", valid_591947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591949: Call_UpdateSubscriptionDefinition_591937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a subscription definition.
  ## 
  let valid = call_591949.validator(path, query, header, formData, body)
  let scheme = call_591949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591949.url(scheme.get, call_591949.host, call_591949.base,
                         call_591949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591949, url, valid)

proc call*(call_591950: Call_UpdateSubscriptionDefinition_591937;
          SubscriptionDefinitionId: string; body: JsonNode): Recallable =
  ## updateSubscriptionDefinition
  ## Updates a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  ##   body: JObject (required)
  var path_591951 = newJObject()
  var body_591952 = newJObject()
  add(path_591951, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  if body != nil:
    body_591952 = body
  result = call_591950.call(path_591951, nil, nil, nil, body_591952)

var updateSubscriptionDefinition* = Call_UpdateSubscriptionDefinition_591937(
    name: "updateSubscriptionDefinition", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_UpdateSubscriptionDefinition_591938, base: "/",
    url: url_UpdateSubscriptionDefinition_591939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinition_591923 = ref object of OpenApiRestCall_590348
proc url_GetSubscriptionDefinition_591925(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinition_591924(path: JsonNode; query: JsonNode;
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
  var valid_591926 = path.getOrDefault("SubscriptionDefinitionId")
  valid_591926 = validateParameter(valid_591926, JString, required = true,
                                 default = nil)
  if valid_591926 != nil:
    section.add "SubscriptionDefinitionId", valid_591926
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
  var valid_591927 = header.getOrDefault("X-Amz-Signature")
  valid_591927 = validateParameter(valid_591927, JString, required = false,
                                 default = nil)
  if valid_591927 != nil:
    section.add "X-Amz-Signature", valid_591927
  var valid_591928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591928 = validateParameter(valid_591928, JString, required = false,
                                 default = nil)
  if valid_591928 != nil:
    section.add "X-Amz-Content-Sha256", valid_591928
  var valid_591929 = header.getOrDefault("X-Amz-Date")
  valid_591929 = validateParameter(valid_591929, JString, required = false,
                                 default = nil)
  if valid_591929 != nil:
    section.add "X-Amz-Date", valid_591929
  var valid_591930 = header.getOrDefault("X-Amz-Credential")
  valid_591930 = validateParameter(valid_591930, JString, required = false,
                                 default = nil)
  if valid_591930 != nil:
    section.add "X-Amz-Credential", valid_591930
  var valid_591931 = header.getOrDefault("X-Amz-Security-Token")
  valid_591931 = validateParameter(valid_591931, JString, required = false,
                                 default = nil)
  if valid_591931 != nil:
    section.add "X-Amz-Security-Token", valid_591931
  var valid_591932 = header.getOrDefault("X-Amz-Algorithm")
  valid_591932 = validateParameter(valid_591932, JString, required = false,
                                 default = nil)
  if valid_591932 != nil:
    section.add "X-Amz-Algorithm", valid_591932
  var valid_591933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591933 = validateParameter(valid_591933, JString, required = false,
                                 default = nil)
  if valid_591933 != nil:
    section.add "X-Amz-SignedHeaders", valid_591933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591934: Call_GetSubscriptionDefinition_591923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition.
  ## 
  let valid = call_591934.validator(path, query, header, formData, body)
  let scheme = call_591934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591934.url(scheme.get, call_591934.host, call_591934.base,
                         call_591934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591934, url, valid)

proc call*(call_591935: Call_GetSubscriptionDefinition_591923;
          SubscriptionDefinitionId: string): Recallable =
  ## getSubscriptionDefinition
  ## Retrieves information about a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_591936 = newJObject()
  add(path_591936, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_591935.call(path_591936, nil, nil, nil, nil)

var getSubscriptionDefinition* = Call_GetSubscriptionDefinition_591923(
    name: "getSubscriptionDefinition", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_GetSubscriptionDefinition_591924, base: "/",
    url: url_GetSubscriptionDefinition_591925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubscriptionDefinition_591953 = ref object of OpenApiRestCall_590348
proc url_DeleteSubscriptionDefinition_591955(protocol: Scheme; host: string;
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

proc validate_DeleteSubscriptionDefinition_591954(path: JsonNode; query: JsonNode;
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
  var valid_591956 = path.getOrDefault("SubscriptionDefinitionId")
  valid_591956 = validateParameter(valid_591956, JString, required = true,
                                 default = nil)
  if valid_591956 != nil:
    section.add "SubscriptionDefinitionId", valid_591956
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
  var valid_591957 = header.getOrDefault("X-Amz-Signature")
  valid_591957 = validateParameter(valid_591957, JString, required = false,
                                 default = nil)
  if valid_591957 != nil:
    section.add "X-Amz-Signature", valid_591957
  var valid_591958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591958 = validateParameter(valid_591958, JString, required = false,
                                 default = nil)
  if valid_591958 != nil:
    section.add "X-Amz-Content-Sha256", valid_591958
  var valid_591959 = header.getOrDefault("X-Amz-Date")
  valid_591959 = validateParameter(valid_591959, JString, required = false,
                                 default = nil)
  if valid_591959 != nil:
    section.add "X-Amz-Date", valid_591959
  var valid_591960 = header.getOrDefault("X-Amz-Credential")
  valid_591960 = validateParameter(valid_591960, JString, required = false,
                                 default = nil)
  if valid_591960 != nil:
    section.add "X-Amz-Credential", valid_591960
  var valid_591961 = header.getOrDefault("X-Amz-Security-Token")
  valid_591961 = validateParameter(valid_591961, JString, required = false,
                                 default = nil)
  if valid_591961 != nil:
    section.add "X-Amz-Security-Token", valid_591961
  var valid_591962 = header.getOrDefault("X-Amz-Algorithm")
  valid_591962 = validateParameter(valid_591962, JString, required = false,
                                 default = nil)
  if valid_591962 != nil:
    section.add "X-Amz-Algorithm", valid_591962
  var valid_591963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591963 = validateParameter(valid_591963, JString, required = false,
                                 default = nil)
  if valid_591963 != nil:
    section.add "X-Amz-SignedHeaders", valid_591963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591964: Call_DeleteSubscriptionDefinition_591953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subscription definition.
  ## 
  let valid = call_591964.validator(path, query, header, formData, body)
  let scheme = call_591964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591964.url(scheme.get, call_591964.host, call_591964.base,
                         call_591964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591964, url, valid)

proc call*(call_591965: Call_DeleteSubscriptionDefinition_591953;
          SubscriptionDefinitionId: string): Recallable =
  ## deleteSubscriptionDefinition
  ## Deletes a subscription definition.
  ##   SubscriptionDefinitionId: string (required)
  ##                           : The ID of the subscription definition.
  var path_591966 = newJObject()
  add(path_591966, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_591965.call(path_591966, nil, nil, nil, nil)

var deleteSubscriptionDefinition* = Call_DeleteSubscriptionDefinition_591953(
    name: "deleteSubscriptionDefinition", meth: HttpMethod.HttpDelete,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}",
    validator: validate_DeleteSubscriptionDefinition_591954, base: "/",
    url: url_DeleteSubscriptionDefinition_591955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkDeploymentStatus_591967 = ref object of OpenApiRestCall_590348
proc url_GetBulkDeploymentStatus_591969(protocol: Scheme; host: string; base: string;
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

proc validate_GetBulkDeploymentStatus_591968(path: JsonNode; query: JsonNode;
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
  var valid_591970 = path.getOrDefault("BulkDeploymentId")
  valid_591970 = validateParameter(valid_591970, JString, required = true,
                                 default = nil)
  if valid_591970 != nil:
    section.add "BulkDeploymentId", valid_591970
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
  var valid_591971 = header.getOrDefault("X-Amz-Signature")
  valid_591971 = validateParameter(valid_591971, JString, required = false,
                                 default = nil)
  if valid_591971 != nil:
    section.add "X-Amz-Signature", valid_591971
  var valid_591972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591972 = validateParameter(valid_591972, JString, required = false,
                                 default = nil)
  if valid_591972 != nil:
    section.add "X-Amz-Content-Sha256", valid_591972
  var valid_591973 = header.getOrDefault("X-Amz-Date")
  valid_591973 = validateParameter(valid_591973, JString, required = false,
                                 default = nil)
  if valid_591973 != nil:
    section.add "X-Amz-Date", valid_591973
  var valid_591974 = header.getOrDefault("X-Amz-Credential")
  valid_591974 = validateParameter(valid_591974, JString, required = false,
                                 default = nil)
  if valid_591974 != nil:
    section.add "X-Amz-Credential", valid_591974
  var valid_591975 = header.getOrDefault("X-Amz-Security-Token")
  valid_591975 = validateParameter(valid_591975, JString, required = false,
                                 default = nil)
  if valid_591975 != nil:
    section.add "X-Amz-Security-Token", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Algorithm")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Algorithm", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-SignedHeaders", valid_591977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591978: Call_GetBulkDeploymentStatus_591967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a bulk deployment.
  ## 
  let valid = call_591978.validator(path, query, header, formData, body)
  let scheme = call_591978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591978.url(scheme.get, call_591978.host, call_591978.base,
                         call_591978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591978, url, valid)

proc call*(call_591979: Call_GetBulkDeploymentStatus_591967;
          BulkDeploymentId: string): Recallable =
  ## getBulkDeploymentStatus
  ## Returns the status of a bulk deployment.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_591980 = newJObject()
  add(path_591980, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_591979.call(path_591980, nil, nil, nil, nil)

var getBulkDeploymentStatus* = Call_GetBulkDeploymentStatus_591967(
    name: "getBulkDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/status",
    validator: validate_GetBulkDeploymentStatus_591968, base: "/",
    url: url_GetBulkDeploymentStatus_591969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnectivityInfo_591995 = ref object of OpenApiRestCall_590348
proc url_UpdateConnectivityInfo_591997(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnectivityInfo_591996(path: JsonNode; query: JsonNode;
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
  var valid_591998 = path.getOrDefault("ThingName")
  valid_591998 = validateParameter(valid_591998, JString, required = true,
                                 default = nil)
  if valid_591998 != nil:
    section.add "ThingName", valid_591998
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
  var valid_591999 = header.getOrDefault("X-Amz-Signature")
  valid_591999 = validateParameter(valid_591999, JString, required = false,
                                 default = nil)
  if valid_591999 != nil:
    section.add "X-Amz-Signature", valid_591999
  var valid_592000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592000 = validateParameter(valid_592000, JString, required = false,
                                 default = nil)
  if valid_592000 != nil:
    section.add "X-Amz-Content-Sha256", valid_592000
  var valid_592001 = header.getOrDefault("X-Amz-Date")
  valid_592001 = validateParameter(valid_592001, JString, required = false,
                                 default = nil)
  if valid_592001 != nil:
    section.add "X-Amz-Date", valid_592001
  var valid_592002 = header.getOrDefault("X-Amz-Credential")
  valid_592002 = validateParameter(valid_592002, JString, required = false,
                                 default = nil)
  if valid_592002 != nil:
    section.add "X-Amz-Credential", valid_592002
  var valid_592003 = header.getOrDefault("X-Amz-Security-Token")
  valid_592003 = validateParameter(valid_592003, JString, required = false,
                                 default = nil)
  if valid_592003 != nil:
    section.add "X-Amz-Security-Token", valid_592003
  var valid_592004 = header.getOrDefault("X-Amz-Algorithm")
  valid_592004 = validateParameter(valid_592004, JString, required = false,
                                 default = nil)
  if valid_592004 != nil:
    section.add "X-Amz-Algorithm", valid_592004
  var valid_592005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592005 = validateParameter(valid_592005, JString, required = false,
                                 default = nil)
  if valid_592005 != nil:
    section.add "X-Amz-SignedHeaders", valid_592005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592007: Call_UpdateConnectivityInfo_591995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ## 
  let valid = call_592007.validator(path, query, header, formData, body)
  let scheme = call_592007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592007.url(scheme.get, call_592007.host, call_592007.base,
                         call_592007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592007, url, valid)

proc call*(call_592008: Call_UpdateConnectivityInfo_591995; ThingName: string;
          body: JsonNode): Recallable =
  ## updateConnectivityInfo
  ## Updates the connectivity information for the core. Any devices that belong to the group which has this core will receive this information in order to find the location of the core and connect to it.
  ##   ThingName: string (required)
  ##            : The thing name.
  ##   body: JObject (required)
  var path_592009 = newJObject()
  var body_592010 = newJObject()
  add(path_592009, "ThingName", newJString(ThingName))
  if body != nil:
    body_592010 = body
  result = call_592008.call(path_592009, nil, nil, nil, body_592010)

var updateConnectivityInfo* = Call_UpdateConnectivityInfo_591995(
    name: "updateConnectivityInfo", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_UpdateConnectivityInfo_591996, base: "/",
    url: url_UpdateConnectivityInfo_591997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectivityInfo_591981 = ref object of OpenApiRestCall_590348
proc url_GetConnectivityInfo_591983(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectivityInfo_591982(path: JsonNode; query: JsonNode;
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
  var valid_591984 = path.getOrDefault("ThingName")
  valid_591984 = validateParameter(valid_591984, JString, required = true,
                                 default = nil)
  if valid_591984 != nil:
    section.add "ThingName", valid_591984
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
  var valid_591985 = header.getOrDefault("X-Amz-Signature")
  valid_591985 = validateParameter(valid_591985, JString, required = false,
                                 default = nil)
  if valid_591985 != nil:
    section.add "X-Amz-Signature", valid_591985
  var valid_591986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591986 = validateParameter(valid_591986, JString, required = false,
                                 default = nil)
  if valid_591986 != nil:
    section.add "X-Amz-Content-Sha256", valid_591986
  var valid_591987 = header.getOrDefault("X-Amz-Date")
  valid_591987 = validateParameter(valid_591987, JString, required = false,
                                 default = nil)
  if valid_591987 != nil:
    section.add "X-Amz-Date", valid_591987
  var valid_591988 = header.getOrDefault("X-Amz-Credential")
  valid_591988 = validateParameter(valid_591988, JString, required = false,
                                 default = nil)
  if valid_591988 != nil:
    section.add "X-Amz-Credential", valid_591988
  var valid_591989 = header.getOrDefault("X-Amz-Security-Token")
  valid_591989 = validateParameter(valid_591989, JString, required = false,
                                 default = nil)
  if valid_591989 != nil:
    section.add "X-Amz-Security-Token", valid_591989
  var valid_591990 = header.getOrDefault("X-Amz-Algorithm")
  valid_591990 = validateParameter(valid_591990, JString, required = false,
                                 default = nil)
  if valid_591990 != nil:
    section.add "X-Amz-Algorithm", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-SignedHeaders", valid_591991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591992: Call_GetConnectivityInfo_591981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the connectivity information for a core.
  ## 
  let valid = call_591992.validator(path, query, header, formData, body)
  let scheme = call_591992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591992.url(scheme.get, call_591992.host, call_591992.base,
                         call_591992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591992, url, valid)

proc call*(call_591993: Call_GetConnectivityInfo_591981; ThingName: string): Recallable =
  ## getConnectivityInfo
  ## Retrieves the connectivity information for a core.
  ##   ThingName: string (required)
  ##            : The thing name.
  var path_591994 = newJObject()
  add(path_591994, "ThingName", newJString(ThingName))
  result = call_591993.call(path_591994, nil, nil, nil, nil)

var getConnectivityInfo* = Call_GetConnectivityInfo_591981(
    name: "getConnectivityInfo", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/things/{ThingName}/connectivityInfo",
    validator: validate_GetConnectivityInfo_591982, base: "/",
    url: url_GetConnectivityInfo_591983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectorDefinitionVersion_592011 = ref object of OpenApiRestCall_590348
proc url_GetConnectorDefinitionVersion_592013(protocol: Scheme; host: string;
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

proc validate_GetConnectorDefinitionVersion_592012(path: JsonNode; query: JsonNode;
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
  var valid_592014 = path.getOrDefault("ConnectorDefinitionVersionId")
  valid_592014 = validateParameter(valid_592014, JString, required = true,
                                 default = nil)
  if valid_592014 != nil:
    section.add "ConnectorDefinitionVersionId", valid_592014
  var valid_592015 = path.getOrDefault("ConnectorDefinitionId")
  valid_592015 = validateParameter(valid_592015, JString, required = true,
                                 default = nil)
  if valid_592015 != nil:
    section.add "ConnectorDefinitionId", valid_592015
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592016 = query.getOrDefault("NextToken")
  valid_592016 = validateParameter(valid_592016, JString, required = false,
                                 default = nil)
  if valid_592016 != nil:
    section.add "NextToken", valid_592016
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592017 = header.getOrDefault("X-Amz-Signature")
  valid_592017 = validateParameter(valid_592017, JString, required = false,
                                 default = nil)
  if valid_592017 != nil:
    section.add "X-Amz-Signature", valid_592017
  var valid_592018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592018 = validateParameter(valid_592018, JString, required = false,
                                 default = nil)
  if valid_592018 != nil:
    section.add "X-Amz-Content-Sha256", valid_592018
  var valid_592019 = header.getOrDefault("X-Amz-Date")
  valid_592019 = validateParameter(valid_592019, JString, required = false,
                                 default = nil)
  if valid_592019 != nil:
    section.add "X-Amz-Date", valid_592019
  var valid_592020 = header.getOrDefault("X-Amz-Credential")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = nil)
  if valid_592020 != nil:
    section.add "X-Amz-Credential", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-Security-Token")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-Security-Token", valid_592021
  var valid_592022 = header.getOrDefault("X-Amz-Algorithm")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = nil)
  if valid_592022 != nil:
    section.add "X-Amz-Algorithm", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-SignedHeaders", valid_592023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592024: Call_GetConnectorDefinitionVersion_592011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a connector definition version, including the connectors that the version contains. Connectors are prebuilt modules that interact with local infrastructure, device protocols, AWS, and other cloud services.
  ## 
  let valid = call_592024.validator(path, query, header, formData, body)
  let scheme = call_592024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592024.url(scheme.get, call_592024.host, call_592024.base,
                         call_592024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592024, url, valid)

proc call*(call_592025: Call_GetConnectorDefinitionVersion_592011;
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
  var path_592026 = newJObject()
  var query_592027 = newJObject()
  add(path_592026, "ConnectorDefinitionVersionId",
      newJString(ConnectorDefinitionVersionId))
  add(query_592027, "NextToken", newJString(NextToken))
  add(path_592026, "ConnectorDefinitionId", newJString(ConnectorDefinitionId))
  result = call_592025.call(path_592026, query_592027, nil, nil, nil)

var getConnectorDefinitionVersion* = Call_GetConnectorDefinitionVersion_592011(
    name: "getConnectorDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/connectors/{ConnectorDefinitionId}/versions/{ConnectorDefinitionVersionId}",
    validator: validate_GetConnectorDefinitionVersion_592012, base: "/",
    url: url_GetConnectorDefinitionVersion_592013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCoreDefinitionVersion_592028 = ref object of OpenApiRestCall_590348
proc url_GetCoreDefinitionVersion_592030(protocol: Scheme; host: string;
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

proc validate_GetCoreDefinitionVersion_592029(path: JsonNode; query: JsonNode;
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
  var valid_592031 = path.getOrDefault("CoreDefinitionVersionId")
  valid_592031 = validateParameter(valid_592031, JString, required = true,
                                 default = nil)
  if valid_592031 != nil:
    section.add "CoreDefinitionVersionId", valid_592031
  var valid_592032 = path.getOrDefault("CoreDefinitionId")
  valid_592032 = validateParameter(valid_592032, JString, required = true,
                                 default = nil)
  if valid_592032 != nil:
    section.add "CoreDefinitionId", valid_592032
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
  var valid_592033 = header.getOrDefault("X-Amz-Signature")
  valid_592033 = validateParameter(valid_592033, JString, required = false,
                                 default = nil)
  if valid_592033 != nil:
    section.add "X-Amz-Signature", valid_592033
  var valid_592034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592034 = validateParameter(valid_592034, JString, required = false,
                                 default = nil)
  if valid_592034 != nil:
    section.add "X-Amz-Content-Sha256", valid_592034
  var valid_592035 = header.getOrDefault("X-Amz-Date")
  valid_592035 = validateParameter(valid_592035, JString, required = false,
                                 default = nil)
  if valid_592035 != nil:
    section.add "X-Amz-Date", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-Credential")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-Credential", valid_592036
  var valid_592037 = header.getOrDefault("X-Amz-Security-Token")
  valid_592037 = validateParameter(valid_592037, JString, required = false,
                                 default = nil)
  if valid_592037 != nil:
    section.add "X-Amz-Security-Token", valid_592037
  var valid_592038 = header.getOrDefault("X-Amz-Algorithm")
  valid_592038 = validateParameter(valid_592038, JString, required = false,
                                 default = nil)
  if valid_592038 != nil:
    section.add "X-Amz-Algorithm", valid_592038
  var valid_592039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "X-Amz-SignedHeaders", valid_592039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592040: Call_GetCoreDefinitionVersion_592028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a core definition version.
  ## 
  let valid = call_592040.validator(path, query, header, formData, body)
  let scheme = call_592040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592040.url(scheme.get, call_592040.host, call_592040.base,
                         call_592040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592040, url, valid)

proc call*(call_592041: Call_GetCoreDefinitionVersion_592028;
          CoreDefinitionVersionId: string; CoreDefinitionId: string): Recallable =
  ## getCoreDefinitionVersion
  ## Retrieves information about a core definition version.
  ##   CoreDefinitionVersionId: string (required)
  ##                          : The ID of the core definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListCoreDefinitionVersions'' requests. If the version is the last one that was associated with a core definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   CoreDefinitionId: string (required)
  ##                   : The ID of the core definition.
  var path_592042 = newJObject()
  add(path_592042, "CoreDefinitionVersionId", newJString(CoreDefinitionVersionId))
  add(path_592042, "CoreDefinitionId", newJString(CoreDefinitionId))
  result = call_592041.call(path_592042, nil, nil, nil, nil)

var getCoreDefinitionVersion* = Call_GetCoreDefinitionVersion_592028(
    name: "getCoreDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/cores/{CoreDefinitionId}/versions/{CoreDefinitionVersionId}",
    validator: validate_GetCoreDefinitionVersion_592029, base: "/",
    url: url_GetCoreDefinitionVersion_592030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStatus_592043 = ref object of OpenApiRestCall_590348
proc url_GetDeploymentStatus_592045(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStatus_592044(path: JsonNode; query: JsonNode;
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
  var valid_592046 = path.getOrDefault("GroupId")
  valid_592046 = validateParameter(valid_592046, JString, required = true,
                                 default = nil)
  if valid_592046 != nil:
    section.add "GroupId", valid_592046
  var valid_592047 = path.getOrDefault("DeploymentId")
  valid_592047 = validateParameter(valid_592047, JString, required = true,
                                 default = nil)
  if valid_592047 != nil:
    section.add "DeploymentId", valid_592047
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
  var valid_592048 = header.getOrDefault("X-Amz-Signature")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Signature", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Content-Sha256", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-Date")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-Date", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-Credential")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-Credential", valid_592051
  var valid_592052 = header.getOrDefault("X-Amz-Security-Token")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "X-Amz-Security-Token", valid_592052
  var valid_592053 = header.getOrDefault("X-Amz-Algorithm")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "X-Amz-Algorithm", valid_592053
  var valid_592054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592054 = validateParameter(valid_592054, JString, required = false,
                                 default = nil)
  if valid_592054 != nil:
    section.add "X-Amz-SignedHeaders", valid_592054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592055: Call_GetDeploymentStatus_592043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of a deployment.
  ## 
  let valid = call_592055.validator(path, query, header, formData, body)
  let scheme = call_592055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592055.url(scheme.get, call_592055.host, call_592055.base,
                         call_592055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592055, url, valid)

proc call*(call_592056: Call_GetDeploymentStatus_592043; GroupId: string;
          DeploymentId: string): Recallable =
  ## getDeploymentStatus
  ## Returns the status of a deployment.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   DeploymentId: string (required)
  ##               : The ID of the deployment.
  var path_592057 = newJObject()
  add(path_592057, "GroupId", newJString(GroupId))
  add(path_592057, "DeploymentId", newJString(DeploymentId))
  result = call_592056.call(path_592057, nil, nil, nil, nil)

var getDeploymentStatus* = Call_GetDeploymentStatus_592043(
    name: "getDeploymentStatus", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/{DeploymentId}/status",
    validator: validate_GetDeploymentStatus_592044, base: "/",
    url: url_GetDeploymentStatus_592045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeviceDefinitionVersion_592058 = ref object of OpenApiRestCall_590348
proc url_GetDeviceDefinitionVersion_592060(protocol: Scheme; host: string;
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

proc validate_GetDeviceDefinitionVersion_592059(path: JsonNode; query: JsonNode;
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
  var valid_592061 = path.getOrDefault("DeviceDefinitionId")
  valid_592061 = validateParameter(valid_592061, JString, required = true,
                                 default = nil)
  if valid_592061 != nil:
    section.add "DeviceDefinitionId", valid_592061
  var valid_592062 = path.getOrDefault("DeviceDefinitionVersionId")
  valid_592062 = validateParameter(valid_592062, JString, required = true,
                                 default = nil)
  if valid_592062 != nil:
    section.add "DeviceDefinitionVersionId", valid_592062
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592063 = query.getOrDefault("NextToken")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "NextToken", valid_592063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592064 = header.getOrDefault("X-Amz-Signature")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-Signature", valid_592064
  var valid_592065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-Content-Sha256", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Date")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Date", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Credential")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Credential", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-Security-Token")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-Security-Token", valid_592068
  var valid_592069 = header.getOrDefault("X-Amz-Algorithm")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "X-Amz-Algorithm", valid_592069
  var valid_592070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "X-Amz-SignedHeaders", valid_592070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592071: Call_GetDeviceDefinitionVersion_592058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a device definition version.
  ## 
  let valid = call_592071.validator(path, query, header, formData, body)
  let scheme = call_592071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592071.url(scheme.get, call_592071.host, call_592071.base,
                         call_592071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592071, url, valid)

proc call*(call_592072: Call_GetDeviceDefinitionVersion_592058;
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
  var path_592073 = newJObject()
  var query_592074 = newJObject()
  add(path_592073, "DeviceDefinitionId", newJString(DeviceDefinitionId))
  add(query_592074, "NextToken", newJString(NextToken))
  add(path_592073, "DeviceDefinitionVersionId",
      newJString(DeviceDefinitionVersionId))
  result = call_592072.call(path_592073, query_592074, nil, nil, nil)

var getDeviceDefinitionVersion* = Call_GetDeviceDefinitionVersion_592058(
    name: "getDeviceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/devices/{DeviceDefinitionId}/versions/{DeviceDefinitionVersionId}",
    validator: validate_GetDeviceDefinitionVersion_592059, base: "/",
    url: url_GetDeviceDefinitionVersion_592060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionDefinitionVersion_592075 = ref object of OpenApiRestCall_590348
proc url_GetFunctionDefinitionVersion_592077(protocol: Scheme; host: string;
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

proc validate_GetFunctionDefinitionVersion_592076(path: JsonNode; query: JsonNode;
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
  var valid_592078 = path.getOrDefault("FunctionDefinitionVersionId")
  valid_592078 = validateParameter(valid_592078, JString, required = true,
                                 default = nil)
  if valid_592078 != nil:
    section.add "FunctionDefinitionVersionId", valid_592078
  var valid_592079 = path.getOrDefault("FunctionDefinitionId")
  valid_592079 = validateParameter(valid_592079, JString, required = true,
                                 default = nil)
  if valid_592079 != nil:
    section.add "FunctionDefinitionId", valid_592079
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592080 = query.getOrDefault("NextToken")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "NextToken", valid_592080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592081 = header.getOrDefault("X-Amz-Signature")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-Signature", valid_592081
  var valid_592082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592082 = validateParameter(valid_592082, JString, required = false,
                                 default = nil)
  if valid_592082 != nil:
    section.add "X-Amz-Content-Sha256", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Date")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Date", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Credential")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Credential", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-Security-Token")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-Security-Token", valid_592085
  var valid_592086 = header.getOrDefault("X-Amz-Algorithm")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "X-Amz-Algorithm", valid_592086
  var valid_592087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "X-Amz-SignedHeaders", valid_592087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592088: Call_GetFunctionDefinitionVersion_592075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a Lambda function definition version, including which Lambda functions are included in the version and their configurations.
  ## 
  let valid = call_592088.validator(path, query, header, formData, body)
  let scheme = call_592088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592088.url(scheme.get, call_592088.host, call_592088.base,
                         call_592088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592088, url, valid)

proc call*(call_592089: Call_GetFunctionDefinitionVersion_592075;
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
  var path_592090 = newJObject()
  var query_592091 = newJObject()
  add(path_592090, "FunctionDefinitionVersionId",
      newJString(FunctionDefinitionVersionId))
  add(query_592091, "NextToken", newJString(NextToken))
  add(path_592090, "FunctionDefinitionId", newJString(FunctionDefinitionId))
  result = call_592089.call(path_592090, query_592091, nil, nil, nil)

var getFunctionDefinitionVersion* = Call_GetFunctionDefinitionVersion_592075(
    name: "getFunctionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/functions/{FunctionDefinitionId}/versions/{FunctionDefinitionVersionId}",
    validator: validate_GetFunctionDefinitionVersion_592076, base: "/",
    url: url_GetFunctionDefinitionVersion_592077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateAuthority_592092 = ref object of OpenApiRestCall_590348
proc url_GetGroupCertificateAuthority_592094(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateAuthority_592093(path: JsonNode; query: JsonNode;
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
  var valid_592095 = path.getOrDefault("GroupId")
  valid_592095 = validateParameter(valid_592095, JString, required = true,
                                 default = nil)
  if valid_592095 != nil:
    section.add "GroupId", valid_592095
  var valid_592096 = path.getOrDefault("CertificateAuthorityId")
  valid_592096 = validateParameter(valid_592096, JString, required = true,
                                 default = nil)
  if valid_592096 != nil:
    section.add "CertificateAuthorityId", valid_592096
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
  var valid_592097 = header.getOrDefault("X-Amz-Signature")
  valid_592097 = validateParameter(valid_592097, JString, required = false,
                                 default = nil)
  if valid_592097 != nil:
    section.add "X-Amz-Signature", valid_592097
  var valid_592098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592098 = validateParameter(valid_592098, JString, required = false,
                                 default = nil)
  if valid_592098 != nil:
    section.add "X-Amz-Content-Sha256", valid_592098
  var valid_592099 = header.getOrDefault("X-Amz-Date")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "X-Amz-Date", valid_592099
  var valid_592100 = header.getOrDefault("X-Amz-Credential")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "X-Amz-Credential", valid_592100
  var valid_592101 = header.getOrDefault("X-Amz-Security-Token")
  valid_592101 = validateParameter(valid_592101, JString, required = false,
                                 default = nil)
  if valid_592101 != nil:
    section.add "X-Amz-Security-Token", valid_592101
  var valid_592102 = header.getOrDefault("X-Amz-Algorithm")
  valid_592102 = validateParameter(valid_592102, JString, required = false,
                                 default = nil)
  if valid_592102 != nil:
    section.add "X-Amz-Algorithm", valid_592102
  var valid_592103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-SignedHeaders", valid_592103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592104: Call_GetGroupCertificateAuthority_592092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ## 
  let valid = call_592104.validator(path, query, header, formData, body)
  let scheme = call_592104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592104.url(scheme.get, call_592104.host, call_592104.base,
                         call_592104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592104, url, valid)

proc call*(call_592105: Call_GetGroupCertificateAuthority_592092; GroupId: string;
          CertificateAuthorityId: string): Recallable =
  ## getGroupCertificateAuthority
  ## Retreives the CA associated with a group. Returns the public key of the CA.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   CertificateAuthorityId: string (required)
  ##                         : The ID of the certificate authority.
  var path_592106 = newJObject()
  add(path_592106, "GroupId", newJString(GroupId))
  add(path_592106, "CertificateAuthorityId", newJString(CertificateAuthorityId))
  result = call_592105.call(path_592106, nil, nil, nil, nil)

var getGroupCertificateAuthority* = Call_GetGroupCertificateAuthority_592092(
    name: "getGroupCertificateAuthority", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/{CertificateAuthorityId}",
    validator: validate_GetGroupCertificateAuthority_592093, base: "/",
    url: url_GetGroupCertificateAuthority_592094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroupCertificateConfiguration_592121 = ref object of OpenApiRestCall_590348
proc url_UpdateGroupCertificateConfiguration_592123(protocol: Scheme; host: string;
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

proc validate_UpdateGroupCertificateConfiguration_592122(path: JsonNode;
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
  var valid_592124 = path.getOrDefault("GroupId")
  valid_592124 = validateParameter(valid_592124, JString, required = true,
                                 default = nil)
  if valid_592124 != nil:
    section.add "GroupId", valid_592124
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
  var valid_592125 = header.getOrDefault("X-Amz-Signature")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Signature", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-Content-Sha256", valid_592126
  var valid_592127 = header.getOrDefault("X-Amz-Date")
  valid_592127 = validateParameter(valid_592127, JString, required = false,
                                 default = nil)
  if valid_592127 != nil:
    section.add "X-Amz-Date", valid_592127
  var valid_592128 = header.getOrDefault("X-Amz-Credential")
  valid_592128 = validateParameter(valid_592128, JString, required = false,
                                 default = nil)
  if valid_592128 != nil:
    section.add "X-Amz-Credential", valid_592128
  var valid_592129 = header.getOrDefault("X-Amz-Security-Token")
  valid_592129 = validateParameter(valid_592129, JString, required = false,
                                 default = nil)
  if valid_592129 != nil:
    section.add "X-Amz-Security-Token", valid_592129
  var valid_592130 = header.getOrDefault("X-Amz-Algorithm")
  valid_592130 = validateParameter(valid_592130, JString, required = false,
                                 default = nil)
  if valid_592130 != nil:
    section.add "X-Amz-Algorithm", valid_592130
  var valid_592131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592131 = validateParameter(valid_592131, JString, required = false,
                                 default = nil)
  if valid_592131 != nil:
    section.add "X-Amz-SignedHeaders", valid_592131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592133: Call_UpdateGroupCertificateConfiguration_592121;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the Certificate expiry time for a group.
  ## 
  let valid = call_592133.validator(path, query, header, formData, body)
  let scheme = call_592133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592133.url(scheme.get, call_592133.host, call_592133.base,
                         call_592133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592133, url, valid)

proc call*(call_592134: Call_UpdateGroupCertificateConfiguration_592121;
          GroupId: string; body: JsonNode): Recallable =
  ## updateGroupCertificateConfiguration
  ## Updates the Certificate expiry time for a group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_592135 = newJObject()
  var body_592136 = newJObject()
  add(path_592135, "GroupId", newJString(GroupId))
  if body != nil:
    body_592136 = body
  result = call_592134.call(path_592135, nil, nil, nil, body_592136)

var updateGroupCertificateConfiguration* = Call_UpdateGroupCertificateConfiguration_592121(
    name: "updateGroupCertificateConfiguration", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_UpdateGroupCertificateConfiguration_592122, base: "/",
    url: url_UpdateGroupCertificateConfiguration_592123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupCertificateConfiguration_592107 = ref object of OpenApiRestCall_590348
proc url_GetGroupCertificateConfiguration_592109(protocol: Scheme; host: string;
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

proc validate_GetGroupCertificateConfiguration_592108(path: JsonNode;
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
  var valid_592110 = path.getOrDefault("GroupId")
  valid_592110 = validateParameter(valid_592110, JString, required = true,
                                 default = nil)
  if valid_592110 != nil:
    section.add "GroupId", valid_592110
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
  var valid_592111 = header.getOrDefault("X-Amz-Signature")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-Signature", valid_592111
  var valid_592112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592112 = validateParameter(valid_592112, JString, required = false,
                                 default = nil)
  if valid_592112 != nil:
    section.add "X-Amz-Content-Sha256", valid_592112
  var valid_592113 = header.getOrDefault("X-Amz-Date")
  valid_592113 = validateParameter(valid_592113, JString, required = false,
                                 default = nil)
  if valid_592113 != nil:
    section.add "X-Amz-Date", valid_592113
  var valid_592114 = header.getOrDefault("X-Amz-Credential")
  valid_592114 = validateParameter(valid_592114, JString, required = false,
                                 default = nil)
  if valid_592114 != nil:
    section.add "X-Amz-Credential", valid_592114
  var valid_592115 = header.getOrDefault("X-Amz-Security-Token")
  valid_592115 = validateParameter(valid_592115, JString, required = false,
                                 default = nil)
  if valid_592115 != nil:
    section.add "X-Amz-Security-Token", valid_592115
  var valid_592116 = header.getOrDefault("X-Amz-Algorithm")
  valid_592116 = validateParameter(valid_592116, JString, required = false,
                                 default = nil)
  if valid_592116 != nil:
    section.add "X-Amz-Algorithm", valid_592116
  var valid_592117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592117 = validateParameter(valid_592117, JString, required = false,
                                 default = nil)
  if valid_592117 != nil:
    section.add "X-Amz-SignedHeaders", valid_592117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592118: Call_GetGroupCertificateConfiguration_592107;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current configuration for the CA used by the group.
  ## 
  let valid = call_592118.validator(path, query, header, formData, body)
  let scheme = call_592118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592118.url(scheme.get, call_592118.host, call_592118.base,
                         call_592118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592118, url, valid)

proc call*(call_592119: Call_GetGroupCertificateConfiguration_592107;
          GroupId: string): Recallable =
  ## getGroupCertificateConfiguration
  ## Retrieves the current configuration for the CA used by the group.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_592120 = newJObject()
  add(path_592120, "GroupId", newJString(GroupId))
  result = call_592119.call(path_592120, nil, nil, nil, nil)

var getGroupCertificateConfiguration* = Call_GetGroupCertificateConfiguration_592107(
    name: "getGroupCertificateConfiguration", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/groups/{GroupId}/certificateauthorities/configuration/expiry",
    validator: validate_GetGroupCertificateConfiguration_592108, base: "/",
    url: url_GetGroupCertificateConfiguration_592109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroupVersion_592137 = ref object of OpenApiRestCall_590348
proc url_GetGroupVersion_592139(protocol: Scheme; host: string; base: string;
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

proc validate_GetGroupVersion_592138(path: JsonNode; query: JsonNode;
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
  var valid_592140 = path.getOrDefault("GroupVersionId")
  valid_592140 = validateParameter(valid_592140, JString, required = true,
                                 default = nil)
  if valid_592140 != nil:
    section.add "GroupVersionId", valid_592140
  var valid_592141 = path.getOrDefault("GroupId")
  valid_592141 = validateParameter(valid_592141, JString, required = true,
                                 default = nil)
  if valid_592141 != nil:
    section.add "GroupId", valid_592141
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
  var valid_592142 = header.getOrDefault("X-Amz-Signature")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-Signature", valid_592142
  var valid_592143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592143 = validateParameter(valid_592143, JString, required = false,
                                 default = nil)
  if valid_592143 != nil:
    section.add "X-Amz-Content-Sha256", valid_592143
  var valid_592144 = header.getOrDefault("X-Amz-Date")
  valid_592144 = validateParameter(valid_592144, JString, required = false,
                                 default = nil)
  if valid_592144 != nil:
    section.add "X-Amz-Date", valid_592144
  var valid_592145 = header.getOrDefault("X-Amz-Credential")
  valid_592145 = validateParameter(valid_592145, JString, required = false,
                                 default = nil)
  if valid_592145 != nil:
    section.add "X-Amz-Credential", valid_592145
  var valid_592146 = header.getOrDefault("X-Amz-Security-Token")
  valid_592146 = validateParameter(valid_592146, JString, required = false,
                                 default = nil)
  if valid_592146 != nil:
    section.add "X-Amz-Security-Token", valid_592146
  var valid_592147 = header.getOrDefault("X-Amz-Algorithm")
  valid_592147 = validateParameter(valid_592147, JString, required = false,
                                 default = nil)
  if valid_592147 != nil:
    section.add "X-Amz-Algorithm", valid_592147
  var valid_592148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592148 = validateParameter(valid_592148, JString, required = false,
                                 default = nil)
  if valid_592148 != nil:
    section.add "X-Amz-SignedHeaders", valid_592148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592149: Call_GetGroupVersion_592137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a group version.
  ## 
  let valid = call_592149.validator(path, query, header, formData, body)
  let scheme = call_592149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592149.url(scheme.get, call_592149.host, call_592149.base,
                         call_592149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592149, url, valid)

proc call*(call_592150: Call_GetGroupVersion_592137; GroupVersionId: string;
          GroupId: string): Recallable =
  ## getGroupVersion
  ## Retrieves information about a group version.
  ##   GroupVersionId: string (required)
  ##                 : The ID of the group version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListGroupVersions'' requests. If the version is the last one that was associated with a group, the value also maps to the ''LatestVersion'' property of the corresponding ''GroupInformation'' object.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  var path_592151 = newJObject()
  add(path_592151, "GroupVersionId", newJString(GroupVersionId))
  add(path_592151, "GroupId", newJString(GroupId))
  result = call_592150.call(path_592151, nil, nil, nil, nil)

var getGroupVersion* = Call_GetGroupVersion_592137(name: "getGroupVersion",
    meth: HttpMethod.HttpGet, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/versions/{GroupVersionId}",
    validator: validate_GetGroupVersion_592138, base: "/", url: url_GetGroupVersion_592139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggerDefinitionVersion_592152 = ref object of OpenApiRestCall_590348
proc url_GetLoggerDefinitionVersion_592154(protocol: Scheme; host: string;
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

proc validate_GetLoggerDefinitionVersion_592153(path: JsonNode; query: JsonNode;
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
  var valid_592155 = path.getOrDefault("LoggerDefinitionVersionId")
  valid_592155 = validateParameter(valid_592155, JString, required = true,
                                 default = nil)
  if valid_592155 != nil:
    section.add "LoggerDefinitionVersionId", valid_592155
  var valid_592156 = path.getOrDefault("LoggerDefinitionId")
  valid_592156 = validateParameter(valid_592156, JString, required = true,
                                 default = nil)
  if valid_592156 != nil:
    section.add "LoggerDefinitionId", valid_592156
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592157 = query.getOrDefault("NextToken")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "NextToken", valid_592157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592158 = header.getOrDefault("X-Amz-Signature")
  valid_592158 = validateParameter(valid_592158, JString, required = false,
                                 default = nil)
  if valid_592158 != nil:
    section.add "X-Amz-Signature", valid_592158
  var valid_592159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592159 = validateParameter(valid_592159, JString, required = false,
                                 default = nil)
  if valid_592159 != nil:
    section.add "X-Amz-Content-Sha256", valid_592159
  var valid_592160 = header.getOrDefault("X-Amz-Date")
  valid_592160 = validateParameter(valid_592160, JString, required = false,
                                 default = nil)
  if valid_592160 != nil:
    section.add "X-Amz-Date", valid_592160
  var valid_592161 = header.getOrDefault("X-Amz-Credential")
  valid_592161 = validateParameter(valid_592161, JString, required = false,
                                 default = nil)
  if valid_592161 != nil:
    section.add "X-Amz-Credential", valid_592161
  var valid_592162 = header.getOrDefault("X-Amz-Security-Token")
  valid_592162 = validateParameter(valid_592162, JString, required = false,
                                 default = nil)
  if valid_592162 != nil:
    section.add "X-Amz-Security-Token", valid_592162
  var valid_592163 = header.getOrDefault("X-Amz-Algorithm")
  valid_592163 = validateParameter(valid_592163, JString, required = false,
                                 default = nil)
  if valid_592163 != nil:
    section.add "X-Amz-Algorithm", valid_592163
  var valid_592164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592164 = validateParameter(valid_592164, JString, required = false,
                                 default = nil)
  if valid_592164 != nil:
    section.add "X-Amz-SignedHeaders", valid_592164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592165: Call_GetLoggerDefinitionVersion_592152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a logger definition version.
  ## 
  let valid = call_592165.validator(path, query, header, formData, body)
  let scheme = call_592165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592165.url(scheme.get, call_592165.host, call_592165.base,
                         call_592165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592165, url, valid)

proc call*(call_592166: Call_GetLoggerDefinitionVersion_592152;
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
  var path_592167 = newJObject()
  var query_592168 = newJObject()
  add(path_592167, "LoggerDefinitionVersionId",
      newJString(LoggerDefinitionVersionId))
  add(query_592168, "NextToken", newJString(NextToken))
  add(path_592167, "LoggerDefinitionId", newJString(LoggerDefinitionId))
  result = call_592166.call(path_592167, query_592168, nil, nil, nil)

var getLoggerDefinitionVersion* = Call_GetLoggerDefinitionVersion_592152(
    name: "getLoggerDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/loggers/{LoggerDefinitionId}/versions/{LoggerDefinitionVersionId}",
    validator: validate_GetLoggerDefinitionVersion_592153, base: "/",
    url: url_GetLoggerDefinitionVersion_592154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceDefinitionVersion_592169 = ref object of OpenApiRestCall_590348
proc url_GetResourceDefinitionVersion_592171(protocol: Scheme; host: string;
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

proc validate_GetResourceDefinitionVersion_592170(path: JsonNode; query: JsonNode;
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
  var valid_592172 = path.getOrDefault("ResourceDefinitionVersionId")
  valid_592172 = validateParameter(valid_592172, JString, required = true,
                                 default = nil)
  if valid_592172 != nil:
    section.add "ResourceDefinitionVersionId", valid_592172
  var valid_592173 = path.getOrDefault("ResourceDefinitionId")
  valid_592173 = validateParameter(valid_592173, JString, required = true,
                                 default = nil)
  if valid_592173 != nil:
    section.add "ResourceDefinitionId", valid_592173
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
  var valid_592174 = header.getOrDefault("X-Amz-Signature")
  valid_592174 = validateParameter(valid_592174, JString, required = false,
                                 default = nil)
  if valid_592174 != nil:
    section.add "X-Amz-Signature", valid_592174
  var valid_592175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592175 = validateParameter(valid_592175, JString, required = false,
                                 default = nil)
  if valid_592175 != nil:
    section.add "X-Amz-Content-Sha256", valid_592175
  var valid_592176 = header.getOrDefault("X-Amz-Date")
  valid_592176 = validateParameter(valid_592176, JString, required = false,
                                 default = nil)
  if valid_592176 != nil:
    section.add "X-Amz-Date", valid_592176
  var valid_592177 = header.getOrDefault("X-Amz-Credential")
  valid_592177 = validateParameter(valid_592177, JString, required = false,
                                 default = nil)
  if valid_592177 != nil:
    section.add "X-Amz-Credential", valid_592177
  var valid_592178 = header.getOrDefault("X-Amz-Security-Token")
  valid_592178 = validateParameter(valid_592178, JString, required = false,
                                 default = nil)
  if valid_592178 != nil:
    section.add "X-Amz-Security-Token", valid_592178
  var valid_592179 = header.getOrDefault("X-Amz-Algorithm")
  valid_592179 = validateParameter(valid_592179, JString, required = false,
                                 default = nil)
  if valid_592179 != nil:
    section.add "X-Amz-Algorithm", valid_592179
  var valid_592180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592180 = validateParameter(valid_592180, JString, required = false,
                                 default = nil)
  if valid_592180 != nil:
    section.add "X-Amz-SignedHeaders", valid_592180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592181: Call_GetResourceDefinitionVersion_592169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ## 
  let valid = call_592181.validator(path, query, header, formData, body)
  let scheme = call_592181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592181.url(scheme.get, call_592181.host, call_592181.base,
                         call_592181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592181, url, valid)

proc call*(call_592182: Call_GetResourceDefinitionVersion_592169;
          ResourceDefinitionVersionId: string; ResourceDefinitionId: string): Recallable =
  ## getResourceDefinitionVersion
  ## Retrieves information about a resource definition version, including which resources are included in the version.
  ##   ResourceDefinitionVersionId: string (required)
  ##                              : The ID of the resource definition version. This value maps to the ''Version'' property of the corresponding ''VersionInformation'' object, which is returned by ''ListResourceDefinitionVersions'' requests. If the version is the last one that was associated with a resource definition, the value also maps to the ''LatestVersion'' property of the corresponding ''DefinitionInformation'' object.
  ##   ResourceDefinitionId: string (required)
  ##                       : The ID of the resource definition.
  var path_592183 = newJObject()
  add(path_592183, "ResourceDefinitionVersionId",
      newJString(ResourceDefinitionVersionId))
  add(path_592183, "ResourceDefinitionId", newJString(ResourceDefinitionId))
  result = call_592182.call(path_592183, nil, nil, nil, nil)

var getResourceDefinitionVersion* = Call_GetResourceDefinitionVersion_592169(
    name: "getResourceDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/resources/{ResourceDefinitionId}/versions/{ResourceDefinitionVersionId}",
    validator: validate_GetResourceDefinitionVersion_592170, base: "/",
    url: url_GetResourceDefinitionVersion_592171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscriptionDefinitionVersion_592184 = ref object of OpenApiRestCall_590348
proc url_GetSubscriptionDefinitionVersion_592186(protocol: Scheme; host: string;
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

proc validate_GetSubscriptionDefinitionVersion_592185(path: JsonNode;
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
  var valid_592187 = path.getOrDefault("SubscriptionDefinitionVersionId")
  valid_592187 = validateParameter(valid_592187, JString, required = true,
                                 default = nil)
  if valid_592187 != nil:
    section.add "SubscriptionDefinitionVersionId", valid_592187
  var valid_592188 = path.getOrDefault("SubscriptionDefinitionId")
  valid_592188 = validateParameter(valid_592188, JString, required = true,
                                 default = nil)
  if valid_592188 != nil:
    section.add "SubscriptionDefinitionId", valid_592188
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592189 = query.getOrDefault("NextToken")
  valid_592189 = validateParameter(valid_592189, JString, required = false,
                                 default = nil)
  if valid_592189 != nil:
    section.add "NextToken", valid_592189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592190 = header.getOrDefault("X-Amz-Signature")
  valid_592190 = validateParameter(valid_592190, JString, required = false,
                                 default = nil)
  if valid_592190 != nil:
    section.add "X-Amz-Signature", valid_592190
  var valid_592191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592191 = validateParameter(valid_592191, JString, required = false,
                                 default = nil)
  if valid_592191 != nil:
    section.add "X-Amz-Content-Sha256", valid_592191
  var valid_592192 = header.getOrDefault("X-Amz-Date")
  valid_592192 = validateParameter(valid_592192, JString, required = false,
                                 default = nil)
  if valid_592192 != nil:
    section.add "X-Amz-Date", valid_592192
  var valid_592193 = header.getOrDefault("X-Amz-Credential")
  valid_592193 = validateParameter(valid_592193, JString, required = false,
                                 default = nil)
  if valid_592193 != nil:
    section.add "X-Amz-Credential", valid_592193
  var valid_592194 = header.getOrDefault("X-Amz-Security-Token")
  valid_592194 = validateParameter(valid_592194, JString, required = false,
                                 default = nil)
  if valid_592194 != nil:
    section.add "X-Amz-Security-Token", valid_592194
  var valid_592195 = header.getOrDefault("X-Amz-Algorithm")
  valid_592195 = validateParameter(valid_592195, JString, required = false,
                                 default = nil)
  if valid_592195 != nil:
    section.add "X-Amz-Algorithm", valid_592195
  var valid_592196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592196 = validateParameter(valid_592196, JString, required = false,
                                 default = nil)
  if valid_592196 != nil:
    section.add "X-Amz-SignedHeaders", valid_592196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592197: Call_GetSubscriptionDefinitionVersion_592184;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a subscription definition version.
  ## 
  let valid = call_592197.validator(path, query, header, formData, body)
  let scheme = call_592197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592197.url(scheme.get, call_592197.host, call_592197.base,
                         call_592197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592197, url, valid)

proc call*(call_592198: Call_GetSubscriptionDefinitionVersion_592184;
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
  var path_592199 = newJObject()
  var query_592200 = newJObject()
  add(path_592199, "SubscriptionDefinitionVersionId",
      newJString(SubscriptionDefinitionVersionId))
  add(query_592200, "NextToken", newJString(NextToken))
  add(path_592199, "SubscriptionDefinitionId",
      newJString(SubscriptionDefinitionId))
  result = call_592198.call(path_592199, query_592200, nil, nil, nil)

var getSubscriptionDefinitionVersion* = Call_GetSubscriptionDefinitionVersion_592184(
    name: "getSubscriptionDefinitionVersion", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/definition/subscriptions/{SubscriptionDefinitionId}/versions/{SubscriptionDefinitionVersionId}",
    validator: validate_GetSubscriptionDefinitionVersion_592185, base: "/",
    url: url_GetSubscriptionDefinitionVersion_592186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeploymentDetailedReports_592201 = ref object of OpenApiRestCall_590348
proc url_ListBulkDeploymentDetailedReports_592203(protocol: Scheme; host: string;
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

proc validate_ListBulkDeploymentDetailedReports_592202(path: JsonNode;
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
  var valid_592204 = path.getOrDefault("BulkDeploymentId")
  valid_592204 = validateParameter(valid_592204, JString, required = true,
                                 default = nil)
  if valid_592204 != nil:
    section.add "BulkDeploymentId", valid_592204
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: JString
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  section = newJObject()
  var valid_592205 = query.getOrDefault("MaxResults")
  valid_592205 = validateParameter(valid_592205, JString, required = false,
                                 default = nil)
  if valid_592205 != nil:
    section.add "MaxResults", valid_592205
  var valid_592206 = query.getOrDefault("NextToken")
  valid_592206 = validateParameter(valid_592206, JString, required = false,
                                 default = nil)
  if valid_592206 != nil:
    section.add "NextToken", valid_592206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592207 = header.getOrDefault("X-Amz-Signature")
  valid_592207 = validateParameter(valid_592207, JString, required = false,
                                 default = nil)
  if valid_592207 != nil:
    section.add "X-Amz-Signature", valid_592207
  var valid_592208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592208 = validateParameter(valid_592208, JString, required = false,
                                 default = nil)
  if valid_592208 != nil:
    section.add "X-Amz-Content-Sha256", valid_592208
  var valid_592209 = header.getOrDefault("X-Amz-Date")
  valid_592209 = validateParameter(valid_592209, JString, required = false,
                                 default = nil)
  if valid_592209 != nil:
    section.add "X-Amz-Date", valid_592209
  var valid_592210 = header.getOrDefault("X-Amz-Credential")
  valid_592210 = validateParameter(valid_592210, JString, required = false,
                                 default = nil)
  if valid_592210 != nil:
    section.add "X-Amz-Credential", valid_592210
  var valid_592211 = header.getOrDefault("X-Amz-Security-Token")
  valid_592211 = validateParameter(valid_592211, JString, required = false,
                                 default = nil)
  if valid_592211 != nil:
    section.add "X-Amz-Security-Token", valid_592211
  var valid_592212 = header.getOrDefault("X-Amz-Algorithm")
  valid_592212 = validateParameter(valid_592212, JString, required = false,
                                 default = nil)
  if valid_592212 != nil:
    section.add "X-Amz-Algorithm", valid_592212
  var valid_592213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592213 = validateParameter(valid_592213, JString, required = false,
                                 default = nil)
  if valid_592213 != nil:
    section.add "X-Amz-SignedHeaders", valid_592213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592214: Call_ListBulkDeploymentDetailedReports_592201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ## 
  let valid = call_592214.validator(path, query, header, formData, body)
  let scheme = call_592214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592214.url(scheme.get, call_592214.host, call_592214.base,
                         call_592214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592214, url, valid)

proc call*(call_592215: Call_ListBulkDeploymentDetailedReports_592201;
          BulkDeploymentId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBulkDeploymentDetailedReports
  ## Gets a paginated list of the deployments that have been started in a bulk deployment operation, and their current deployment status.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_592216 = newJObject()
  var query_592217 = newJObject()
  add(query_592217, "MaxResults", newJString(MaxResults))
  add(query_592217, "NextToken", newJString(NextToken))
  add(path_592216, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_592215.call(path_592216, query_592217, nil, nil, nil)

var listBulkDeploymentDetailedReports* = Call_ListBulkDeploymentDetailedReports_592201(
    name: "listBulkDeploymentDetailedReports", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/detailed-reports",
    validator: validate_ListBulkDeploymentDetailedReports_592202, base: "/",
    url: url_ListBulkDeploymentDetailedReports_592203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBulkDeployment_592233 = ref object of OpenApiRestCall_590348
proc url_StartBulkDeployment_592235(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartBulkDeployment_592234(path: JsonNode; query: JsonNode;
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
  var valid_592236 = header.getOrDefault("X-Amz-Signature")
  valid_592236 = validateParameter(valid_592236, JString, required = false,
                                 default = nil)
  if valid_592236 != nil:
    section.add "X-Amz-Signature", valid_592236
  var valid_592237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592237 = validateParameter(valid_592237, JString, required = false,
                                 default = nil)
  if valid_592237 != nil:
    section.add "X-Amz-Content-Sha256", valid_592237
  var valid_592238 = header.getOrDefault("X-Amz-Date")
  valid_592238 = validateParameter(valid_592238, JString, required = false,
                                 default = nil)
  if valid_592238 != nil:
    section.add "X-Amz-Date", valid_592238
  var valid_592239 = header.getOrDefault("X-Amz-Credential")
  valid_592239 = validateParameter(valid_592239, JString, required = false,
                                 default = nil)
  if valid_592239 != nil:
    section.add "X-Amz-Credential", valid_592239
  var valid_592240 = header.getOrDefault("X-Amzn-Client-Token")
  valid_592240 = validateParameter(valid_592240, JString, required = false,
                                 default = nil)
  if valid_592240 != nil:
    section.add "X-Amzn-Client-Token", valid_592240
  var valid_592241 = header.getOrDefault("X-Amz-Security-Token")
  valid_592241 = validateParameter(valid_592241, JString, required = false,
                                 default = nil)
  if valid_592241 != nil:
    section.add "X-Amz-Security-Token", valid_592241
  var valid_592242 = header.getOrDefault("X-Amz-Algorithm")
  valid_592242 = validateParameter(valid_592242, JString, required = false,
                                 default = nil)
  if valid_592242 != nil:
    section.add "X-Amz-Algorithm", valid_592242
  var valid_592243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592243 = validateParameter(valid_592243, JString, required = false,
                                 default = nil)
  if valid_592243 != nil:
    section.add "X-Amz-SignedHeaders", valid_592243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592245: Call_StartBulkDeployment_592233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ## 
  let valid = call_592245.validator(path, query, header, formData, body)
  let scheme = call_592245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592245.url(scheme.get, call_592245.host, call_592245.base,
                         call_592245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592245, url, valid)

proc call*(call_592246: Call_StartBulkDeployment_592233; body: JsonNode): Recallable =
  ## startBulkDeployment
  ## Deploys multiple groups in one operation. This action starts the bulk deployment of a specified set of group versions. Each group version deployment will be triggered with an adaptive rate that has a fixed upper limit. We recommend that you include an ''X-Amzn-Client-Token'' token in every ''StartBulkDeployment'' request. These requests are idempotent with respect to the token and the request parameters.
  ##   body: JObject (required)
  var body_592247 = newJObject()
  if body != nil:
    body_592247 = body
  result = call_592246.call(nil, nil, nil, nil, body_592247)

var startBulkDeployment* = Call_StartBulkDeployment_592233(
    name: "startBulkDeployment", meth: HttpMethod.HttpPost,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_StartBulkDeployment_592234, base: "/",
    url: url_StartBulkDeployment_592235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBulkDeployments_592218 = ref object of OpenApiRestCall_590348
proc url_ListBulkDeployments_592220(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBulkDeployments_592219(path: JsonNode; query: JsonNode;
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
  var valid_592221 = query.getOrDefault("MaxResults")
  valid_592221 = validateParameter(valid_592221, JString, required = false,
                                 default = nil)
  if valid_592221 != nil:
    section.add "MaxResults", valid_592221
  var valid_592222 = query.getOrDefault("NextToken")
  valid_592222 = validateParameter(valid_592222, JString, required = false,
                                 default = nil)
  if valid_592222 != nil:
    section.add "NextToken", valid_592222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592223 = header.getOrDefault("X-Amz-Signature")
  valid_592223 = validateParameter(valid_592223, JString, required = false,
                                 default = nil)
  if valid_592223 != nil:
    section.add "X-Amz-Signature", valid_592223
  var valid_592224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592224 = validateParameter(valid_592224, JString, required = false,
                                 default = nil)
  if valid_592224 != nil:
    section.add "X-Amz-Content-Sha256", valid_592224
  var valid_592225 = header.getOrDefault("X-Amz-Date")
  valid_592225 = validateParameter(valid_592225, JString, required = false,
                                 default = nil)
  if valid_592225 != nil:
    section.add "X-Amz-Date", valid_592225
  var valid_592226 = header.getOrDefault("X-Amz-Credential")
  valid_592226 = validateParameter(valid_592226, JString, required = false,
                                 default = nil)
  if valid_592226 != nil:
    section.add "X-Amz-Credential", valid_592226
  var valid_592227 = header.getOrDefault("X-Amz-Security-Token")
  valid_592227 = validateParameter(valid_592227, JString, required = false,
                                 default = nil)
  if valid_592227 != nil:
    section.add "X-Amz-Security-Token", valid_592227
  var valid_592228 = header.getOrDefault("X-Amz-Algorithm")
  valid_592228 = validateParameter(valid_592228, JString, required = false,
                                 default = nil)
  if valid_592228 != nil:
    section.add "X-Amz-Algorithm", valid_592228
  var valid_592229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592229 = validateParameter(valid_592229, JString, required = false,
                                 default = nil)
  if valid_592229 != nil:
    section.add "X-Amz-SignedHeaders", valid_592229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592230: Call_ListBulkDeployments_592218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of bulk deployments.
  ## 
  let valid = call_592230.validator(path, query, header, formData, body)
  let scheme = call_592230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592230.url(scheme.get, call_592230.host, call_592230.base,
                         call_592230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592230, url, valid)

proc call*(call_592231: Call_ListBulkDeployments_592218; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## listBulkDeployments
  ## Returns a list of bulk deployments.
  ##   MaxResults: string
  ##             : The maximum number of results to be returned per request.
  ##   NextToken: string
  ##            : The token for the next set of results, or ''null'' if there are no additional results.
  var query_592232 = newJObject()
  add(query_592232, "MaxResults", newJString(MaxResults))
  add(query_592232, "NextToken", newJString(NextToken))
  result = call_592231.call(nil, query_592232, nil, nil, nil)

var listBulkDeployments* = Call_ListBulkDeployments_592218(
    name: "listBulkDeployments", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/greengrass/bulk/deployments",
    validator: validate_ListBulkDeployments_592219, base: "/",
    url: url_ListBulkDeployments_592220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592262 = ref object of OpenApiRestCall_590348
proc url_TagResource_592264(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_592263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592265 = path.getOrDefault("resource-arn")
  valid_592265 = validateParameter(valid_592265, JString, required = true,
                                 default = nil)
  if valid_592265 != nil:
    section.add "resource-arn", valid_592265
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
  var valid_592266 = header.getOrDefault("X-Amz-Signature")
  valid_592266 = validateParameter(valid_592266, JString, required = false,
                                 default = nil)
  if valid_592266 != nil:
    section.add "X-Amz-Signature", valid_592266
  var valid_592267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592267 = validateParameter(valid_592267, JString, required = false,
                                 default = nil)
  if valid_592267 != nil:
    section.add "X-Amz-Content-Sha256", valid_592267
  var valid_592268 = header.getOrDefault("X-Amz-Date")
  valid_592268 = validateParameter(valid_592268, JString, required = false,
                                 default = nil)
  if valid_592268 != nil:
    section.add "X-Amz-Date", valid_592268
  var valid_592269 = header.getOrDefault("X-Amz-Credential")
  valid_592269 = validateParameter(valid_592269, JString, required = false,
                                 default = nil)
  if valid_592269 != nil:
    section.add "X-Amz-Credential", valid_592269
  var valid_592270 = header.getOrDefault("X-Amz-Security-Token")
  valid_592270 = validateParameter(valid_592270, JString, required = false,
                                 default = nil)
  if valid_592270 != nil:
    section.add "X-Amz-Security-Token", valid_592270
  var valid_592271 = header.getOrDefault("X-Amz-Algorithm")
  valid_592271 = validateParameter(valid_592271, JString, required = false,
                                 default = nil)
  if valid_592271 != nil:
    section.add "X-Amz-Algorithm", valid_592271
  var valid_592272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592272 = validateParameter(valid_592272, JString, required = false,
                                 default = nil)
  if valid_592272 != nil:
    section.add "X-Amz-SignedHeaders", valid_592272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592274: Call_TagResource_592262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ## 
  let valid = call_592274.validator(path, query, header, formData, body)
  let scheme = call_592274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592274.url(scheme.get, call_592274.host, call_592274.base,
                         call_592274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592274, url, valid)

proc call*(call_592275: Call_TagResource_592262; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a Greengrass resource. Valid resources are 'Group', 'ConnectorDefinition', 'CoreDefinition', 'DeviceDefinition', 'FunctionDefinition', 'LoggerDefinition', 'SubscriptionDefinition', 'ResourceDefinition', and 'BulkDeployment'.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_592276 = newJObject()
  var body_592277 = newJObject()
  add(path_592276, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_592277 = body
  result = call_592275.call(path_592276, nil, nil, nil, body_592277)

var tagResource* = Call_TagResource_592262(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "greengrass.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_592263,
                                        base: "/", url: url_TagResource_592264,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592248 = ref object of OpenApiRestCall_590348
proc url_ListTagsForResource_592250(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_592249(path: JsonNode; query: JsonNode;
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
  var valid_592251 = path.getOrDefault("resource-arn")
  valid_592251 = validateParameter(valid_592251, JString, required = true,
                                 default = nil)
  if valid_592251 != nil:
    section.add "resource-arn", valid_592251
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
  var valid_592252 = header.getOrDefault("X-Amz-Signature")
  valid_592252 = validateParameter(valid_592252, JString, required = false,
                                 default = nil)
  if valid_592252 != nil:
    section.add "X-Amz-Signature", valid_592252
  var valid_592253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592253 = validateParameter(valid_592253, JString, required = false,
                                 default = nil)
  if valid_592253 != nil:
    section.add "X-Amz-Content-Sha256", valid_592253
  var valid_592254 = header.getOrDefault("X-Amz-Date")
  valid_592254 = validateParameter(valid_592254, JString, required = false,
                                 default = nil)
  if valid_592254 != nil:
    section.add "X-Amz-Date", valid_592254
  var valid_592255 = header.getOrDefault("X-Amz-Credential")
  valid_592255 = validateParameter(valid_592255, JString, required = false,
                                 default = nil)
  if valid_592255 != nil:
    section.add "X-Amz-Credential", valid_592255
  var valid_592256 = header.getOrDefault("X-Amz-Security-Token")
  valid_592256 = validateParameter(valid_592256, JString, required = false,
                                 default = nil)
  if valid_592256 != nil:
    section.add "X-Amz-Security-Token", valid_592256
  var valid_592257 = header.getOrDefault("X-Amz-Algorithm")
  valid_592257 = validateParameter(valid_592257, JString, required = false,
                                 default = nil)
  if valid_592257 != nil:
    section.add "X-Amz-Algorithm", valid_592257
  var valid_592258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592258 = validateParameter(valid_592258, JString, required = false,
                                 default = nil)
  if valid_592258 != nil:
    section.add "X-Amz-SignedHeaders", valid_592258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592259: Call_ListTagsForResource_592248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of resource tags for a resource arn.
  ## 
  let valid = call_592259.validator(path, query, header, formData, body)
  let scheme = call_592259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592259.url(scheme.get, call_592259.host, call_592259.base,
                         call_592259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592259, url, valid)

proc call*(call_592260: Call_ListTagsForResource_592248; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves a list of resource tags for a resource arn.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_592261 = newJObject()
  add(path_592261, "resource-arn", newJString(resourceArn))
  result = call_592260.call(path_592261, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_592248(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "greengrass.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_592249, base: "/",
    url: url_ListTagsForResource_592250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetDeployments_592278 = ref object of OpenApiRestCall_590348
proc url_ResetDeployments_592280(protocol: Scheme; host: string; base: string;
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

proc validate_ResetDeployments_592279(path: JsonNode; query: JsonNode;
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
  var valid_592281 = path.getOrDefault("GroupId")
  valid_592281 = validateParameter(valid_592281, JString, required = true,
                                 default = nil)
  if valid_592281 != nil:
    section.add "GroupId", valid_592281
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
  var valid_592282 = header.getOrDefault("X-Amz-Signature")
  valid_592282 = validateParameter(valid_592282, JString, required = false,
                                 default = nil)
  if valid_592282 != nil:
    section.add "X-Amz-Signature", valid_592282
  var valid_592283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592283 = validateParameter(valid_592283, JString, required = false,
                                 default = nil)
  if valid_592283 != nil:
    section.add "X-Amz-Content-Sha256", valid_592283
  var valid_592284 = header.getOrDefault("X-Amz-Date")
  valid_592284 = validateParameter(valid_592284, JString, required = false,
                                 default = nil)
  if valid_592284 != nil:
    section.add "X-Amz-Date", valid_592284
  var valid_592285 = header.getOrDefault("X-Amz-Credential")
  valid_592285 = validateParameter(valid_592285, JString, required = false,
                                 default = nil)
  if valid_592285 != nil:
    section.add "X-Amz-Credential", valid_592285
  var valid_592286 = header.getOrDefault("X-Amzn-Client-Token")
  valid_592286 = validateParameter(valid_592286, JString, required = false,
                                 default = nil)
  if valid_592286 != nil:
    section.add "X-Amzn-Client-Token", valid_592286
  var valid_592287 = header.getOrDefault("X-Amz-Security-Token")
  valid_592287 = validateParameter(valid_592287, JString, required = false,
                                 default = nil)
  if valid_592287 != nil:
    section.add "X-Amz-Security-Token", valid_592287
  var valid_592288 = header.getOrDefault("X-Amz-Algorithm")
  valid_592288 = validateParameter(valid_592288, JString, required = false,
                                 default = nil)
  if valid_592288 != nil:
    section.add "X-Amz-Algorithm", valid_592288
  var valid_592289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592289 = validateParameter(valid_592289, JString, required = false,
                                 default = nil)
  if valid_592289 != nil:
    section.add "X-Amz-SignedHeaders", valid_592289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592291: Call_ResetDeployments_592278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a group's deployments.
  ## 
  let valid = call_592291.validator(path, query, header, formData, body)
  let scheme = call_592291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592291.url(scheme.get, call_592291.host, call_592291.base,
                         call_592291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592291, url, valid)

proc call*(call_592292: Call_ResetDeployments_592278; GroupId: string; body: JsonNode): Recallable =
  ## resetDeployments
  ## Resets a group's deployments.
  ##   GroupId: string (required)
  ##          : The ID of the Greengrass group.
  ##   body: JObject (required)
  var path_592293 = newJObject()
  var body_592294 = newJObject()
  add(path_592293, "GroupId", newJString(GroupId))
  if body != nil:
    body_592294 = body
  result = call_592292.call(path_592293, nil, nil, nil, body_592294)

var resetDeployments* = Call_ResetDeployments_592278(name: "resetDeployments",
    meth: HttpMethod.HttpPost, host: "greengrass.amazonaws.com",
    route: "/greengrass/groups/{GroupId}/deployments/$reset",
    validator: validate_ResetDeployments_592279, base: "/",
    url: url_ResetDeployments_592280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBulkDeployment_592295 = ref object of OpenApiRestCall_590348
proc url_StopBulkDeployment_592297(protocol: Scheme; host: string; base: string;
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

proc validate_StopBulkDeployment_592296(path: JsonNode; query: JsonNode;
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
  var valid_592298 = path.getOrDefault("BulkDeploymentId")
  valid_592298 = validateParameter(valid_592298, JString, required = true,
                                 default = nil)
  if valid_592298 != nil:
    section.add "BulkDeploymentId", valid_592298
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
  var valid_592299 = header.getOrDefault("X-Amz-Signature")
  valid_592299 = validateParameter(valid_592299, JString, required = false,
                                 default = nil)
  if valid_592299 != nil:
    section.add "X-Amz-Signature", valid_592299
  var valid_592300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592300 = validateParameter(valid_592300, JString, required = false,
                                 default = nil)
  if valid_592300 != nil:
    section.add "X-Amz-Content-Sha256", valid_592300
  var valid_592301 = header.getOrDefault("X-Amz-Date")
  valid_592301 = validateParameter(valid_592301, JString, required = false,
                                 default = nil)
  if valid_592301 != nil:
    section.add "X-Amz-Date", valid_592301
  var valid_592302 = header.getOrDefault("X-Amz-Credential")
  valid_592302 = validateParameter(valid_592302, JString, required = false,
                                 default = nil)
  if valid_592302 != nil:
    section.add "X-Amz-Credential", valid_592302
  var valid_592303 = header.getOrDefault("X-Amz-Security-Token")
  valid_592303 = validateParameter(valid_592303, JString, required = false,
                                 default = nil)
  if valid_592303 != nil:
    section.add "X-Amz-Security-Token", valid_592303
  var valid_592304 = header.getOrDefault("X-Amz-Algorithm")
  valid_592304 = validateParameter(valid_592304, JString, required = false,
                                 default = nil)
  if valid_592304 != nil:
    section.add "X-Amz-Algorithm", valid_592304
  var valid_592305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592305 = validateParameter(valid_592305, JString, required = false,
                                 default = nil)
  if valid_592305 != nil:
    section.add "X-Amz-SignedHeaders", valid_592305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592306: Call_StopBulkDeployment_592295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ## 
  let valid = call_592306.validator(path, query, header, formData, body)
  let scheme = call_592306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592306.url(scheme.get, call_592306.host, call_592306.base,
                         call_592306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592306, url, valid)

proc call*(call_592307: Call_StopBulkDeployment_592295; BulkDeploymentId: string): Recallable =
  ## stopBulkDeployment
  ## Stops the execution of a bulk deployment. This action returns a status of ''Stopping'' until the deployment is stopped. You cannot start a new bulk deployment while a previous deployment is in the ''Stopping'' state. This action doesn't rollback completed deployments or cancel pending deployments.
  ##   BulkDeploymentId: string (required)
  ##                   : The ID of the bulk deployment.
  var path_592308 = newJObject()
  add(path_592308, "BulkDeploymentId", newJString(BulkDeploymentId))
  result = call_592307.call(path_592308, nil, nil, nil, nil)

var stopBulkDeployment* = Call_StopBulkDeployment_592295(
    name: "stopBulkDeployment", meth: HttpMethod.HttpPut,
    host: "greengrass.amazonaws.com",
    route: "/greengrass/bulk/deployments/{BulkDeploymentId}/$stop",
    validator: validate_StopBulkDeployment_592296, base: "/",
    url: url_StopBulkDeployment_592297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592309 = ref object of OpenApiRestCall_590348
proc url_UntagResource_592311(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_592310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592312 = path.getOrDefault("resource-arn")
  valid_592312 = validateParameter(valid_592312, JString, required = true,
                                 default = nil)
  if valid_592312 != nil:
    section.add "resource-arn", valid_592312
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_592313 = query.getOrDefault("tagKeys")
  valid_592313 = validateParameter(valid_592313, JArray, required = true, default = nil)
  if valid_592313 != nil:
    section.add "tagKeys", valid_592313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592314 = header.getOrDefault("X-Amz-Signature")
  valid_592314 = validateParameter(valid_592314, JString, required = false,
                                 default = nil)
  if valid_592314 != nil:
    section.add "X-Amz-Signature", valid_592314
  var valid_592315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592315 = validateParameter(valid_592315, JString, required = false,
                                 default = nil)
  if valid_592315 != nil:
    section.add "X-Amz-Content-Sha256", valid_592315
  var valid_592316 = header.getOrDefault("X-Amz-Date")
  valid_592316 = validateParameter(valid_592316, JString, required = false,
                                 default = nil)
  if valid_592316 != nil:
    section.add "X-Amz-Date", valid_592316
  var valid_592317 = header.getOrDefault("X-Amz-Credential")
  valid_592317 = validateParameter(valid_592317, JString, required = false,
                                 default = nil)
  if valid_592317 != nil:
    section.add "X-Amz-Credential", valid_592317
  var valid_592318 = header.getOrDefault("X-Amz-Security-Token")
  valid_592318 = validateParameter(valid_592318, JString, required = false,
                                 default = nil)
  if valid_592318 != nil:
    section.add "X-Amz-Security-Token", valid_592318
  var valid_592319 = header.getOrDefault("X-Amz-Algorithm")
  valid_592319 = validateParameter(valid_592319, JString, required = false,
                                 default = nil)
  if valid_592319 != nil:
    section.add "X-Amz-Algorithm", valid_592319
  var valid_592320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592320 = validateParameter(valid_592320, JString, required = false,
                                 default = nil)
  if valid_592320 != nil:
    section.add "X-Amz-SignedHeaders", valid_592320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592321: Call_UntagResource_592309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove resource tags from a Greengrass Resource.
  ## 
  let valid = call_592321.validator(path, query, header, formData, body)
  let scheme = call_592321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592321.url(scheme.get, call_592321.host, call_592321.base,
                         call_592321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592321, url, valid)

proc call*(call_592322: Call_UntagResource_592309; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove resource tags from a Greengrass Resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : An array of tag keys to delete
  var path_592323 = newJObject()
  var query_592324 = newJObject()
  add(path_592323, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_592324.add "tagKeys", tagKeys
  result = call_592322.call(path_592323, query_592324, nil, nil, nil)

var untagResource* = Call_UntagResource_592309(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "greengrass.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_592310,
    base: "/", url: url_UntagResource_592311, schemes: {Scheme.Https, Scheme.Http})
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
