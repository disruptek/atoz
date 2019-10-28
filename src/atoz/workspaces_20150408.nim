
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon WorkSpaces
## version: 2015-04-08
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon WorkSpaces Service</fullname> <p>Amazon WorkSpaces enables you to provision virtual, cloud-based Microsoft Windows and Amazon Linux desktops for your users.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/workspaces/
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "workspaces.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workspaces.ap-southeast-1.amazonaws.com",
                           "us-west-2": "workspaces.us-west-2.amazonaws.com",
                           "eu-west-2": "workspaces.eu-west-2.amazonaws.com", "ap-northeast-3": "workspaces.ap-northeast-3.amazonaws.com", "eu-central-1": "workspaces.eu-central-1.amazonaws.com",
                           "us-east-2": "workspaces.us-east-2.amazonaws.com",
                           "us-east-1": "workspaces.us-east-1.amazonaws.com", "cn-northwest-1": "workspaces.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "workspaces.ap-south-1.amazonaws.com",
                           "eu-north-1": "workspaces.eu-north-1.amazonaws.com", "ap-northeast-2": "workspaces.ap-northeast-2.amazonaws.com",
                           "us-west-1": "workspaces.us-west-1.amazonaws.com", "us-gov-east-1": "workspaces.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "workspaces.eu-west-3.amazonaws.com", "cn-north-1": "workspaces.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "workspaces.sa-east-1.amazonaws.com",
                           "eu-west-1": "workspaces.eu-west-1.amazonaws.com", "us-gov-west-1": "workspaces.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workspaces.ap-southeast-2.amazonaws.com", "ca-central-1": "workspaces.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "workspaces.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "workspaces.ap-southeast-1.amazonaws.com",
      "us-west-2": "workspaces.us-west-2.amazonaws.com",
      "eu-west-2": "workspaces.eu-west-2.amazonaws.com",
      "ap-northeast-3": "workspaces.ap-northeast-3.amazonaws.com",
      "eu-central-1": "workspaces.eu-central-1.amazonaws.com",
      "us-east-2": "workspaces.us-east-2.amazonaws.com",
      "us-east-1": "workspaces.us-east-1.amazonaws.com",
      "cn-northwest-1": "workspaces.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "workspaces.ap-south-1.amazonaws.com",
      "eu-north-1": "workspaces.eu-north-1.amazonaws.com",
      "ap-northeast-2": "workspaces.ap-northeast-2.amazonaws.com",
      "us-west-1": "workspaces.us-west-1.amazonaws.com",
      "us-gov-east-1": "workspaces.us-gov-east-1.amazonaws.com",
      "eu-west-3": "workspaces.eu-west-3.amazonaws.com",
      "cn-north-1": "workspaces.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "workspaces.sa-east-1.amazonaws.com",
      "eu-west-1": "workspaces.eu-west-1.amazonaws.com",
      "us-gov-west-1": "workspaces.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "workspaces.ap-southeast-2.amazonaws.com",
      "ca-central-1": "workspaces.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "workspaces"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateIpGroups_590703 = ref object of OpenApiRestCall_590364
proc url_AssociateIpGroups_590705(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateIpGroups_590704(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_AssociateIpGroups_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_AssociateIpGroups_590703; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var associateIpGroups* = Call_AssociateIpGroups_590703(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_590704, base: "/",
    url: url_AssociateIpGroups_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_590972 = ref object of OpenApiRestCall_590364
proc url_AuthorizeIpRules_590974(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AuthorizeIpRules_590973(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_AuthorizeIpRules_590972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_AuthorizeIpRules_590972; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var authorizeIpRules* = Call_AuthorizeIpRules_590972(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_590973, base: "/",
    url: url_AuthorizeIpRules_590974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_590987 = ref object of OpenApiRestCall_590364
proc url_CopyWorkspaceImage_590989(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyWorkspaceImage_590988(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_CopyWorkspaceImage_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_CopyWorkspaceImage_590987; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_590987(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_590988, base: "/",
    url: url_CopyWorkspaceImage_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_591002 = ref object of OpenApiRestCall_590364
proc url_CreateIpGroup_591004(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIpGroup_591003(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateIpGroup_591002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateIpGroup_591002; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var createIpGroup* = Call_CreateIpGroup_591002(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_591003, base: "/", url: url_CreateIpGroup_591004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_591017 = ref object of OpenApiRestCall_590364
proc url_CreateTags_591019(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTags_591018(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_CreateTags_591017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_CreateTags_591017; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var createTags* = Call_CreateTags_591017(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_591018,
                                      base: "/", url: url_CreateTags_591019,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_591032 = ref object of OpenApiRestCall_590364
proc url_CreateWorkspaces_591034(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkspaces_591033(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_CreateWorkspaces_591032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_CreateWorkspaces_591032; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var createWorkspaces* = Call_CreateWorkspaces_591032(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_591033, base: "/",
    url: url_CreateWorkspaces_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_591047 = ref object of OpenApiRestCall_590364
proc url_DeleteIpGroup_591049(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteIpGroup_591048(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_DeleteIpGroup_591047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_DeleteIpGroup_591047; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var deleteIpGroup* = Call_DeleteIpGroup_591047(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_591048, base: "/", url: url_DeleteIpGroup_591049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_591062 = ref object of OpenApiRestCall_590364
proc url_DeleteTags_591064(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_591063(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_DeleteTags_591062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_DeleteTags_591062; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var deleteTags* = Call_DeleteTags_591062(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_591063,
                                      base: "/", url: url_DeleteTags_591064,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_591077 = ref object of OpenApiRestCall_590364
proc url_DeleteWorkspaceImage_591079(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkspaceImage_591078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_DeleteWorkspaceImage_591077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_DeleteWorkspaceImage_591077; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_591077(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_591078, base: "/",
    url: url_DeleteWorkspaceImage_591079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_591092 = ref object of OpenApiRestCall_590364
proc url_DescribeAccount_591094(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccount_591093(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_DescribeAccount_591092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_DescribeAccount_591092; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var describeAccount* = Call_DescribeAccount_591092(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_591093, base: "/", url: url_DescribeAccount_591094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_591107 = ref object of OpenApiRestCall_590364
proc url_DescribeAccountModifications_591109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccountModifications_591108(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_DescribeAccountModifications_591107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_DescribeAccountModifications_591107; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var describeAccountModifications* = Call_DescribeAccountModifications_591107(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_591108, base: "/",
    url: url_DescribeAccountModifications_591109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_591122 = ref object of OpenApiRestCall_590364
proc url_DescribeClientProperties_591124(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeClientProperties_591123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_DescribeClientProperties_591122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_DescribeClientProperties_591122; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var describeClientProperties* = Call_DescribeClientProperties_591122(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_591123, base: "/",
    url: url_DescribeClientProperties_591124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_591137 = ref object of OpenApiRestCall_590364
proc url_DescribeIpGroups_591139(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeIpGroups_591138(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes one or more of your IP access control groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591140 = header.getOrDefault("X-Amz-Target")
  valid_591140 = validateParameter(valid_591140, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_591140 != nil:
    section.add "X-Amz-Target", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Signature")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Signature", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Content-Sha256", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Date")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Date", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Credential")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Credential", valid_591144
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

proc call*(call_591149: Call_DescribeIpGroups_591137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_DescribeIpGroups_591137; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_591151 = newJObject()
  if body != nil:
    body_591151 = body
  result = call_591150.call(nil, nil, nil, nil, body_591151)

var describeIpGroups* = Call_DescribeIpGroups_591137(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_591138, base: "/",
    url: url_DescribeIpGroups_591139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_591152 = ref object of OpenApiRestCall_590364
proc url_DescribeTags_591154(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTags_591153(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591155 = header.getOrDefault("X-Amz-Target")
  valid_591155 = validateParameter(valid_591155, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_591155 != nil:
    section.add "X-Amz-Target", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591164: Call_DescribeTags_591152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_DescribeTags_591152; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var describeTags* = Call_DescribeTags_591152(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_591153, base: "/", url: url_DescribeTags_591154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_591167 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspaceBundles_591169(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceBundles_591168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591170 = query.getOrDefault("NextToken")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "NextToken", valid_591170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591171 = header.getOrDefault("X-Amz-Target")
  valid_591171 = validateParameter(valid_591171, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_591171 != nil:
    section.add "X-Amz-Target", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Signature")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Signature", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Content-Sha256", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Date")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Date", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Credential")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Credential", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Security-Token")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Security-Token", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Algorithm")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Algorithm", valid_591177
  var valid_591178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amz-SignedHeaders", valid_591178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591180: Call_DescribeWorkspaceBundles_591167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_591180.validator(path, query, header, formData, body)
  let scheme = call_591180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591180.url(scheme.get, call_591180.host, call_591180.base,
                         call_591180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591180, url, valid)

proc call*(call_591181: Call_DescribeWorkspaceBundles_591167; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591182 = newJObject()
  var body_591183 = newJObject()
  add(query_591182, "NextToken", newJString(NextToken))
  if body != nil:
    body_591183 = body
  result = call_591181.call(nil, query_591182, nil, nil, body_591183)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_591167(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_591168, base: "/",
    url: url_DescribeWorkspaceBundles_591169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_591185 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspaceDirectories_591187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceDirectories_591186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591188 = query.getOrDefault("NextToken")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "NextToken", valid_591188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591189 = header.getOrDefault("X-Amz-Target")
  valid_591189 = validateParameter(valid_591189, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_591189 != nil:
    section.add "X-Amz-Target", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Signature")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Signature", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Content-Sha256", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-Date")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Date", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-Credential")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-Credential", valid_591193
  var valid_591194 = header.getOrDefault("X-Amz-Security-Token")
  valid_591194 = validateParameter(valid_591194, JString, required = false,
                                 default = nil)
  if valid_591194 != nil:
    section.add "X-Amz-Security-Token", valid_591194
  var valid_591195 = header.getOrDefault("X-Amz-Algorithm")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "X-Amz-Algorithm", valid_591195
  var valid_591196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591196 = validateParameter(valid_591196, JString, required = false,
                                 default = nil)
  if valid_591196 != nil:
    section.add "X-Amz-SignedHeaders", valid_591196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591198: Call_DescribeWorkspaceDirectories_591185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_591198.validator(path, query, header, formData, body)
  let scheme = call_591198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591198.url(scheme.get, call_591198.host, call_591198.base,
                         call_591198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591198, url, valid)

proc call*(call_591199: Call_DescribeWorkspaceDirectories_591185; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591200 = newJObject()
  var body_591201 = newJObject()
  add(query_591200, "NextToken", newJString(NextToken))
  if body != nil:
    body_591201 = body
  result = call_591199.call(nil, query_591200, nil, nil, body_591201)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_591185(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_591186, base: "/",
    url: url_DescribeWorkspaceDirectories_591187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_591202 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspaceImages_591204(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceImages_591203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591205 = header.getOrDefault("X-Amz-Target")
  valid_591205 = validateParameter(valid_591205, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_591205 != nil:
    section.add "X-Amz-Target", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Signature")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Signature", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Content-Sha256", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Date")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Date", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Credential")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Credential", valid_591209
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

proc call*(call_591214: Call_DescribeWorkspaceImages_591202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_591214.validator(path, query, header, formData, body)
  let scheme = call_591214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591214.url(scheme.get, call_591214.host, call_591214.base,
                         call_591214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591214, url, valid)

proc call*(call_591215: Call_DescribeWorkspaceImages_591202; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_591216 = newJObject()
  if body != nil:
    body_591216 = body
  result = call_591215.call(nil, nil, nil, nil, body_591216)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_591202(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_591203, base: "/",
    url: url_DescribeWorkspaceImages_591204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_591217 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspaceSnapshots_591219(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceSnapshots_591218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591220 = header.getOrDefault("X-Amz-Target")
  valid_591220 = validateParameter(valid_591220, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_591220 != nil:
    section.add "X-Amz-Target", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Signature")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Signature", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Content-Sha256", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Date")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Date", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Credential")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Credential", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-Security-Token")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-Security-Token", valid_591225
  var valid_591226 = header.getOrDefault("X-Amz-Algorithm")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "X-Amz-Algorithm", valid_591226
  var valid_591227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-SignedHeaders", valid_591227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591229: Call_DescribeWorkspaceSnapshots_591217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_591229.validator(path, query, header, formData, body)
  let scheme = call_591229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591229.url(scheme.get, call_591229.host, call_591229.base,
                         call_591229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591229, url, valid)

proc call*(call_591230: Call_DescribeWorkspaceSnapshots_591217; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_591231 = newJObject()
  if body != nil:
    body_591231 = body
  result = call_591230.call(nil, nil, nil, nil, body_591231)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_591217(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_591218, base: "/",
    url: url_DescribeWorkspaceSnapshots_591219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_591232 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspaces_591234(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaces_591233(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_591235 = query.getOrDefault("NextToken")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "NextToken", valid_591235
  var valid_591236 = query.getOrDefault("Limit")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "Limit", valid_591236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591237 = header.getOrDefault("X-Amz-Target")
  valid_591237 = validateParameter(valid_591237, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_591237 != nil:
    section.add "X-Amz-Target", valid_591237
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
  var valid_591242 = header.getOrDefault("X-Amz-Security-Token")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Security-Token", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Algorithm")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Algorithm", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-SignedHeaders", valid_591244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591246: Call_DescribeWorkspaces_591232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_591246.validator(path, query, header, formData, body)
  let scheme = call_591246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591246.url(scheme.get, call_591246.host, call_591246.base,
                         call_591246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591246, url, valid)

proc call*(call_591247: Call_DescribeWorkspaces_591232; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_591248 = newJObject()
  var body_591249 = newJObject()
  add(query_591248, "NextToken", newJString(NextToken))
  add(query_591248, "Limit", newJString(Limit))
  if body != nil:
    body_591249 = body
  result = call_591247.call(nil, query_591248, nil, nil, body_591249)

var describeWorkspaces* = Call_DescribeWorkspaces_591232(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_591233, base: "/",
    url: url_DescribeWorkspaces_591234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_591250 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkspacesConnectionStatus_591252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspacesConnectionStatus_591251(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591253 = header.getOrDefault("X-Amz-Target")
  valid_591253 = validateParameter(valid_591253, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_591253 != nil:
    section.add "X-Amz-Target", valid_591253
  var valid_591254 = header.getOrDefault("X-Amz-Signature")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "X-Amz-Signature", valid_591254
  var valid_591255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Content-Sha256", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-Date")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Date", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Credential")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Credential", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Security-Token")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Security-Token", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Algorithm")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Algorithm", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-SignedHeaders", valid_591260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591262: Call_DescribeWorkspacesConnectionStatus_591250;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_591262.validator(path, query, header, formData, body)
  let scheme = call_591262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591262.url(scheme.get, call_591262.host, call_591262.base,
                         call_591262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591262, url, valid)

proc call*(call_591263: Call_DescribeWorkspacesConnectionStatus_591250;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_591264 = newJObject()
  if body != nil:
    body_591264 = body
  result = call_591263.call(nil, nil, nil, nil, body_591264)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_591250(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_591251, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_591252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_591265 = ref object of OpenApiRestCall_590364
proc url_DisassociateIpGroups_591267(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateIpGroups_591266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591268 = header.getOrDefault("X-Amz-Target")
  valid_591268 = validateParameter(valid_591268, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_591268 != nil:
    section.add "X-Amz-Target", valid_591268
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
  var valid_591273 = header.getOrDefault("X-Amz-Security-Token")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Security-Token", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-Algorithm")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Algorithm", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-SignedHeaders", valid_591275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591277: Call_DisassociateIpGroups_591265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_591277.validator(path, query, header, formData, body)
  let scheme = call_591277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591277.url(scheme.get, call_591277.host, call_591277.base,
                         call_591277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591277, url, valid)

proc call*(call_591278: Call_DisassociateIpGroups_591265; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_591279 = newJObject()
  if body != nil:
    body_591279 = body
  result = call_591278.call(nil, nil, nil, nil, body_591279)

var disassociateIpGroups* = Call_DisassociateIpGroups_591265(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_591266, base: "/",
    url: url_DisassociateIpGroups_591267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_591280 = ref object of OpenApiRestCall_590364
proc url_ImportWorkspaceImage_591282(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportWorkspaceImage_591281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591283 = header.getOrDefault("X-Amz-Target")
  valid_591283 = validateParameter(valid_591283, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_591283 != nil:
    section.add "X-Amz-Target", valid_591283
  var valid_591284 = header.getOrDefault("X-Amz-Signature")
  valid_591284 = validateParameter(valid_591284, JString, required = false,
                                 default = nil)
  if valid_591284 != nil:
    section.add "X-Amz-Signature", valid_591284
  var valid_591285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591285 = validateParameter(valid_591285, JString, required = false,
                                 default = nil)
  if valid_591285 != nil:
    section.add "X-Amz-Content-Sha256", valid_591285
  var valid_591286 = header.getOrDefault("X-Amz-Date")
  valid_591286 = validateParameter(valid_591286, JString, required = false,
                                 default = nil)
  if valid_591286 != nil:
    section.add "X-Amz-Date", valid_591286
  var valid_591287 = header.getOrDefault("X-Amz-Credential")
  valid_591287 = validateParameter(valid_591287, JString, required = false,
                                 default = nil)
  if valid_591287 != nil:
    section.add "X-Amz-Credential", valid_591287
  var valid_591288 = header.getOrDefault("X-Amz-Security-Token")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Security-Token", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Algorithm")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Algorithm", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-SignedHeaders", valid_591290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591292: Call_ImportWorkspaceImage_591280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_591292.validator(path, query, header, formData, body)
  let scheme = call_591292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591292.url(scheme.get, call_591292.host, call_591292.base,
                         call_591292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591292, url, valid)

proc call*(call_591293: Call_ImportWorkspaceImage_591280; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_591294 = newJObject()
  if body != nil:
    body_591294 = body
  result = call_591293.call(nil, nil, nil, nil, body_591294)

var importWorkspaceImage* = Call_ImportWorkspaceImage_591280(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_591281, base: "/",
    url: url_ImportWorkspaceImage_591282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_591295 = ref object of OpenApiRestCall_590364
proc url_ListAvailableManagementCidrRanges_591297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAvailableManagementCidrRanges_591296(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591298 = header.getOrDefault("X-Amz-Target")
  valid_591298 = validateParameter(valid_591298, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_591298 != nil:
    section.add "X-Amz-Target", valid_591298
  var valid_591299 = header.getOrDefault("X-Amz-Signature")
  valid_591299 = validateParameter(valid_591299, JString, required = false,
                                 default = nil)
  if valid_591299 != nil:
    section.add "X-Amz-Signature", valid_591299
  var valid_591300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591300 = validateParameter(valid_591300, JString, required = false,
                                 default = nil)
  if valid_591300 != nil:
    section.add "X-Amz-Content-Sha256", valid_591300
  var valid_591301 = header.getOrDefault("X-Amz-Date")
  valid_591301 = validateParameter(valid_591301, JString, required = false,
                                 default = nil)
  if valid_591301 != nil:
    section.add "X-Amz-Date", valid_591301
  var valid_591302 = header.getOrDefault("X-Amz-Credential")
  valid_591302 = validateParameter(valid_591302, JString, required = false,
                                 default = nil)
  if valid_591302 != nil:
    section.add "X-Amz-Credential", valid_591302
  var valid_591303 = header.getOrDefault("X-Amz-Security-Token")
  valid_591303 = validateParameter(valid_591303, JString, required = false,
                                 default = nil)
  if valid_591303 != nil:
    section.add "X-Amz-Security-Token", valid_591303
  var valid_591304 = header.getOrDefault("X-Amz-Algorithm")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Algorithm", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-SignedHeaders", valid_591305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591307: Call_ListAvailableManagementCidrRanges_591295;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_591307.validator(path, query, header, formData, body)
  let scheme = call_591307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591307.url(scheme.get, call_591307.host, call_591307.base,
                         call_591307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591307, url, valid)

proc call*(call_591308: Call_ListAvailableManagementCidrRanges_591295;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_591309 = newJObject()
  if body != nil:
    body_591309 = body
  result = call_591308.call(nil, nil, nil, nil, body_591309)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_591295(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_591296, base: "/",
    url: url_ListAvailableManagementCidrRanges_591297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_591310 = ref object of OpenApiRestCall_590364
proc url_ModifyAccount_591312(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyAccount_591311(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591313 = header.getOrDefault("X-Amz-Target")
  valid_591313 = validateParameter(valid_591313, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_591313 != nil:
    section.add "X-Amz-Target", valid_591313
  var valid_591314 = header.getOrDefault("X-Amz-Signature")
  valid_591314 = validateParameter(valid_591314, JString, required = false,
                                 default = nil)
  if valid_591314 != nil:
    section.add "X-Amz-Signature", valid_591314
  var valid_591315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591315 = validateParameter(valid_591315, JString, required = false,
                                 default = nil)
  if valid_591315 != nil:
    section.add "X-Amz-Content-Sha256", valid_591315
  var valid_591316 = header.getOrDefault("X-Amz-Date")
  valid_591316 = validateParameter(valid_591316, JString, required = false,
                                 default = nil)
  if valid_591316 != nil:
    section.add "X-Amz-Date", valid_591316
  var valid_591317 = header.getOrDefault("X-Amz-Credential")
  valid_591317 = validateParameter(valid_591317, JString, required = false,
                                 default = nil)
  if valid_591317 != nil:
    section.add "X-Amz-Credential", valid_591317
  var valid_591318 = header.getOrDefault("X-Amz-Security-Token")
  valid_591318 = validateParameter(valid_591318, JString, required = false,
                                 default = nil)
  if valid_591318 != nil:
    section.add "X-Amz-Security-Token", valid_591318
  var valid_591319 = header.getOrDefault("X-Amz-Algorithm")
  valid_591319 = validateParameter(valid_591319, JString, required = false,
                                 default = nil)
  if valid_591319 != nil:
    section.add "X-Amz-Algorithm", valid_591319
  var valid_591320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591320 = validateParameter(valid_591320, JString, required = false,
                                 default = nil)
  if valid_591320 != nil:
    section.add "X-Amz-SignedHeaders", valid_591320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591322: Call_ModifyAccount_591310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_591322.validator(path, query, header, formData, body)
  let scheme = call_591322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591322.url(scheme.get, call_591322.host, call_591322.base,
                         call_591322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591322, url, valid)

proc call*(call_591323: Call_ModifyAccount_591310; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_591324 = newJObject()
  if body != nil:
    body_591324 = body
  result = call_591323.call(nil, nil, nil, nil, body_591324)

var modifyAccount* = Call_ModifyAccount_591310(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_591311, base: "/", url: url_ModifyAccount_591312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_591325 = ref object of OpenApiRestCall_590364
proc url_ModifyClientProperties_591327(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyClientProperties_591326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591328 = header.getOrDefault("X-Amz-Target")
  valid_591328 = validateParameter(valid_591328, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_591328 != nil:
    section.add "X-Amz-Target", valid_591328
  var valid_591329 = header.getOrDefault("X-Amz-Signature")
  valid_591329 = validateParameter(valid_591329, JString, required = false,
                                 default = nil)
  if valid_591329 != nil:
    section.add "X-Amz-Signature", valid_591329
  var valid_591330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-Content-Sha256", valid_591330
  var valid_591331 = header.getOrDefault("X-Amz-Date")
  valid_591331 = validateParameter(valid_591331, JString, required = false,
                                 default = nil)
  if valid_591331 != nil:
    section.add "X-Amz-Date", valid_591331
  var valid_591332 = header.getOrDefault("X-Amz-Credential")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-Credential", valid_591332
  var valid_591333 = header.getOrDefault("X-Amz-Security-Token")
  valid_591333 = validateParameter(valid_591333, JString, required = false,
                                 default = nil)
  if valid_591333 != nil:
    section.add "X-Amz-Security-Token", valid_591333
  var valid_591334 = header.getOrDefault("X-Amz-Algorithm")
  valid_591334 = validateParameter(valid_591334, JString, required = false,
                                 default = nil)
  if valid_591334 != nil:
    section.add "X-Amz-Algorithm", valid_591334
  var valid_591335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591335 = validateParameter(valid_591335, JString, required = false,
                                 default = nil)
  if valid_591335 != nil:
    section.add "X-Amz-SignedHeaders", valid_591335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591337: Call_ModifyClientProperties_591325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_591337.validator(path, query, header, formData, body)
  let scheme = call_591337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591337.url(scheme.get, call_591337.host, call_591337.base,
                         call_591337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591337, url, valid)

proc call*(call_591338: Call_ModifyClientProperties_591325; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_591339 = newJObject()
  if body != nil:
    body_591339 = body
  result = call_591338.call(nil, nil, nil, nil, body_591339)

var modifyClientProperties* = Call_ModifyClientProperties_591325(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_591326, base: "/",
    url: url_ModifyClientProperties_591327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_591340 = ref object of OpenApiRestCall_590364
proc url_ModifyWorkspaceProperties_591342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceProperties_591341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified WorkSpace properties.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591343 = header.getOrDefault("X-Amz-Target")
  valid_591343 = validateParameter(valid_591343, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_591343 != nil:
    section.add "X-Amz-Target", valid_591343
  var valid_591344 = header.getOrDefault("X-Amz-Signature")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = nil)
  if valid_591344 != nil:
    section.add "X-Amz-Signature", valid_591344
  var valid_591345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Content-Sha256", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Date")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Date", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Credential")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Credential", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Security-Token")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Security-Token", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-Algorithm")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-Algorithm", valid_591349
  var valid_591350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591350 = validateParameter(valid_591350, JString, required = false,
                                 default = nil)
  if valid_591350 != nil:
    section.add "X-Amz-SignedHeaders", valid_591350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591352: Call_ModifyWorkspaceProperties_591340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_591352.validator(path, query, header, formData, body)
  let scheme = call_591352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591352.url(scheme.get, call_591352.host, call_591352.base,
                         call_591352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591352, url, valid)

proc call*(call_591353: Call_ModifyWorkspaceProperties_591340; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_591354 = newJObject()
  if body != nil:
    body_591354 = body
  result = call_591353.call(nil, nil, nil, nil, body_591354)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_591340(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_591341, base: "/",
    url: url_ModifyWorkspaceProperties_591342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_591355 = ref object of OpenApiRestCall_590364
proc url_ModifyWorkspaceState_591357(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceState_591356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591358 = header.getOrDefault("X-Amz-Target")
  valid_591358 = validateParameter(valid_591358, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_591358 != nil:
    section.add "X-Amz-Target", valid_591358
  var valid_591359 = header.getOrDefault("X-Amz-Signature")
  valid_591359 = validateParameter(valid_591359, JString, required = false,
                                 default = nil)
  if valid_591359 != nil:
    section.add "X-Amz-Signature", valid_591359
  var valid_591360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "X-Amz-Content-Sha256", valid_591360
  var valid_591361 = header.getOrDefault("X-Amz-Date")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "X-Amz-Date", valid_591361
  var valid_591362 = header.getOrDefault("X-Amz-Credential")
  valid_591362 = validateParameter(valid_591362, JString, required = false,
                                 default = nil)
  if valid_591362 != nil:
    section.add "X-Amz-Credential", valid_591362
  var valid_591363 = header.getOrDefault("X-Amz-Security-Token")
  valid_591363 = validateParameter(valid_591363, JString, required = false,
                                 default = nil)
  if valid_591363 != nil:
    section.add "X-Amz-Security-Token", valid_591363
  var valid_591364 = header.getOrDefault("X-Amz-Algorithm")
  valid_591364 = validateParameter(valid_591364, JString, required = false,
                                 default = nil)
  if valid_591364 != nil:
    section.add "X-Amz-Algorithm", valid_591364
  var valid_591365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591365 = validateParameter(valid_591365, JString, required = false,
                                 default = nil)
  if valid_591365 != nil:
    section.add "X-Amz-SignedHeaders", valid_591365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591367: Call_ModifyWorkspaceState_591355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_591367.validator(path, query, header, formData, body)
  let scheme = call_591367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591367.url(scheme.get, call_591367.host, call_591367.base,
                         call_591367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591367, url, valid)

proc call*(call_591368: Call_ModifyWorkspaceState_591355; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_591369 = newJObject()
  if body != nil:
    body_591369 = body
  result = call_591368.call(nil, nil, nil, nil, body_591369)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_591355(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_591356, base: "/",
    url: url_ModifyWorkspaceState_591357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_591370 = ref object of OpenApiRestCall_590364
proc url_RebootWorkspaces_591372(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootWorkspaces_591371(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591373 = header.getOrDefault("X-Amz-Target")
  valid_591373 = validateParameter(valid_591373, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_591373 != nil:
    section.add "X-Amz-Target", valid_591373
  var valid_591374 = header.getOrDefault("X-Amz-Signature")
  valid_591374 = validateParameter(valid_591374, JString, required = false,
                                 default = nil)
  if valid_591374 != nil:
    section.add "X-Amz-Signature", valid_591374
  var valid_591375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591375 = validateParameter(valid_591375, JString, required = false,
                                 default = nil)
  if valid_591375 != nil:
    section.add "X-Amz-Content-Sha256", valid_591375
  var valid_591376 = header.getOrDefault("X-Amz-Date")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-Date", valid_591376
  var valid_591377 = header.getOrDefault("X-Amz-Credential")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Credential", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-Security-Token")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-Security-Token", valid_591378
  var valid_591379 = header.getOrDefault("X-Amz-Algorithm")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-Algorithm", valid_591379
  var valid_591380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591380 = validateParameter(valid_591380, JString, required = false,
                                 default = nil)
  if valid_591380 != nil:
    section.add "X-Amz-SignedHeaders", valid_591380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591382: Call_RebootWorkspaces_591370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_591382.validator(path, query, header, formData, body)
  let scheme = call_591382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591382.url(scheme.get, call_591382.host, call_591382.base,
                         call_591382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591382, url, valid)

proc call*(call_591383: Call_RebootWorkspaces_591370; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_591384 = newJObject()
  if body != nil:
    body_591384 = body
  result = call_591383.call(nil, nil, nil, nil, body_591384)

var rebootWorkspaces* = Call_RebootWorkspaces_591370(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_591371, base: "/",
    url: url_RebootWorkspaces_591372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_591385 = ref object of OpenApiRestCall_590364
proc url_RebuildWorkspaces_591387(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebuildWorkspaces_591386(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591388 = header.getOrDefault("X-Amz-Target")
  valid_591388 = validateParameter(valid_591388, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_591388 != nil:
    section.add "X-Amz-Target", valid_591388
  var valid_591389 = header.getOrDefault("X-Amz-Signature")
  valid_591389 = validateParameter(valid_591389, JString, required = false,
                                 default = nil)
  if valid_591389 != nil:
    section.add "X-Amz-Signature", valid_591389
  var valid_591390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-Content-Sha256", valid_591390
  var valid_591391 = header.getOrDefault("X-Amz-Date")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-Date", valid_591391
  var valid_591392 = header.getOrDefault("X-Amz-Credential")
  valid_591392 = validateParameter(valid_591392, JString, required = false,
                                 default = nil)
  if valid_591392 != nil:
    section.add "X-Amz-Credential", valid_591392
  var valid_591393 = header.getOrDefault("X-Amz-Security-Token")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-Security-Token", valid_591393
  var valid_591394 = header.getOrDefault("X-Amz-Algorithm")
  valid_591394 = validateParameter(valid_591394, JString, required = false,
                                 default = nil)
  if valid_591394 != nil:
    section.add "X-Amz-Algorithm", valid_591394
  var valid_591395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591395 = validateParameter(valid_591395, JString, required = false,
                                 default = nil)
  if valid_591395 != nil:
    section.add "X-Amz-SignedHeaders", valid_591395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591397: Call_RebuildWorkspaces_591385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_591397.validator(path, query, header, formData, body)
  let scheme = call_591397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591397.url(scheme.get, call_591397.host, call_591397.base,
                         call_591397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591397, url, valid)

proc call*(call_591398: Call_RebuildWorkspaces_591385; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_591399 = newJObject()
  if body != nil:
    body_591399 = body
  result = call_591398.call(nil, nil, nil, nil, body_591399)

var rebuildWorkspaces* = Call_RebuildWorkspaces_591385(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_591386, base: "/",
    url: url_RebuildWorkspaces_591387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_591400 = ref object of OpenApiRestCall_590364
proc url_RestoreWorkspace_591402(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreWorkspace_591401(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591403 = header.getOrDefault("X-Amz-Target")
  valid_591403 = validateParameter(valid_591403, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_591403 != nil:
    section.add "X-Amz-Target", valid_591403
  var valid_591404 = header.getOrDefault("X-Amz-Signature")
  valid_591404 = validateParameter(valid_591404, JString, required = false,
                                 default = nil)
  if valid_591404 != nil:
    section.add "X-Amz-Signature", valid_591404
  var valid_591405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591405 = validateParameter(valid_591405, JString, required = false,
                                 default = nil)
  if valid_591405 != nil:
    section.add "X-Amz-Content-Sha256", valid_591405
  var valid_591406 = header.getOrDefault("X-Amz-Date")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Date", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-Credential")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-Credential", valid_591407
  var valid_591408 = header.getOrDefault("X-Amz-Security-Token")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-Security-Token", valid_591408
  var valid_591409 = header.getOrDefault("X-Amz-Algorithm")
  valid_591409 = validateParameter(valid_591409, JString, required = false,
                                 default = nil)
  if valid_591409 != nil:
    section.add "X-Amz-Algorithm", valid_591409
  var valid_591410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591410 = validateParameter(valid_591410, JString, required = false,
                                 default = nil)
  if valid_591410 != nil:
    section.add "X-Amz-SignedHeaders", valid_591410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591412: Call_RestoreWorkspace_591400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_591412.validator(path, query, header, formData, body)
  let scheme = call_591412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591412.url(scheme.get, call_591412.host, call_591412.base,
                         call_591412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591412, url, valid)

proc call*(call_591413: Call_RestoreWorkspace_591400; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_591414 = newJObject()
  if body != nil:
    body_591414 = body
  result = call_591413.call(nil, nil, nil, nil, body_591414)

var restoreWorkspace* = Call_RestoreWorkspace_591400(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_591401, base: "/",
    url: url_RestoreWorkspace_591402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_591415 = ref object of OpenApiRestCall_590364
proc url_RevokeIpRules_591417(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeIpRules_591416(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591418 = header.getOrDefault("X-Amz-Target")
  valid_591418 = validateParameter(valid_591418, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_591418 != nil:
    section.add "X-Amz-Target", valid_591418
  var valid_591419 = header.getOrDefault("X-Amz-Signature")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "X-Amz-Signature", valid_591419
  var valid_591420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591420 = validateParameter(valid_591420, JString, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "X-Amz-Content-Sha256", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-Date")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-Date", valid_591421
  var valid_591422 = header.getOrDefault("X-Amz-Credential")
  valid_591422 = validateParameter(valid_591422, JString, required = false,
                                 default = nil)
  if valid_591422 != nil:
    section.add "X-Amz-Credential", valid_591422
  var valid_591423 = header.getOrDefault("X-Amz-Security-Token")
  valid_591423 = validateParameter(valid_591423, JString, required = false,
                                 default = nil)
  if valid_591423 != nil:
    section.add "X-Amz-Security-Token", valid_591423
  var valid_591424 = header.getOrDefault("X-Amz-Algorithm")
  valid_591424 = validateParameter(valid_591424, JString, required = false,
                                 default = nil)
  if valid_591424 != nil:
    section.add "X-Amz-Algorithm", valid_591424
  var valid_591425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591425 = validateParameter(valid_591425, JString, required = false,
                                 default = nil)
  if valid_591425 != nil:
    section.add "X-Amz-SignedHeaders", valid_591425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591427: Call_RevokeIpRules_591415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_591427.validator(path, query, header, formData, body)
  let scheme = call_591427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591427.url(scheme.get, call_591427.host, call_591427.base,
                         call_591427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591427, url, valid)

proc call*(call_591428: Call_RevokeIpRules_591415; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_591429 = newJObject()
  if body != nil:
    body_591429 = body
  result = call_591428.call(nil, nil, nil, nil, body_591429)

var revokeIpRules* = Call_RevokeIpRules_591415(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_591416, base: "/", url: url_RevokeIpRules_591417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_591430 = ref object of OpenApiRestCall_590364
proc url_StartWorkspaces_591432(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkspaces_591431(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591433 = header.getOrDefault("X-Amz-Target")
  valid_591433 = validateParameter(valid_591433, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_591433 != nil:
    section.add "X-Amz-Target", valid_591433
  var valid_591434 = header.getOrDefault("X-Amz-Signature")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Signature", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Content-Sha256", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-Date")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-Date", valid_591436
  var valid_591437 = header.getOrDefault("X-Amz-Credential")
  valid_591437 = validateParameter(valid_591437, JString, required = false,
                                 default = nil)
  if valid_591437 != nil:
    section.add "X-Amz-Credential", valid_591437
  var valid_591438 = header.getOrDefault("X-Amz-Security-Token")
  valid_591438 = validateParameter(valid_591438, JString, required = false,
                                 default = nil)
  if valid_591438 != nil:
    section.add "X-Amz-Security-Token", valid_591438
  var valid_591439 = header.getOrDefault("X-Amz-Algorithm")
  valid_591439 = validateParameter(valid_591439, JString, required = false,
                                 default = nil)
  if valid_591439 != nil:
    section.add "X-Amz-Algorithm", valid_591439
  var valid_591440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591440 = validateParameter(valid_591440, JString, required = false,
                                 default = nil)
  if valid_591440 != nil:
    section.add "X-Amz-SignedHeaders", valid_591440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591442: Call_StartWorkspaces_591430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_591442.validator(path, query, header, formData, body)
  let scheme = call_591442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591442.url(scheme.get, call_591442.host, call_591442.base,
                         call_591442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591442, url, valid)

proc call*(call_591443: Call_StartWorkspaces_591430; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_591444 = newJObject()
  if body != nil:
    body_591444 = body
  result = call_591443.call(nil, nil, nil, nil, body_591444)

var startWorkspaces* = Call_StartWorkspaces_591430(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_591431, base: "/", url: url_StartWorkspaces_591432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_591445 = ref object of OpenApiRestCall_590364
proc url_StopWorkspaces_591447(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopWorkspaces_591446(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591448 = header.getOrDefault("X-Amz-Target")
  valid_591448 = validateParameter(valid_591448, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_591448 != nil:
    section.add "X-Amz-Target", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Signature")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Signature", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Content-Sha256", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-Date")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-Date", valid_591451
  var valid_591452 = header.getOrDefault("X-Amz-Credential")
  valid_591452 = validateParameter(valid_591452, JString, required = false,
                                 default = nil)
  if valid_591452 != nil:
    section.add "X-Amz-Credential", valid_591452
  var valid_591453 = header.getOrDefault("X-Amz-Security-Token")
  valid_591453 = validateParameter(valid_591453, JString, required = false,
                                 default = nil)
  if valid_591453 != nil:
    section.add "X-Amz-Security-Token", valid_591453
  var valid_591454 = header.getOrDefault("X-Amz-Algorithm")
  valid_591454 = validateParameter(valid_591454, JString, required = false,
                                 default = nil)
  if valid_591454 != nil:
    section.add "X-Amz-Algorithm", valid_591454
  var valid_591455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591455 = validateParameter(valid_591455, JString, required = false,
                                 default = nil)
  if valid_591455 != nil:
    section.add "X-Amz-SignedHeaders", valid_591455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591457: Call_StopWorkspaces_591445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_591457.validator(path, query, header, formData, body)
  let scheme = call_591457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591457.url(scheme.get, call_591457.host, call_591457.base,
                         call_591457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591457, url, valid)

proc call*(call_591458: Call_StopWorkspaces_591445; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_591459 = newJObject()
  if body != nil:
    body_591459 = body
  result = call_591458.call(nil, nil, nil, nil, body_591459)

var stopWorkspaces* = Call_StopWorkspaces_591445(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_591446, base: "/", url: url_StopWorkspaces_591447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_591460 = ref object of OpenApiRestCall_590364
proc url_TerminateWorkspaces_591462(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateWorkspaces_591461(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591463 = header.getOrDefault("X-Amz-Target")
  valid_591463 = validateParameter(valid_591463, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_591463 != nil:
    section.add "X-Amz-Target", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-Signature")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Signature", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Content-Sha256", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-Date")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-Date", valid_591466
  var valid_591467 = header.getOrDefault("X-Amz-Credential")
  valid_591467 = validateParameter(valid_591467, JString, required = false,
                                 default = nil)
  if valid_591467 != nil:
    section.add "X-Amz-Credential", valid_591467
  var valid_591468 = header.getOrDefault("X-Amz-Security-Token")
  valid_591468 = validateParameter(valid_591468, JString, required = false,
                                 default = nil)
  if valid_591468 != nil:
    section.add "X-Amz-Security-Token", valid_591468
  var valid_591469 = header.getOrDefault("X-Amz-Algorithm")
  valid_591469 = validateParameter(valid_591469, JString, required = false,
                                 default = nil)
  if valid_591469 != nil:
    section.add "X-Amz-Algorithm", valid_591469
  var valid_591470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591470 = validateParameter(valid_591470, JString, required = false,
                                 default = nil)
  if valid_591470 != nil:
    section.add "X-Amz-SignedHeaders", valid_591470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591472: Call_TerminateWorkspaces_591460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_591472.validator(path, query, header, formData, body)
  let scheme = call_591472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591472.url(scheme.get, call_591472.host, call_591472.base,
                         call_591472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591472, url, valid)

proc call*(call_591473: Call_TerminateWorkspaces_591460; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_591474 = newJObject()
  if body != nil:
    body_591474 = body
  result = call_591473.call(nil, nil, nil, nil, body_591474)

var terminateWorkspaces* = Call_TerminateWorkspaces_591460(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_591461, base: "/",
    url: url_TerminateWorkspaces_591462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_591475 = ref object of OpenApiRestCall_590364
proc url_UpdateRulesOfIpGroup_591477(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRulesOfIpGroup_591476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591478 = header.getOrDefault("X-Amz-Target")
  valid_591478 = validateParameter(valid_591478, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_591478 != nil:
    section.add "X-Amz-Target", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Signature")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Signature", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-Content-Sha256", valid_591480
  var valid_591481 = header.getOrDefault("X-Amz-Date")
  valid_591481 = validateParameter(valid_591481, JString, required = false,
                                 default = nil)
  if valid_591481 != nil:
    section.add "X-Amz-Date", valid_591481
  var valid_591482 = header.getOrDefault("X-Amz-Credential")
  valid_591482 = validateParameter(valid_591482, JString, required = false,
                                 default = nil)
  if valid_591482 != nil:
    section.add "X-Amz-Credential", valid_591482
  var valid_591483 = header.getOrDefault("X-Amz-Security-Token")
  valid_591483 = validateParameter(valid_591483, JString, required = false,
                                 default = nil)
  if valid_591483 != nil:
    section.add "X-Amz-Security-Token", valid_591483
  var valid_591484 = header.getOrDefault("X-Amz-Algorithm")
  valid_591484 = validateParameter(valid_591484, JString, required = false,
                                 default = nil)
  if valid_591484 != nil:
    section.add "X-Amz-Algorithm", valid_591484
  var valid_591485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591485 = validateParameter(valid_591485, JString, required = false,
                                 default = nil)
  if valid_591485 != nil:
    section.add "X-Amz-SignedHeaders", valid_591485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591487: Call_UpdateRulesOfIpGroup_591475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_591487.validator(path, query, header, formData, body)
  let scheme = call_591487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591487.url(scheme.get, call_591487.host, call_591487.base,
                         call_591487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591487, url, valid)

proc call*(call_591488: Call_UpdateRulesOfIpGroup_591475; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_591489 = newJObject()
  if body != nil:
    body_591489 = body
  result = call_591488.call(nil, nil, nil, nil, body_591489)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_591475(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_591476, base: "/",
    url: url_UpdateRulesOfIpGroup_591477, schemes: {Scheme.Https, Scheme.Http})
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
