
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_604658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateIpGroups_604996 = ref object of OpenApiRestCall_604658
proc url_AssociateIpGroups_604998(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateIpGroups_604997(path: JsonNode; query: JsonNode;
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
  var valid_605123 = header.getOrDefault("X-Amz-Target")
  valid_605123 = validateParameter(valid_605123, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_605123 != nil:
    section.add "X-Amz-Target", valid_605123
  var valid_605124 = header.getOrDefault("X-Amz-Signature")
  valid_605124 = validateParameter(valid_605124, JString, required = false,
                                 default = nil)
  if valid_605124 != nil:
    section.add "X-Amz-Signature", valid_605124
  var valid_605125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605125 = validateParameter(valid_605125, JString, required = false,
                                 default = nil)
  if valid_605125 != nil:
    section.add "X-Amz-Content-Sha256", valid_605125
  var valid_605126 = header.getOrDefault("X-Amz-Date")
  valid_605126 = validateParameter(valid_605126, JString, required = false,
                                 default = nil)
  if valid_605126 != nil:
    section.add "X-Amz-Date", valid_605126
  var valid_605127 = header.getOrDefault("X-Amz-Credential")
  valid_605127 = validateParameter(valid_605127, JString, required = false,
                                 default = nil)
  if valid_605127 != nil:
    section.add "X-Amz-Credential", valid_605127
  var valid_605128 = header.getOrDefault("X-Amz-Security-Token")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "X-Amz-Security-Token", valid_605128
  var valid_605129 = header.getOrDefault("X-Amz-Algorithm")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "X-Amz-Algorithm", valid_605129
  var valid_605130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-SignedHeaders", valid_605130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605154: Call_AssociateIpGroups_604996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_605154.validator(path, query, header, formData, body)
  let scheme = call_605154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605154.url(scheme.get, call_605154.host, call_605154.base,
                         call_605154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605154, url, valid)

proc call*(call_605225: Call_AssociateIpGroups_604996; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_605226 = newJObject()
  if body != nil:
    body_605226 = body
  result = call_605225.call(nil, nil, nil, nil, body_605226)

var associateIpGroups* = Call_AssociateIpGroups_604996(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_604997, base: "/",
    url: url_AssociateIpGroups_604998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_605265 = ref object of OpenApiRestCall_604658
proc url_AuthorizeIpRules_605267(protocol: Scheme; host: string; base: string;
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

proc validate_AuthorizeIpRules_605266(path: JsonNode; query: JsonNode;
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
  var valid_605268 = header.getOrDefault("X-Amz-Target")
  valid_605268 = validateParameter(valid_605268, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_605268 != nil:
    section.add "X-Amz-Target", valid_605268
  var valid_605269 = header.getOrDefault("X-Amz-Signature")
  valid_605269 = validateParameter(valid_605269, JString, required = false,
                                 default = nil)
  if valid_605269 != nil:
    section.add "X-Amz-Signature", valid_605269
  var valid_605270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605270 = validateParameter(valid_605270, JString, required = false,
                                 default = nil)
  if valid_605270 != nil:
    section.add "X-Amz-Content-Sha256", valid_605270
  var valid_605271 = header.getOrDefault("X-Amz-Date")
  valid_605271 = validateParameter(valid_605271, JString, required = false,
                                 default = nil)
  if valid_605271 != nil:
    section.add "X-Amz-Date", valid_605271
  var valid_605272 = header.getOrDefault("X-Amz-Credential")
  valid_605272 = validateParameter(valid_605272, JString, required = false,
                                 default = nil)
  if valid_605272 != nil:
    section.add "X-Amz-Credential", valid_605272
  var valid_605273 = header.getOrDefault("X-Amz-Security-Token")
  valid_605273 = validateParameter(valid_605273, JString, required = false,
                                 default = nil)
  if valid_605273 != nil:
    section.add "X-Amz-Security-Token", valid_605273
  var valid_605274 = header.getOrDefault("X-Amz-Algorithm")
  valid_605274 = validateParameter(valid_605274, JString, required = false,
                                 default = nil)
  if valid_605274 != nil:
    section.add "X-Amz-Algorithm", valid_605274
  var valid_605275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "X-Amz-SignedHeaders", valid_605275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605277: Call_AuthorizeIpRules_605265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_605277.validator(path, query, header, formData, body)
  let scheme = call_605277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605277.url(scheme.get, call_605277.host, call_605277.base,
                         call_605277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605277, url, valid)

proc call*(call_605278: Call_AuthorizeIpRules_605265; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_605279 = newJObject()
  if body != nil:
    body_605279 = body
  result = call_605278.call(nil, nil, nil, nil, body_605279)

var authorizeIpRules* = Call_AuthorizeIpRules_605265(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_605266, base: "/",
    url: url_AuthorizeIpRules_605267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_605280 = ref object of OpenApiRestCall_604658
proc url_CopyWorkspaceImage_605282(protocol: Scheme; host: string; base: string;
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

proc validate_CopyWorkspaceImage_605281(path: JsonNode; query: JsonNode;
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
  var valid_605283 = header.getOrDefault("X-Amz-Target")
  valid_605283 = validateParameter(valid_605283, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_605283 != nil:
    section.add "X-Amz-Target", valid_605283
  var valid_605284 = header.getOrDefault("X-Amz-Signature")
  valid_605284 = validateParameter(valid_605284, JString, required = false,
                                 default = nil)
  if valid_605284 != nil:
    section.add "X-Amz-Signature", valid_605284
  var valid_605285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605285 = validateParameter(valid_605285, JString, required = false,
                                 default = nil)
  if valid_605285 != nil:
    section.add "X-Amz-Content-Sha256", valid_605285
  var valid_605286 = header.getOrDefault("X-Amz-Date")
  valid_605286 = validateParameter(valid_605286, JString, required = false,
                                 default = nil)
  if valid_605286 != nil:
    section.add "X-Amz-Date", valid_605286
  var valid_605287 = header.getOrDefault("X-Amz-Credential")
  valid_605287 = validateParameter(valid_605287, JString, required = false,
                                 default = nil)
  if valid_605287 != nil:
    section.add "X-Amz-Credential", valid_605287
  var valid_605288 = header.getOrDefault("X-Amz-Security-Token")
  valid_605288 = validateParameter(valid_605288, JString, required = false,
                                 default = nil)
  if valid_605288 != nil:
    section.add "X-Amz-Security-Token", valid_605288
  var valid_605289 = header.getOrDefault("X-Amz-Algorithm")
  valid_605289 = validateParameter(valid_605289, JString, required = false,
                                 default = nil)
  if valid_605289 != nil:
    section.add "X-Amz-Algorithm", valid_605289
  var valid_605290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "X-Amz-SignedHeaders", valid_605290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605292: Call_CopyWorkspaceImage_605280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_605292.validator(path, query, header, formData, body)
  let scheme = call_605292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605292.url(scheme.get, call_605292.host, call_605292.base,
                         call_605292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605292, url, valid)

proc call*(call_605293: Call_CopyWorkspaceImage_605280; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_605294 = newJObject()
  if body != nil:
    body_605294 = body
  result = call_605293.call(nil, nil, nil, nil, body_605294)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_605280(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_605281, base: "/",
    url: url_CopyWorkspaceImage_605282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_605295 = ref object of OpenApiRestCall_604658
proc url_CreateIpGroup_605297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIpGroup_605296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605298 = header.getOrDefault("X-Amz-Target")
  valid_605298 = validateParameter(valid_605298, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_605298 != nil:
    section.add "X-Amz-Target", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-Signature")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-Signature", valid_605299
  var valid_605300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605300 = validateParameter(valid_605300, JString, required = false,
                                 default = nil)
  if valid_605300 != nil:
    section.add "X-Amz-Content-Sha256", valid_605300
  var valid_605301 = header.getOrDefault("X-Amz-Date")
  valid_605301 = validateParameter(valid_605301, JString, required = false,
                                 default = nil)
  if valid_605301 != nil:
    section.add "X-Amz-Date", valid_605301
  var valid_605302 = header.getOrDefault("X-Amz-Credential")
  valid_605302 = validateParameter(valid_605302, JString, required = false,
                                 default = nil)
  if valid_605302 != nil:
    section.add "X-Amz-Credential", valid_605302
  var valid_605303 = header.getOrDefault("X-Amz-Security-Token")
  valid_605303 = validateParameter(valid_605303, JString, required = false,
                                 default = nil)
  if valid_605303 != nil:
    section.add "X-Amz-Security-Token", valid_605303
  var valid_605304 = header.getOrDefault("X-Amz-Algorithm")
  valid_605304 = validateParameter(valid_605304, JString, required = false,
                                 default = nil)
  if valid_605304 != nil:
    section.add "X-Amz-Algorithm", valid_605304
  var valid_605305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605305 = validateParameter(valid_605305, JString, required = false,
                                 default = nil)
  if valid_605305 != nil:
    section.add "X-Amz-SignedHeaders", valid_605305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605307: Call_CreateIpGroup_605295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_605307.validator(path, query, header, formData, body)
  let scheme = call_605307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605307.url(scheme.get, call_605307.host, call_605307.base,
                         call_605307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605307, url, valid)

proc call*(call_605308: Call_CreateIpGroup_605295; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_605309 = newJObject()
  if body != nil:
    body_605309 = body
  result = call_605308.call(nil, nil, nil, nil, body_605309)

var createIpGroup* = Call_CreateIpGroup_605295(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_605296, base: "/", url: url_CreateIpGroup_605297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_605310 = ref object of OpenApiRestCall_604658
proc url_CreateTags_605312(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_605311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605313 = header.getOrDefault("X-Amz-Target")
  valid_605313 = validateParameter(valid_605313, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_605313 != nil:
    section.add "X-Amz-Target", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-Signature")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-Signature", valid_605314
  var valid_605315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605315 = validateParameter(valid_605315, JString, required = false,
                                 default = nil)
  if valid_605315 != nil:
    section.add "X-Amz-Content-Sha256", valid_605315
  var valid_605316 = header.getOrDefault("X-Amz-Date")
  valid_605316 = validateParameter(valid_605316, JString, required = false,
                                 default = nil)
  if valid_605316 != nil:
    section.add "X-Amz-Date", valid_605316
  var valid_605317 = header.getOrDefault("X-Amz-Credential")
  valid_605317 = validateParameter(valid_605317, JString, required = false,
                                 default = nil)
  if valid_605317 != nil:
    section.add "X-Amz-Credential", valid_605317
  var valid_605318 = header.getOrDefault("X-Amz-Security-Token")
  valid_605318 = validateParameter(valid_605318, JString, required = false,
                                 default = nil)
  if valid_605318 != nil:
    section.add "X-Amz-Security-Token", valid_605318
  var valid_605319 = header.getOrDefault("X-Amz-Algorithm")
  valid_605319 = validateParameter(valid_605319, JString, required = false,
                                 default = nil)
  if valid_605319 != nil:
    section.add "X-Amz-Algorithm", valid_605319
  var valid_605320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605320 = validateParameter(valid_605320, JString, required = false,
                                 default = nil)
  if valid_605320 != nil:
    section.add "X-Amz-SignedHeaders", valid_605320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605322: Call_CreateTags_605310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_605322.validator(path, query, header, formData, body)
  let scheme = call_605322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605322.url(scheme.get, call_605322.host, call_605322.base,
                         call_605322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605322, url, valid)

proc call*(call_605323: Call_CreateTags_605310; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_605324 = newJObject()
  if body != nil:
    body_605324 = body
  result = call_605323.call(nil, nil, nil, nil, body_605324)

var createTags* = Call_CreateTags_605310(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_605311,
                                      base: "/", url: url_CreateTags_605312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_605325 = ref object of OpenApiRestCall_604658
proc url_CreateWorkspaces_605327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkspaces_605326(path: JsonNode; query: JsonNode;
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
  var valid_605328 = header.getOrDefault("X-Amz-Target")
  valid_605328 = validateParameter(valid_605328, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_605328 != nil:
    section.add "X-Amz-Target", valid_605328
  var valid_605329 = header.getOrDefault("X-Amz-Signature")
  valid_605329 = validateParameter(valid_605329, JString, required = false,
                                 default = nil)
  if valid_605329 != nil:
    section.add "X-Amz-Signature", valid_605329
  var valid_605330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605330 = validateParameter(valid_605330, JString, required = false,
                                 default = nil)
  if valid_605330 != nil:
    section.add "X-Amz-Content-Sha256", valid_605330
  var valid_605331 = header.getOrDefault("X-Amz-Date")
  valid_605331 = validateParameter(valid_605331, JString, required = false,
                                 default = nil)
  if valid_605331 != nil:
    section.add "X-Amz-Date", valid_605331
  var valid_605332 = header.getOrDefault("X-Amz-Credential")
  valid_605332 = validateParameter(valid_605332, JString, required = false,
                                 default = nil)
  if valid_605332 != nil:
    section.add "X-Amz-Credential", valid_605332
  var valid_605333 = header.getOrDefault("X-Amz-Security-Token")
  valid_605333 = validateParameter(valid_605333, JString, required = false,
                                 default = nil)
  if valid_605333 != nil:
    section.add "X-Amz-Security-Token", valid_605333
  var valid_605334 = header.getOrDefault("X-Amz-Algorithm")
  valid_605334 = validateParameter(valid_605334, JString, required = false,
                                 default = nil)
  if valid_605334 != nil:
    section.add "X-Amz-Algorithm", valid_605334
  var valid_605335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605335 = validateParameter(valid_605335, JString, required = false,
                                 default = nil)
  if valid_605335 != nil:
    section.add "X-Amz-SignedHeaders", valid_605335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605337: Call_CreateWorkspaces_605325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_605337.validator(path, query, header, formData, body)
  let scheme = call_605337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605337.url(scheme.get, call_605337.host, call_605337.base,
                         call_605337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605337, url, valid)

proc call*(call_605338: Call_CreateWorkspaces_605325; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_605339 = newJObject()
  if body != nil:
    body_605339 = body
  result = call_605338.call(nil, nil, nil, nil, body_605339)

var createWorkspaces* = Call_CreateWorkspaces_605325(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_605326, base: "/",
    url: url_CreateWorkspaces_605327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_605340 = ref object of OpenApiRestCall_604658
proc url_DeleteIpGroup_605342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIpGroup_605341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605343 = header.getOrDefault("X-Amz-Target")
  valid_605343 = validateParameter(valid_605343, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_605343 != nil:
    section.add "X-Amz-Target", valid_605343
  var valid_605344 = header.getOrDefault("X-Amz-Signature")
  valid_605344 = validateParameter(valid_605344, JString, required = false,
                                 default = nil)
  if valid_605344 != nil:
    section.add "X-Amz-Signature", valid_605344
  var valid_605345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605345 = validateParameter(valid_605345, JString, required = false,
                                 default = nil)
  if valid_605345 != nil:
    section.add "X-Amz-Content-Sha256", valid_605345
  var valid_605346 = header.getOrDefault("X-Amz-Date")
  valid_605346 = validateParameter(valid_605346, JString, required = false,
                                 default = nil)
  if valid_605346 != nil:
    section.add "X-Amz-Date", valid_605346
  var valid_605347 = header.getOrDefault("X-Amz-Credential")
  valid_605347 = validateParameter(valid_605347, JString, required = false,
                                 default = nil)
  if valid_605347 != nil:
    section.add "X-Amz-Credential", valid_605347
  var valid_605348 = header.getOrDefault("X-Amz-Security-Token")
  valid_605348 = validateParameter(valid_605348, JString, required = false,
                                 default = nil)
  if valid_605348 != nil:
    section.add "X-Amz-Security-Token", valid_605348
  var valid_605349 = header.getOrDefault("X-Amz-Algorithm")
  valid_605349 = validateParameter(valid_605349, JString, required = false,
                                 default = nil)
  if valid_605349 != nil:
    section.add "X-Amz-Algorithm", valid_605349
  var valid_605350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605350 = validateParameter(valid_605350, JString, required = false,
                                 default = nil)
  if valid_605350 != nil:
    section.add "X-Amz-SignedHeaders", valid_605350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605352: Call_DeleteIpGroup_605340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_605352.validator(path, query, header, formData, body)
  let scheme = call_605352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605352.url(scheme.get, call_605352.host, call_605352.base,
                         call_605352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605352, url, valid)

proc call*(call_605353: Call_DeleteIpGroup_605340; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_605354 = newJObject()
  if body != nil:
    body_605354 = body
  result = call_605353.call(nil, nil, nil, nil, body_605354)

var deleteIpGroup* = Call_DeleteIpGroup_605340(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_605341, base: "/", url: url_DeleteIpGroup_605342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_605355 = ref object of OpenApiRestCall_604658
proc url_DeleteTags_605357(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_605356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605358 = header.getOrDefault("X-Amz-Target")
  valid_605358 = validateParameter(valid_605358, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_605358 != nil:
    section.add "X-Amz-Target", valid_605358
  var valid_605359 = header.getOrDefault("X-Amz-Signature")
  valid_605359 = validateParameter(valid_605359, JString, required = false,
                                 default = nil)
  if valid_605359 != nil:
    section.add "X-Amz-Signature", valid_605359
  var valid_605360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605360 = validateParameter(valid_605360, JString, required = false,
                                 default = nil)
  if valid_605360 != nil:
    section.add "X-Amz-Content-Sha256", valid_605360
  var valid_605361 = header.getOrDefault("X-Amz-Date")
  valid_605361 = validateParameter(valid_605361, JString, required = false,
                                 default = nil)
  if valid_605361 != nil:
    section.add "X-Amz-Date", valid_605361
  var valid_605362 = header.getOrDefault("X-Amz-Credential")
  valid_605362 = validateParameter(valid_605362, JString, required = false,
                                 default = nil)
  if valid_605362 != nil:
    section.add "X-Amz-Credential", valid_605362
  var valid_605363 = header.getOrDefault("X-Amz-Security-Token")
  valid_605363 = validateParameter(valid_605363, JString, required = false,
                                 default = nil)
  if valid_605363 != nil:
    section.add "X-Amz-Security-Token", valid_605363
  var valid_605364 = header.getOrDefault("X-Amz-Algorithm")
  valid_605364 = validateParameter(valid_605364, JString, required = false,
                                 default = nil)
  if valid_605364 != nil:
    section.add "X-Amz-Algorithm", valid_605364
  var valid_605365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605365 = validateParameter(valid_605365, JString, required = false,
                                 default = nil)
  if valid_605365 != nil:
    section.add "X-Amz-SignedHeaders", valid_605365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605367: Call_DeleteTags_605355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_605367.validator(path, query, header, formData, body)
  let scheme = call_605367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605367.url(scheme.get, call_605367.host, call_605367.base,
                         call_605367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605367, url, valid)

proc call*(call_605368: Call_DeleteTags_605355; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_605369 = newJObject()
  if body != nil:
    body_605369 = body
  result = call_605368.call(nil, nil, nil, nil, body_605369)

var deleteTags* = Call_DeleteTags_605355(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_605356,
                                      base: "/", url: url_DeleteTags_605357,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_605370 = ref object of OpenApiRestCall_604658
proc url_DeleteWorkspaceImage_605372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkspaceImage_605371(path: JsonNode; query: JsonNode;
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
  var valid_605373 = header.getOrDefault("X-Amz-Target")
  valid_605373 = validateParameter(valid_605373, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_605373 != nil:
    section.add "X-Amz-Target", valid_605373
  var valid_605374 = header.getOrDefault("X-Amz-Signature")
  valid_605374 = validateParameter(valid_605374, JString, required = false,
                                 default = nil)
  if valid_605374 != nil:
    section.add "X-Amz-Signature", valid_605374
  var valid_605375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605375 = validateParameter(valid_605375, JString, required = false,
                                 default = nil)
  if valid_605375 != nil:
    section.add "X-Amz-Content-Sha256", valid_605375
  var valid_605376 = header.getOrDefault("X-Amz-Date")
  valid_605376 = validateParameter(valid_605376, JString, required = false,
                                 default = nil)
  if valid_605376 != nil:
    section.add "X-Amz-Date", valid_605376
  var valid_605377 = header.getOrDefault("X-Amz-Credential")
  valid_605377 = validateParameter(valid_605377, JString, required = false,
                                 default = nil)
  if valid_605377 != nil:
    section.add "X-Amz-Credential", valid_605377
  var valid_605378 = header.getOrDefault("X-Amz-Security-Token")
  valid_605378 = validateParameter(valid_605378, JString, required = false,
                                 default = nil)
  if valid_605378 != nil:
    section.add "X-Amz-Security-Token", valid_605378
  var valid_605379 = header.getOrDefault("X-Amz-Algorithm")
  valid_605379 = validateParameter(valid_605379, JString, required = false,
                                 default = nil)
  if valid_605379 != nil:
    section.add "X-Amz-Algorithm", valid_605379
  var valid_605380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "X-Amz-SignedHeaders", valid_605380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605382: Call_DeleteWorkspaceImage_605370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_605382.validator(path, query, header, formData, body)
  let scheme = call_605382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605382.url(scheme.get, call_605382.host, call_605382.base,
                         call_605382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605382, url, valid)

proc call*(call_605383: Call_DeleteWorkspaceImage_605370; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_605384 = newJObject()
  if body != nil:
    body_605384 = body
  result = call_605383.call(nil, nil, nil, nil, body_605384)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_605370(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_605371, base: "/",
    url: url_DeleteWorkspaceImage_605372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWorkspaceDirectory_605385 = ref object of OpenApiRestCall_604658
proc url_DeregisterWorkspaceDirectory_605387(protocol: Scheme; host: string;
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

proc validate_DeregisterWorkspaceDirectory_605386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
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
  var valid_605388 = header.getOrDefault("X-Amz-Target")
  valid_605388 = validateParameter(valid_605388, JString, required = true, default = newJString(
      "WorkspacesService.DeregisterWorkspaceDirectory"))
  if valid_605388 != nil:
    section.add "X-Amz-Target", valid_605388
  var valid_605389 = header.getOrDefault("X-Amz-Signature")
  valid_605389 = validateParameter(valid_605389, JString, required = false,
                                 default = nil)
  if valid_605389 != nil:
    section.add "X-Amz-Signature", valid_605389
  var valid_605390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605390 = validateParameter(valid_605390, JString, required = false,
                                 default = nil)
  if valid_605390 != nil:
    section.add "X-Amz-Content-Sha256", valid_605390
  var valid_605391 = header.getOrDefault("X-Amz-Date")
  valid_605391 = validateParameter(valid_605391, JString, required = false,
                                 default = nil)
  if valid_605391 != nil:
    section.add "X-Amz-Date", valid_605391
  var valid_605392 = header.getOrDefault("X-Amz-Credential")
  valid_605392 = validateParameter(valid_605392, JString, required = false,
                                 default = nil)
  if valid_605392 != nil:
    section.add "X-Amz-Credential", valid_605392
  var valid_605393 = header.getOrDefault("X-Amz-Security-Token")
  valid_605393 = validateParameter(valid_605393, JString, required = false,
                                 default = nil)
  if valid_605393 != nil:
    section.add "X-Amz-Security-Token", valid_605393
  var valid_605394 = header.getOrDefault("X-Amz-Algorithm")
  valid_605394 = validateParameter(valid_605394, JString, required = false,
                                 default = nil)
  if valid_605394 != nil:
    section.add "X-Amz-Algorithm", valid_605394
  var valid_605395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605395 = validateParameter(valid_605395, JString, required = false,
                                 default = nil)
  if valid_605395 != nil:
    section.add "X-Amz-SignedHeaders", valid_605395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605397: Call_DeregisterWorkspaceDirectory_605385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ## 
  let valid = call_605397.validator(path, query, header, formData, body)
  let scheme = call_605397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605397.url(scheme.get, call_605397.host, call_605397.base,
                         call_605397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605397, url, valid)

proc call*(call_605398: Call_DeregisterWorkspaceDirectory_605385; body: JsonNode): Recallable =
  ## deregisterWorkspaceDirectory
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ##   body: JObject (required)
  var body_605399 = newJObject()
  if body != nil:
    body_605399 = body
  result = call_605398.call(nil, nil, nil, nil, body_605399)

var deregisterWorkspaceDirectory* = Call_DeregisterWorkspaceDirectory_605385(
    name: "deregisterWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeregisterWorkspaceDirectory",
    validator: validate_DeregisterWorkspaceDirectory_605386, base: "/",
    url: url_DeregisterWorkspaceDirectory_605387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_605400 = ref object of OpenApiRestCall_604658
proc url_DescribeAccount_605402(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAccount_605401(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
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
  var valid_605403 = header.getOrDefault("X-Amz-Target")
  valid_605403 = validateParameter(valid_605403, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_605403 != nil:
    section.add "X-Amz-Target", valid_605403
  var valid_605404 = header.getOrDefault("X-Amz-Signature")
  valid_605404 = validateParameter(valid_605404, JString, required = false,
                                 default = nil)
  if valid_605404 != nil:
    section.add "X-Amz-Signature", valid_605404
  var valid_605405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605405 = validateParameter(valid_605405, JString, required = false,
                                 default = nil)
  if valid_605405 != nil:
    section.add "X-Amz-Content-Sha256", valid_605405
  var valid_605406 = header.getOrDefault("X-Amz-Date")
  valid_605406 = validateParameter(valid_605406, JString, required = false,
                                 default = nil)
  if valid_605406 != nil:
    section.add "X-Amz-Date", valid_605406
  var valid_605407 = header.getOrDefault("X-Amz-Credential")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-Credential", valid_605407
  var valid_605408 = header.getOrDefault("X-Amz-Security-Token")
  valid_605408 = validateParameter(valid_605408, JString, required = false,
                                 default = nil)
  if valid_605408 != nil:
    section.add "X-Amz-Security-Token", valid_605408
  var valid_605409 = header.getOrDefault("X-Amz-Algorithm")
  valid_605409 = validateParameter(valid_605409, JString, required = false,
                                 default = nil)
  if valid_605409 != nil:
    section.add "X-Amz-Algorithm", valid_605409
  var valid_605410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605410 = validateParameter(valid_605410, JString, required = false,
                                 default = nil)
  if valid_605410 != nil:
    section.add "X-Amz-SignedHeaders", valid_605410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605412: Call_DescribeAccount_605400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_605412.validator(path, query, header, formData, body)
  let scheme = call_605412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605412.url(scheme.get, call_605412.host, call_605412.base,
                         call_605412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605412, url, valid)

proc call*(call_605413: Call_DescribeAccount_605400; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_605414 = newJObject()
  if body != nil:
    body_605414 = body
  result = call_605413.call(nil, nil, nil, nil, body_605414)

var describeAccount* = Call_DescribeAccount_605400(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_605401, base: "/", url: url_DescribeAccount_605402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_605415 = ref object of OpenApiRestCall_604658
proc url_DescribeAccountModifications_605417(protocol: Scheme; host: string;
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

proc validate_DescribeAccountModifications_605416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
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
  var valid_605418 = header.getOrDefault("X-Amz-Target")
  valid_605418 = validateParameter(valid_605418, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_605418 != nil:
    section.add "X-Amz-Target", valid_605418
  var valid_605419 = header.getOrDefault("X-Amz-Signature")
  valid_605419 = validateParameter(valid_605419, JString, required = false,
                                 default = nil)
  if valid_605419 != nil:
    section.add "X-Amz-Signature", valid_605419
  var valid_605420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605420 = validateParameter(valid_605420, JString, required = false,
                                 default = nil)
  if valid_605420 != nil:
    section.add "X-Amz-Content-Sha256", valid_605420
  var valid_605421 = header.getOrDefault("X-Amz-Date")
  valid_605421 = validateParameter(valid_605421, JString, required = false,
                                 default = nil)
  if valid_605421 != nil:
    section.add "X-Amz-Date", valid_605421
  var valid_605422 = header.getOrDefault("X-Amz-Credential")
  valid_605422 = validateParameter(valid_605422, JString, required = false,
                                 default = nil)
  if valid_605422 != nil:
    section.add "X-Amz-Credential", valid_605422
  var valid_605423 = header.getOrDefault("X-Amz-Security-Token")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Security-Token", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Algorithm")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Algorithm", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-SignedHeaders", valid_605425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605427: Call_DescribeAccountModifications_605415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_605427.validator(path, query, header, formData, body)
  let scheme = call_605427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605427.url(scheme.get, call_605427.host, call_605427.base,
                         call_605427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605427, url, valid)

proc call*(call_605428: Call_DescribeAccountModifications_605415; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_605429 = newJObject()
  if body != nil:
    body_605429 = body
  result = call_605428.call(nil, nil, nil, nil, body_605429)

var describeAccountModifications* = Call_DescribeAccountModifications_605415(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_605416, base: "/",
    url: url_DescribeAccountModifications_605417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_605430 = ref object of OpenApiRestCall_604658
proc url_DescribeClientProperties_605432(protocol: Scheme; host: string;
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

proc validate_DescribeClientProperties_605431(path: JsonNode; query: JsonNode;
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
  var valid_605433 = header.getOrDefault("X-Amz-Target")
  valid_605433 = validateParameter(valid_605433, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_605433 != nil:
    section.add "X-Amz-Target", valid_605433
  var valid_605434 = header.getOrDefault("X-Amz-Signature")
  valid_605434 = validateParameter(valid_605434, JString, required = false,
                                 default = nil)
  if valid_605434 != nil:
    section.add "X-Amz-Signature", valid_605434
  var valid_605435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605435 = validateParameter(valid_605435, JString, required = false,
                                 default = nil)
  if valid_605435 != nil:
    section.add "X-Amz-Content-Sha256", valid_605435
  var valid_605436 = header.getOrDefault("X-Amz-Date")
  valid_605436 = validateParameter(valid_605436, JString, required = false,
                                 default = nil)
  if valid_605436 != nil:
    section.add "X-Amz-Date", valid_605436
  var valid_605437 = header.getOrDefault("X-Amz-Credential")
  valid_605437 = validateParameter(valid_605437, JString, required = false,
                                 default = nil)
  if valid_605437 != nil:
    section.add "X-Amz-Credential", valid_605437
  var valid_605438 = header.getOrDefault("X-Amz-Security-Token")
  valid_605438 = validateParameter(valid_605438, JString, required = false,
                                 default = nil)
  if valid_605438 != nil:
    section.add "X-Amz-Security-Token", valid_605438
  var valid_605439 = header.getOrDefault("X-Amz-Algorithm")
  valid_605439 = validateParameter(valid_605439, JString, required = false,
                                 default = nil)
  if valid_605439 != nil:
    section.add "X-Amz-Algorithm", valid_605439
  var valid_605440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605440 = validateParameter(valid_605440, JString, required = false,
                                 default = nil)
  if valid_605440 != nil:
    section.add "X-Amz-SignedHeaders", valid_605440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605442: Call_DescribeClientProperties_605430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_605442.validator(path, query, header, formData, body)
  let scheme = call_605442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605442.url(scheme.get, call_605442.host, call_605442.base,
                         call_605442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605442, url, valid)

proc call*(call_605443: Call_DescribeClientProperties_605430; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_605444 = newJObject()
  if body != nil:
    body_605444 = body
  result = call_605443.call(nil, nil, nil, nil, body_605444)

var describeClientProperties* = Call_DescribeClientProperties_605430(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_605431, base: "/",
    url: url_DescribeClientProperties_605432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_605445 = ref object of OpenApiRestCall_604658
proc url_DescribeIpGroups_605447(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIpGroups_605446(path: JsonNode; query: JsonNode;
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
  var valid_605448 = header.getOrDefault("X-Amz-Target")
  valid_605448 = validateParameter(valid_605448, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_605448 != nil:
    section.add "X-Amz-Target", valid_605448
  var valid_605449 = header.getOrDefault("X-Amz-Signature")
  valid_605449 = validateParameter(valid_605449, JString, required = false,
                                 default = nil)
  if valid_605449 != nil:
    section.add "X-Amz-Signature", valid_605449
  var valid_605450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605450 = validateParameter(valid_605450, JString, required = false,
                                 default = nil)
  if valid_605450 != nil:
    section.add "X-Amz-Content-Sha256", valid_605450
  var valid_605451 = header.getOrDefault("X-Amz-Date")
  valid_605451 = validateParameter(valid_605451, JString, required = false,
                                 default = nil)
  if valid_605451 != nil:
    section.add "X-Amz-Date", valid_605451
  var valid_605452 = header.getOrDefault("X-Amz-Credential")
  valid_605452 = validateParameter(valid_605452, JString, required = false,
                                 default = nil)
  if valid_605452 != nil:
    section.add "X-Amz-Credential", valid_605452
  var valid_605453 = header.getOrDefault("X-Amz-Security-Token")
  valid_605453 = validateParameter(valid_605453, JString, required = false,
                                 default = nil)
  if valid_605453 != nil:
    section.add "X-Amz-Security-Token", valid_605453
  var valid_605454 = header.getOrDefault("X-Amz-Algorithm")
  valid_605454 = validateParameter(valid_605454, JString, required = false,
                                 default = nil)
  if valid_605454 != nil:
    section.add "X-Amz-Algorithm", valid_605454
  var valid_605455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605455 = validateParameter(valid_605455, JString, required = false,
                                 default = nil)
  if valid_605455 != nil:
    section.add "X-Amz-SignedHeaders", valid_605455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605457: Call_DescribeIpGroups_605445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_605457.validator(path, query, header, formData, body)
  let scheme = call_605457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605457.url(scheme.get, call_605457.host, call_605457.base,
                         call_605457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605457, url, valid)

proc call*(call_605458: Call_DescribeIpGroups_605445; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_605459 = newJObject()
  if body != nil:
    body_605459 = body
  result = call_605458.call(nil, nil, nil, nil, body_605459)

var describeIpGroups* = Call_DescribeIpGroups_605445(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_605446, base: "/",
    url: url_DescribeIpGroups_605447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_605460 = ref object of OpenApiRestCall_604658
proc url_DescribeTags_605462(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_605461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605463 = header.getOrDefault("X-Amz-Target")
  valid_605463 = validateParameter(valid_605463, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_605463 != nil:
    section.add "X-Amz-Target", valid_605463
  var valid_605464 = header.getOrDefault("X-Amz-Signature")
  valid_605464 = validateParameter(valid_605464, JString, required = false,
                                 default = nil)
  if valid_605464 != nil:
    section.add "X-Amz-Signature", valid_605464
  var valid_605465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605465 = validateParameter(valid_605465, JString, required = false,
                                 default = nil)
  if valid_605465 != nil:
    section.add "X-Amz-Content-Sha256", valid_605465
  var valid_605466 = header.getOrDefault("X-Amz-Date")
  valid_605466 = validateParameter(valid_605466, JString, required = false,
                                 default = nil)
  if valid_605466 != nil:
    section.add "X-Amz-Date", valid_605466
  var valid_605467 = header.getOrDefault("X-Amz-Credential")
  valid_605467 = validateParameter(valid_605467, JString, required = false,
                                 default = nil)
  if valid_605467 != nil:
    section.add "X-Amz-Credential", valid_605467
  var valid_605468 = header.getOrDefault("X-Amz-Security-Token")
  valid_605468 = validateParameter(valid_605468, JString, required = false,
                                 default = nil)
  if valid_605468 != nil:
    section.add "X-Amz-Security-Token", valid_605468
  var valid_605469 = header.getOrDefault("X-Amz-Algorithm")
  valid_605469 = validateParameter(valid_605469, JString, required = false,
                                 default = nil)
  if valid_605469 != nil:
    section.add "X-Amz-Algorithm", valid_605469
  var valid_605470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605470 = validateParameter(valid_605470, JString, required = false,
                                 default = nil)
  if valid_605470 != nil:
    section.add "X-Amz-SignedHeaders", valid_605470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605472: Call_DescribeTags_605460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_605472.validator(path, query, header, formData, body)
  let scheme = call_605472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605472.url(scheme.get, call_605472.host, call_605472.base,
                         call_605472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605472, url, valid)

proc call*(call_605473: Call_DescribeTags_605460; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_605474 = newJObject()
  if body != nil:
    body_605474 = body
  result = call_605473.call(nil, nil, nil, nil, body_605474)

var describeTags* = Call_DescribeTags_605460(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_605461, base: "/", url: url_DescribeTags_605462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_605475 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspaceBundles_605477(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceBundles_605476(path: JsonNode; query: JsonNode;
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
  var valid_605478 = query.getOrDefault("NextToken")
  valid_605478 = validateParameter(valid_605478, JString, required = false,
                                 default = nil)
  if valid_605478 != nil:
    section.add "NextToken", valid_605478
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
  var valid_605479 = header.getOrDefault("X-Amz-Target")
  valid_605479 = validateParameter(valid_605479, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_605479 != nil:
    section.add "X-Amz-Target", valid_605479
  var valid_605480 = header.getOrDefault("X-Amz-Signature")
  valid_605480 = validateParameter(valid_605480, JString, required = false,
                                 default = nil)
  if valid_605480 != nil:
    section.add "X-Amz-Signature", valid_605480
  var valid_605481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605481 = validateParameter(valid_605481, JString, required = false,
                                 default = nil)
  if valid_605481 != nil:
    section.add "X-Amz-Content-Sha256", valid_605481
  var valid_605482 = header.getOrDefault("X-Amz-Date")
  valid_605482 = validateParameter(valid_605482, JString, required = false,
                                 default = nil)
  if valid_605482 != nil:
    section.add "X-Amz-Date", valid_605482
  var valid_605483 = header.getOrDefault("X-Amz-Credential")
  valid_605483 = validateParameter(valid_605483, JString, required = false,
                                 default = nil)
  if valid_605483 != nil:
    section.add "X-Amz-Credential", valid_605483
  var valid_605484 = header.getOrDefault("X-Amz-Security-Token")
  valid_605484 = validateParameter(valid_605484, JString, required = false,
                                 default = nil)
  if valid_605484 != nil:
    section.add "X-Amz-Security-Token", valid_605484
  var valid_605485 = header.getOrDefault("X-Amz-Algorithm")
  valid_605485 = validateParameter(valid_605485, JString, required = false,
                                 default = nil)
  if valid_605485 != nil:
    section.add "X-Amz-Algorithm", valid_605485
  var valid_605486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605486 = validateParameter(valid_605486, JString, required = false,
                                 default = nil)
  if valid_605486 != nil:
    section.add "X-Amz-SignedHeaders", valid_605486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605488: Call_DescribeWorkspaceBundles_605475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_605488.validator(path, query, header, formData, body)
  let scheme = call_605488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605488.url(scheme.get, call_605488.host, call_605488.base,
                         call_605488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605488, url, valid)

proc call*(call_605489: Call_DescribeWorkspaceBundles_605475; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605490 = newJObject()
  var body_605491 = newJObject()
  add(query_605490, "NextToken", newJString(NextToken))
  if body != nil:
    body_605491 = body
  result = call_605489.call(nil, query_605490, nil, nil, body_605491)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_605475(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_605476, base: "/",
    url: url_DescribeWorkspaceBundles_605477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_605493 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspaceDirectories_605495(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceDirectories_605494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605496 = query.getOrDefault("NextToken")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "NextToken", valid_605496
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
  var valid_605497 = header.getOrDefault("X-Amz-Target")
  valid_605497 = validateParameter(valid_605497, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_605497 != nil:
    section.add "X-Amz-Target", valid_605497
  var valid_605498 = header.getOrDefault("X-Amz-Signature")
  valid_605498 = validateParameter(valid_605498, JString, required = false,
                                 default = nil)
  if valid_605498 != nil:
    section.add "X-Amz-Signature", valid_605498
  var valid_605499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605499 = validateParameter(valid_605499, JString, required = false,
                                 default = nil)
  if valid_605499 != nil:
    section.add "X-Amz-Content-Sha256", valid_605499
  var valid_605500 = header.getOrDefault("X-Amz-Date")
  valid_605500 = validateParameter(valid_605500, JString, required = false,
                                 default = nil)
  if valid_605500 != nil:
    section.add "X-Amz-Date", valid_605500
  var valid_605501 = header.getOrDefault("X-Amz-Credential")
  valid_605501 = validateParameter(valid_605501, JString, required = false,
                                 default = nil)
  if valid_605501 != nil:
    section.add "X-Amz-Credential", valid_605501
  var valid_605502 = header.getOrDefault("X-Amz-Security-Token")
  valid_605502 = validateParameter(valid_605502, JString, required = false,
                                 default = nil)
  if valid_605502 != nil:
    section.add "X-Amz-Security-Token", valid_605502
  var valid_605503 = header.getOrDefault("X-Amz-Algorithm")
  valid_605503 = validateParameter(valid_605503, JString, required = false,
                                 default = nil)
  if valid_605503 != nil:
    section.add "X-Amz-Algorithm", valid_605503
  var valid_605504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605504 = validateParameter(valid_605504, JString, required = false,
                                 default = nil)
  if valid_605504 != nil:
    section.add "X-Amz-SignedHeaders", valid_605504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605506: Call_DescribeWorkspaceDirectories_605493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_605506.validator(path, query, header, formData, body)
  let scheme = call_605506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605506.url(scheme.get, call_605506.host, call_605506.base,
                         call_605506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605506, url, valid)

proc call*(call_605507: Call_DescribeWorkspaceDirectories_605493; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605508 = newJObject()
  var body_605509 = newJObject()
  add(query_605508, "NextToken", newJString(NextToken))
  if body != nil:
    body_605509 = body
  result = call_605507.call(nil, query_605508, nil, nil, body_605509)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_605493(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_605494, base: "/",
    url: url_DescribeWorkspaceDirectories_605495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_605510 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspaceImages_605512(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaceImages_605511(path: JsonNode; query: JsonNode;
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
  var valid_605513 = header.getOrDefault("X-Amz-Target")
  valid_605513 = validateParameter(valid_605513, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_605513 != nil:
    section.add "X-Amz-Target", valid_605513
  var valid_605514 = header.getOrDefault("X-Amz-Signature")
  valid_605514 = validateParameter(valid_605514, JString, required = false,
                                 default = nil)
  if valid_605514 != nil:
    section.add "X-Amz-Signature", valid_605514
  var valid_605515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605515 = validateParameter(valid_605515, JString, required = false,
                                 default = nil)
  if valid_605515 != nil:
    section.add "X-Amz-Content-Sha256", valid_605515
  var valid_605516 = header.getOrDefault("X-Amz-Date")
  valid_605516 = validateParameter(valid_605516, JString, required = false,
                                 default = nil)
  if valid_605516 != nil:
    section.add "X-Amz-Date", valid_605516
  var valid_605517 = header.getOrDefault("X-Amz-Credential")
  valid_605517 = validateParameter(valid_605517, JString, required = false,
                                 default = nil)
  if valid_605517 != nil:
    section.add "X-Amz-Credential", valid_605517
  var valid_605518 = header.getOrDefault("X-Amz-Security-Token")
  valid_605518 = validateParameter(valid_605518, JString, required = false,
                                 default = nil)
  if valid_605518 != nil:
    section.add "X-Amz-Security-Token", valid_605518
  var valid_605519 = header.getOrDefault("X-Amz-Algorithm")
  valid_605519 = validateParameter(valid_605519, JString, required = false,
                                 default = nil)
  if valid_605519 != nil:
    section.add "X-Amz-Algorithm", valid_605519
  var valid_605520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605520 = validateParameter(valid_605520, JString, required = false,
                                 default = nil)
  if valid_605520 != nil:
    section.add "X-Amz-SignedHeaders", valid_605520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605522: Call_DescribeWorkspaceImages_605510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_605522.validator(path, query, header, formData, body)
  let scheme = call_605522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605522.url(scheme.get, call_605522.host, call_605522.base,
                         call_605522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605522, url, valid)

proc call*(call_605523: Call_DescribeWorkspaceImages_605510; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_605524 = newJObject()
  if body != nil:
    body_605524 = body
  result = call_605523.call(nil, nil, nil, nil, body_605524)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_605510(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_605511, base: "/",
    url: url_DescribeWorkspaceImages_605512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_605525 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspaceSnapshots_605527(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceSnapshots_605526(path: JsonNode; query: JsonNode;
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
  var valid_605528 = header.getOrDefault("X-Amz-Target")
  valid_605528 = validateParameter(valid_605528, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_605528 != nil:
    section.add "X-Amz-Target", valid_605528
  var valid_605529 = header.getOrDefault("X-Amz-Signature")
  valid_605529 = validateParameter(valid_605529, JString, required = false,
                                 default = nil)
  if valid_605529 != nil:
    section.add "X-Amz-Signature", valid_605529
  var valid_605530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605530 = validateParameter(valid_605530, JString, required = false,
                                 default = nil)
  if valid_605530 != nil:
    section.add "X-Amz-Content-Sha256", valid_605530
  var valid_605531 = header.getOrDefault("X-Amz-Date")
  valid_605531 = validateParameter(valid_605531, JString, required = false,
                                 default = nil)
  if valid_605531 != nil:
    section.add "X-Amz-Date", valid_605531
  var valid_605532 = header.getOrDefault("X-Amz-Credential")
  valid_605532 = validateParameter(valid_605532, JString, required = false,
                                 default = nil)
  if valid_605532 != nil:
    section.add "X-Amz-Credential", valid_605532
  var valid_605533 = header.getOrDefault("X-Amz-Security-Token")
  valid_605533 = validateParameter(valid_605533, JString, required = false,
                                 default = nil)
  if valid_605533 != nil:
    section.add "X-Amz-Security-Token", valid_605533
  var valid_605534 = header.getOrDefault("X-Amz-Algorithm")
  valid_605534 = validateParameter(valid_605534, JString, required = false,
                                 default = nil)
  if valid_605534 != nil:
    section.add "X-Amz-Algorithm", valid_605534
  var valid_605535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605535 = validateParameter(valid_605535, JString, required = false,
                                 default = nil)
  if valid_605535 != nil:
    section.add "X-Amz-SignedHeaders", valid_605535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605537: Call_DescribeWorkspaceSnapshots_605525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_605537.validator(path, query, header, formData, body)
  let scheme = call_605537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605537.url(scheme.get, call_605537.host, call_605537.base,
                         call_605537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605537, url, valid)

proc call*(call_605538: Call_DescribeWorkspaceSnapshots_605525; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_605539 = newJObject()
  if body != nil:
    body_605539 = body
  result = call_605538.call(nil, nil, nil, nil, body_605539)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_605525(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_605526, base: "/",
    url: url_DescribeWorkspaceSnapshots_605527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_605540 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspaces_605542(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaces_605541(path: JsonNode; query: JsonNode;
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
  var valid_605543 = query.getOrDefault("NextToken")
  valid_605543 = validateParameter(valid_605543, JString, required = false,
                                 default = nil)
  if valid_605543 != nil:
    section.add "NextToken", valid_605543
  var valid_605544 = query.getOrDefault("Limit")
  valid_605544 = validateParameter(valid_605544, JString, required = false,
                                 default = nil)
  if valid_605544 != nil:
    section.add "Limit", valid_605544
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
  var valid_605545 = header.getOrDefault("X-Amz-Target")
  valid_605545 = validateParameter(valid_605545, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_605545 != nil:
    section.add "X-Amz-Target", valid_605545
  var valid_605546 = header.getOrDefault("X-Amz-Signature")
  valid_605546 = validateParameter(valid_605546, JString, required = false,
                                 default = nil)
  if valid_605546 != nil:
    section.add "X-Amz-Signature", valid_605546
  var valid_605547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605547 = validateParameter(valid_605547, JString, required = false,
                                 default = nil)
  if valid_605547 != nil:
    section.add "X-Amz-Content-Sha256", valid_605547
  var valid_605548 = header.getOrDefault("X-Amz-Date")
  valid_605548 = validateParameter(valid_605548, JString, required = false,
                                 default = nil)
  if valid_605548 != nil:
    section.add "X-Amz-Date", valid_605548
  var valid_605549 = header.getOrDefault("X-Amz-Credential")
  valid_605549 = validateParameter(valid_605549, JString, required = false,
                                 default = nil)
  if valid_605549 != nil:
    section.add "X-Amz-Credential", valid_605549
  var valid_605550 = header.getOrDefault("X-Amz-Security-Token")
  valid_605550 = validateParameter(valid_605550, JString, required = false,
                                 default = nil)
  if valid_605550 != nil:
    section.add "X-Amz-Security-Token", valid_605550
  var valid_605551 = header.getOrDefault("X-Amz-Algorithm")
  valid_605551 = validateParameter(valid_605551, JString, required = false,
                                 default = nil)
  if valid_605551 != nil:
    section.add "X-Amz-Algorithm", valid_605551
  var valid_605552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605552 = validateParameter(valid_605552, JString, required = false,
                                 default = nil)
  if valid_605552 != nil:
    section.add "X-Amz-SignedHeaders", valid_605552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605554: Call_DescribeWorkspaces_605540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_605554.validator(path, query, header, formData, body)
  let scheme = call_605554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605554.url(scheme.get, call_605554.host, call_605554.base,
                         call_605554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605554, url, valid)

proc call*(call_605555: Call_DescribeWorkspaces_605540; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_605556 = newJObject()
  var body_605557 = newJObject()
  add(query_605556, "NextToken", newJString(NextToken))
  add(query_605556, "Limit", newJString(Limit))
  if body != nil:
    body_605557 = body
  result = call_605555.call(nil, query_605556, nil, nil, body_605557)

var describeWorkspaces* = Call_DescribeWorkspaces_605540(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_605541, base: "/",
    url: url_DescribeWorkspaces_605542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_605558 = ref object of OpenApiRestCall_604658
proc url_DescribeWorkspacesConnectionStatus_605560(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspacesConnectionStatus_605559(path: JsonNode;
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
  var valid_605561 = header.getOrDefault("X-Amz-Target")
  valid_605561 = validateParameter(valid_605561, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_605561 != nil:
    section.add "X-Amz-Target", valid_605561
  var valid_605562 = header.getOrDefault("X-Amz-Signature")
  valid_605562 = validateParameter(valid_605562, JString, required = false,
                                 default = nil)
  if valid_605562 != nil:
    section.add "X-Amz-Signature", valid_605562
  var valid_605563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605563 = validateParameter(valid_605563, JString, required = false,
                                 default = nil)
  if valid_605563 != nil:
    section.add "X-Amz-Content-Sha256", valid_605563
  var valid_605564 = header.getOrDefault("X-Amz-Date")
  valid_605564 = validateParameter(valid_605564, JString, required = false,
                                 default = nil)
  if valid_605564 != nil:
    section.add "X-Amz-Date", valid_605564
  var valid_605565 = header.getOrDefault("X-Amz-Credential")
  valid_605565 = validateParameter(valid_605565, JString, required = false,
                                 default = nil)
  if valid_605565 != nil:
    section.add "X-Amz-Credential", valid_605565
  var valid_605566 = header.getOrDefault("X-Amz-Security-Token")
  valid_605566 = validateParameter(valid_605566, JString, required = false,
                                 default = nil)
  if valid_605566 != nil:
    section.add "X-Amz-Security-Token", valid_605566
  var valid_605567 = header.getOrDefault("X-Amz-Algorithm")
  valid_605567 = validateParameter(valid_605567, JString, required = false,
                                 default = nil)
  if valid_605567 != nil:
    section.add "X-Amz-Algorithm", valid_605567
  var valid_605568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605568 = validateParameter(valid_605568, JString, required = false,
                                 default = nil)
  if valid_605568 != nil:
    section.add "X-Amz-SignedHeaders", valid_605568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605570: Call_DescribeWorkspacesConnectionStatus_605558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_605570.validator(path, query, header, formData, body)
  let scheme = call_605570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605570.url(scheme.get, call_605570.host, call_605570.base,
                         call_605570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605570, url, valid)

proc call*(call_605571: Call_DescribeWorkspacesConnectionStatus_605558;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_605572 = newJObject()
  if body != nil:
    body_605572 = body
  result = call_605571.call(nil, nil, nil, nil, body_605572)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_605558(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_605559, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_605560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_605573 = ref object of OpenApiRestCall_604658
proc url_DisassociateIpGroups_605575(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateIpGroups_605574(path: JsonNode; query: JsonNode;
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
  var valid_605576 = header.getOrDefault("X-Amz-Target")
  valid_605576 = validateParameter(valid_605576, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_605576 != nil:
    section.add "X-Amz-Target", valid_605576
  var valid_605577 = header.getOrDefault("X-Amz-Signature")
  valid_605577 = validateParameter(valid_605577, JString, required = false,
                                 default = nil)
  if valid_605577 != nil:
    section.add "X-Amz-Signature", valid_605577
  var valid_605578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605578 = validateParameter(valid_605578, JString, required = false,
                                 default = nil)
  if valid_605578 != nil:
    section.add "X-Amz-Content-Sha256", valid_605578
  var valid_605579 = header.getOrDefault("X-Amz-Date")
  valid_605579 = validateParameter(valid_605579, JString, required = false,
                                 default = nil)
  if valid_605579 != nil:
    section.add "X-Amz-Date", valid_605579
  var valid_605580 = header.getOrDefault("X-Amz-Credential")
  valid_605580 = validateParameter(valid_605580, JString, required = false,
                                 default = nil)
  if valid_605580 != nil:
    section.add "X-Amz-Credential", valid_605580
  var valid_605581 = header.getOrDefault("X-Amz-Security-Token")
  valid_605581 = validateParameter(valid_605581, JString, required = false,
                                 default = nil)
  if valid_605581 != nil:
    section.add "X-Amz-Security-Token", valid_605581
  var valid_605582 = header.getOrDefault("X-Amz-Algorithm")
  valid_605582 = validateParameter(valid_605582, JString, required = false,
                                 default = nil)
  if valid_605582 != nil:
    section.add "X-Amz-Algorithm", valid_605582
  var valid_605583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605583 = validateParameter(valid_605583, JString, required = false,
                                 default = nil)
  if valid_605583 != nil:
    section.add "X-Amz-SignedHeaders", valid_605583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605585: Call_DisassociateIpGroups_605573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_605585.validator(path, query, header, formData, body)
  let scheme = call_605585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605585.url(scheme.get, call_605585.host, call_605585.base,
                         call_605585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605585, url, valid)

proc call*(call_605586: Call_DisassociateIpGroups_605573; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_605587 = newJObject()
  if body != nil:
    body_605587 = body
  result = call_605586.call(nil, nil, nil, nil, body_605587)

var disassociateIpGroups* = Call_DisassociateIpGroups_605573(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_605574, base: "/",
    url: url_DisassociateIpGroups_605575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_605588 = ref object of OpenApiRestCall_604658
proc url_ImportWorkspaceImage_605590(protocol: Scheme; host: string; base: string;
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

proc validate_ImportWorkspaceImage_605589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
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
  var valid_605591 = header.getOrDefault("X-Amz-Target")
  valid_605591 = validateParameter(valid_605591, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_605591 != nil:
    section.add "X-Amz-Target", valid_605591
  var valid_605592 = header.getOrDefault("X-Amz-Signature")
  valid_605592 = validateParameter(valid_605592, JString, required = false,
                                 default = nil)
  if valid_605592 != nil:
    section.add "X-Amz-Signature", valid_605592
  var valid_605593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605593 = validateParameter(valid_605593, JString, required = false,
                                 default = nil)
  if valid_605593 != nil:
    section.add "X-Amz-Content-Sha256", valid_605593
  var valid_605594 = header.getOrDefault("X-Amz-Date")
  valid_605594 = validateParameter(valid_605594, JString, required = false,
                                 default = nil)
  if valid_605594 != nil:
    section.add "X-Amz-Date", valid_605594
  var valid_605595 = header.getOrDefault("X-Amz-Credential")
  valid_605595 = validateParameter(valid_605595, JString, required = false,
                                 default = nil)
  if valid_605595 != nil:
    section.add "X-Amz-Credential", valid_605595
  var valid_605596 = header.getOrDefault("X-Amz-Security-Token")
  valid_605596 = validateParameter(valid_605596, JString, required = false,
                                 default = nil)
  if valid_605596 != nil:
    section.add "X-Amz-Security-Token", valid_605596
  var valid_605597 = header.getOrDefault("X-Amz-Algorithm")
  valid_605597 = validateParameter(valid_605597, JString, required = false,
                                 default = nil)
  if valid_605597 != nil:
    section.add "X-Amz-Algorithm", valid_605597
  var valid_605598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605598 = validateParameter(valid_605598, JString, required = false,
                                 default = nil)
  if valid_605598 != nil:
    section.add "X-Amz-SignedHeaders", valid_605598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605600: Call_ImportWorkspaceImage_605588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_605600.validator(path, query, header, formData, body)
  let scheme = call_605600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605600.url(scheme.get, call_605600.host, call_605600.base,
                         call_605600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605600, url, valid)

proc call*(call_605601: Call_ImportWorkspaceImage_605588; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_605602 = newJObject()
  if body != nil:
    body_605602 = body
  result = call_605601.call(nil, nil, nil, nil, body_605602)

var importWorkspaceImage* = Call_ImportWorkspaceImage_605588(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_605589, base: "/",
    url: url_ImportWorkspaceImage_605590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_605603 = ref object of OpenApiRestCall_604658
proc url_ListAvailableManagementCidrRanges_605605(protocol: Scheme; host: string;
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

proc validate_ListAvailableManagementCidrRanges_605604(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
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
  var valid_605606 = header.getOrDefault("X-Amz-Target")
  valid_605606 = validateParameter(valid_605606, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_605606 != nil:
    section.add "X-Amz-Target", valid_605606
  var valid_605607 = header.getOrDefault("X-Amz-Signature")
  valid_605607 = validateParameter(valid_605607, JString, required = false,
                                 default = nil)
  if valid_605607 != nil:
    section.add "X-Amz-Signature", valid_605607
  var valid_605608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605608 = validateParameter(valid_605608, JString, required = false,
                                 default = nil)
  if valid_605608 != nil:
    section.add "X-Amz-Content-Sha256", valid_605608
  var valid_605609 = header.getOrDefault("X-Amz-Date")
  valid_605609 = validateParameter(valid_605609, JString, required = false,
                                 default = nil)
  if valid_605609 != nil:
    section.add "X-Amz-Date", valid_605609
  var valid_605610 = header.getOrDefault("X-Amz-Credential")
  valid_605610 = validateParameter(valid_605610, JString, required = false,
                                 default = nil)
  if valid_605610 != nil:
    section.add "X-Amz-Credential", valid_605610
  var valid_605611 = header.getOrDefault("X-Amz-Security-Token")
  valid_605611 = validateParameter(valid_605611, JString, required = false,
                                 default = nil)
  if valid_605611 != nil:
    section.add "X-Amz-Security-Token", valid_605611
  var valid_605612 = header.getOrDefault("X-Amz-Algorithm")
  valid_605612 = validateParameter(valid_605612, JString, required = false,
                                 default = nil)
  if valid_605612 != nil:
    section.add "X-Amz-Algorithm", valid_605612
  var valid_605613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605613 = validateParameter(valid_605613, JString, required = false,
                                 default = nil)
  if valid_605613 != nil:
    section.add "X-Amz-SignedHeaders", valid_605613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605615: Call_ListAvailableManagementCidrRanges_605603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_605615.validator(path, query, header, formData, body)
  let scheme = call_605615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605615.url(scheme.get, call_605615.host, call_605615.base,
                         call_605615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605615, url, valid)

proc call*(call_605616: Call_ListAvailableManagementCidrRanges_605603;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_605617 = newJObject()
  if body != nil:
    body_605617 = body
  result = call_605616.call(nil, nil, nil, nil, body_605617)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_605603(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_605604, base: "/",
    url: url_ListAvailableManagementCidrRanges_605605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MigrateWorkspace_605618 = ref object of OpenApiRestCall_604658
proc url_MigrateWorkspace_605620(protocol: Scheme; host: string; base: string;
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

proc validate_MigrateWorkspace_605619(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
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
  var valid_605621 = header.getOrDefault("X-Amz-Target")
  valid_605621 = validateParameter(valid_605621, JString, required = true, default = newJString(
      "WorkspacesService.MigrateWorkspace"))
  if valid_605621 != nil:
    section.add "X-Amz-Target", valid_605621
  var valid_605622 = header.getOrDefault("X-Amz-Signature")
  valid_605622 = validateParameter(valid_605622, JString, required = false,
                                 default = nil)
  if valid_605622 != nil:
    section.add "X-Amz-Signature", valid_605622
  var valid_605623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605623 = validateParameter(valid_605623, JString, required = false,
                                 default = nil)
  if valid_605623 != nil:
    section.add "X-Amz-Content-Sha256", valid_605623
  var valid_605624 = header.getOrDefault("X-Amz-Date")
  valid_605624 = validateParameter(valid_605624, JString, required = false,
                                 default = nil)
  if valid_605624 != nil:
    section.add "X-Amz-Date", valid_605624
  var valid_605625 = header.getOrDefault("X-Amz-Credential")
  valid_605625 = validateParameter(valid_605625, JString, required = false,
                                 default = nil)
  if valid_605625 != nil:
    section.add "X-Amz-Credential", valid_605625
  var valid_605626 = header.getOrDefault("X-Amz-Security-Token")
  valid_605626 = validateParameter(valid_605626, JString, required = false,
                                 default = nil)
  if valid_605626 != nil:
    section.add "X-Amz-Security-Token", valid_605626
  var valid_605627 = header.getOrDefault("X-Amz-Algorithm")
  valid_605627 = validateParameter(valid_605627, JString, required = false,
                                 default = nil)
  if valid_605627 != nil:
    section.add "X-Amz-Algorithm", valid_605627
  var valid_605628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605628 = validateParameter(valid_605628, JString, required = false,
                                 default = nil)
  if valid_605628 != nil:
    section.add "X-Amz-SignedHeaders", valid_605628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605630: Call_MigrateWorkspace_605618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ## 
  let valid = call_605630.validator(path, query, header, formData, body)
  let scheme = call_605630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605630.url(scheme.get, call_605630.host, call_605630.base,
                         call_605630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605630, url, valid)

proc call*(call_605631: Call_MigrateWorkspace_605618; body: JsonNode): Recallable =
  ## migrateWorkspace
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ##   body: JObject (required)
  var body_605632 = newJObject()
  if body != nil:
    body_605632 = body
  result = call_605631.call(nil, nil, nil, nil, body_605632)

var migrateWorkspace* = Call_MigrateWorkspace_605618(name: "migrateWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.MigrateWorkspace",
    validator: validate_MigrateWorkspace_605619, base: "/",
    url: url_MigrateWorkspace_605620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_605633 = ref object of OpenApiRestCall_604658
proc url_ModifyAccount_605635(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyAccount_605634(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
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
  var valid_605636 = header.getOrDefault("X-Amz-Target")
  valid_605636 = validateParameter(valid_605636, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_605636 != nil:
    section.add "X-Amz-Target", valid_605636
  var valid_605637 = header.getOrDefault("X-Amz-Signature")
  valid_605637 = validateParameter(valid_605637, JString, required = false,
                                 default = nil)
  if valid_605637 != nil:
    section.add "X-Amz-Signature", valid_605637
  var valid_605638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605638 = validateParameter(valid_605638, JString, required = false,
                                 default = nil)
  if valid_605638 != nil:
    section.add "X-Amz-Content-Sha256", valid_605638
  var valid_605639 = header.getOrDefault("X-Amz-Date")
  valid_605639 = validateParameter(valid_605639, JString, required = false,
                                 default = nil)
  if valid_605639 != nil:
    section.add "X-Amz-Date", valid_605639
  var valid_605640 = header.getOrDefault("X-Amz-Credential")
  valid_605640 = validateParameter(valid_605640, JString, required = false,
                                 default = nil)
  if valid_605640 != nil:
    section.add "X-Amz-Credential", valid_605640
  var valid_605641 = header.getOrDefault("X-Amz-Security-Token")
  valid_605641 = validateParameter(valid_605641, JString, required = false,
                                 default = nil)
  if valid_605641 != nil:
    section.add "X-Amz-Security-Token", valid_605641
  var valid_605642 = header.getOrDefault("X-Amz-Algorithm")
  valid_605642 = validateParameter(valid_605642, JString, required = false,
                                 default = nil)
  if valid_605642 != nil:
    section.add "X-Amz-Algorithm", valid_605642
  var valid_605643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605643 = validateParameter(valid_605643, JString, required = false,
                                 default = nil)
  if valid_605643 != nil:
    section.add "X-Amz-SignedHeaders", valid_605643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605645: Call_ModifyAccount_605633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_605645.validator(path, query, header, formData, body)
  let scheme = call_605645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605645.url(scheme.get, call_605645.host, call_605645.base,
                         call_605645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605645, url, valid)

proc call*(call_605646: Call_ModifyAccount_605633; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_605647 = newJObject()
  if body != nil:
    body_605647 = body
  result = call_605646.call(nil, nil, nil, nil, body_605647)

var modifyAccount* = Call_ModifyAccount_605633(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_605634, base: "/", url: url_ModifyAccount_605635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_605648 = ref object of OpenApiRestCall_604658
proc url_ModifyClientProperties_605650(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyClientProperties_605649(path: JsonNode; query: JsonNode;
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
  var valid_605651 = header.getOrDefault("X-Amz-Target")
  valid_605651 = validateParameter(valid_605651, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_605651 != nil:
    section.add "X-Amz-Target", valid_605651
  var valid_605652 = header.getOrDefault("X-Amz-Signature")
  valid_605652 = validateParameter(valid_605652, JString, required = false,
                                 default = nil)
  if valid_605652 != nil:
    section.add "X-Amz-Signature", valid_605652
  var valid_605653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605653 = validateParameter(valid_605653, JString, required = false,
                                 default = nil)
  if valid_605653 != nil:
    section.add "X-Amz-Content-Sha256", valid_605653
  var valid_605654 = header.getOrDefault("X-Amz-Date")
  valid_605654 = validateParameter(valid_605654, JString, required = false,
                                 default = nil)
  if valid_605654 != nil:
    section.add "X-Amz-Date", valid_605654
  var valid_605655 = header.getOrDefault("X-Amz-Credential")
  valid_605655 = validateParameter(valid_605655, JString, required = false,
                                 default = nil)
  if valid_605655 != nil:
    section.add "X-Amz-Credential", valid_605655
  var valid_605656 = header.getOrDefault("X-Amz-Security-Token")
  valid_605656 = validateParameter(valid_605656, JString, required = false,
                                 default = nil)
  if valid_605656 != nil:
    section.add "X-Amz-Security-Token", valid_605656
  var valid_605657 = header.getOrDefault("X-Amz-Algorithm")
  valid_605657 = validateParameter(valid_605657, JString, required = false,
                                 default = nil)
  if valid_605657 != nil:
    section.add "X-Amz-Algorithm", valid_605657
  var valid_605658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605658 = validateParameter(valid_605658, JString, required = false,
                                 default = nil)
  if valid_605658 != nil:
    section.add "X-Amz-SignedHeaders", valid_605658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605660: Call_ModifyClientProperties_605648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_605660.validator(path, query, header, formData, body)
  let scheme = call_605660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605660.url(scheme.get, call_605660.host, call_605660.base,
                         call_605660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605660, url, valid)

proc call*(call_605661: Call_ModifyClientProperties_605648; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_605662 = newJObject()
  if body != nil:
    body_605662 = body
  result = call_605661.call(nil, nil, nil, nil, body_605662)

var modifyClientProperties* = Call_ModifyClientProperties_605648(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_605649, base: "/",
    url: url_ModifyClientProperties_605650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifySelfservicePermissions_605663 = ref object of OpenApiRestCall_604658
proc url_ModifySelfservicePermissions_605665(protocol: Scheme; host: string;
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

proc validate_ModifySelfservicePermissions_605664(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
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
  var valid_605666 = header.getOrDefault("X-Amz-Target")
  valid_605666 = validateParameter(valid_605666, JString, required = true, default = newJString(
      "WorkspacesService.ModifySelfservicePermissions"))
  if valid_605666 != nil:
    section.add "X-Amz-Target", valid_605666
  var valid_605667 = header.getOrDefault("X-Amz-Signature")
  valid_605667 = validateParameter(valid_605667, JString, required = false,
                                 default = nil)
  if valid_605667 != nil:
    section.add "X-Amz-Signature", valid_605667
  var valid_605668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605668 = validateParameter(valid_605668, JString, required = false,
                                 default = nil)
  if valid_605668 != nil:
    section.add "X-Amz-Content-Sha256", valid_605668
  var valid_605669 = header.getOrDefault("X-Amz-Date")
  valid_605669 = validateParameter(valid_605669, JString, required = false,
                                 default = nil)
  if valid_605669 != nil:
    section.add "X-Amz-Date", valid_605669
  var valid_605670 = header.getOrDefault("X-Amz-Credential")
  valid_605670 = validateParameter(valid_605670, JString, required = false,
                                 default = nil)
  if valid_605670 != nil:
    section.add "X-Amz-Credential", valid_605670
  var valid_605671 = header.getOrDefault("X-Amz-Security-Token")
  valid_605671 = validateParameter(valid_605671, JString, required = false,
                                 default = nil)
  if valid_605671 != nil:
    section.add "X-Amz-Security-Token", valid_605671
  var valid_605672 = header.getOrDefault("X-Amz-Algorithm")
  valid_605672 = validateParameter(valid_605672, JString, required = false,
                                 default = nil)
  if valid_605672 != nil:
    section.add "X-Amz-Algorithm", valid_605672
  var valid_605673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605673 = validateParameter(valid_605673, JString, required = false,
                                 default = nil)
  if valid_605673 != nil:
    section.add "X-Amz-SignedHeaders", valid_605673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605675: Call_ModifySelfservicePermissions_605663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ## 
  let valid = call_605675.validator(path, query, header, formData, body)
  let scheme = call_605675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605675.url(scheme.get, call_605675.host, call_605675.base,
                         call_605675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605675, url, valid)

proc call*(call_605676: Call_ModifySelfservicePermissions_605663; body: JsonNode): Recallable =
  ## modifySelfservicePermissions
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ##   body: JObject (required)
  var body_605677 = newJObject()
  if body != nil:
    body_605677 = body
  result = call_605676.call(nil, nil, nil, nil, body_605677)

var modifySelfservicePermissions* = Call_ModifySelfservicePermissions_605663(
    name: "modifySelfservicePermissions", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifySelfservicePermissions",
    validator: validate_ModifySelfservicePermissions_605664, base: "/",
    url: url_ModifySelfservicePermissions_605665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceAccessProperties_605678 = ref object of OpenApiRestCall_604658
proc url_ModifyWorkspaceAccessProperties_605680(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceAccessProperties_605679(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
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
  var valid_605681 = header.getOrDefault("X-Amz-Target")
  valid_605681 = validateParameter(valid_605681, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceAccessProperties"))
  if valid_605681 != nil:
    section.add "X-Amz-Target", valid_605681
  var valid_605682 = header.getOrDefault("X-Amz-Signature")
  valid_605682 = validateParameter(valid_605682, JString, required = false,
                                 default = nil)
  if valid_605682 != nil:
    section.add "X-Amz-Signature", valid_605682
  var valid_605683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605683 = validateParameter(valid_605683, JString, required = false,
                                 default = nil)
  if valid_605683 != nil:
    section.add "X-Amz-Content-Sha256", valid_605683
  var valid_605684 = header.getOrDefault("X-Amz-Date")
  valid_605684 = validateParameter(valid_605684, JString, required = false,
                                 default = nil)
  if valid_605684 != nil:
    section.add "X-Amz-Date", valid_605684
  var valid_605685 = header.getOrDefault("X-Amz-Credential")
  valid_605685 = validateParameter(valid_605685, JString, required = false,
                                 default = nil)
  if valid_605685 != nil:
    section.add "X-Amz-Credential", valid_605685
  var valid_605686 = header.getOrDefault("X-Amz-Security-Token")
  valid_605686 = validateParameter(valid_605686, JString, required = false,
                                 default = nil)
  if valid_605686 != nil:
    section.add "X-Amz-Security-Token", valid_605686
  var valid_605687 = header.getOrDefault("X-Amz-Algorithm")
  valid_605687 = validateParameter(valid_605687, JString, required = false,
                                 default = nil)
  if valid_605687 != nil:
    section.add "X-Amz-Algorithm", valid_605687
  var valid_605688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605688 = validateParameter(valid_605688, JString, required = false,
                                 default = nil)
  if valid_605688 != nil:
    section.add "X-Amz-SignedHeaders", valid_605688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605690: Call_ModifyWorkspaceAccessProperties_605678;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ## 
  let valid = call_605690.validator(path, query, header, formData, body)
  let scheme = call_605690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605690.url(scheme.get, call_605690.host, call_605690.base,
                         call_605690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605690, url, valid)

proc call*(call_605691: Call_ModifyWorkspaceAccessProperties_605678; body: JsonNode): Recallable =
  ## modifyWorkspaceAccessProperties
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ##   body: JObject (required)
  var body_605692 = newJObject()
  if body != nil:
    body_605692 = body
  result = call_605691.call(nil, nil, nil, nil, body_605692)

var modifyWorkspaceAccessProperties* = Call_ModifyWorkspaceAccessProperties_605678(
    name: "modifyWorkspaceAccessProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceAccessProperties",
    validator: validate_ModifyWorkspaceAccessProperties_605679, base: "/",
    url: url_ModifyWorkspaceAccessProperties_605680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceCreationProperties_605693 = ref object of OpenApiRestCall_604658
proc url_ModifyWorkspaceCreationProperties_605695(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceCreationProperties_605694(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modify the default properties used to create WorkSpaces.
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
  var valid_605696 = header.getOrDefault("X-Amz-Target")
  valid_605696 = validateParameter(valid_605696, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceCreationProperties"))
  if valid_605696 != nil:
    section.add "X-Amz-Target", valid_605696
  var valid_605697 = header.getOrDefault("X-Amz-Signature")
  valid_605697 = validateParameter(valid_605697, JString, required = false,
                                 default = nil)
  if valid_605697 != nil:
    section.add "X-Amz-Signature", valid_605697
  var valid_605698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605698 = validateParameter(valid_605698, JString, required = false,
                                 default = nil)
  if valid_605698 != nil:
    section.add "X-Amz-Content-Sha256", valid_605698
  var valid_605699 = header.getOrDefault("X-Amz-Date")
  valid_605699 = validateParameter(valid_605699, JString, required = false,
                                 default = nil)
  if valid_605699 != nil:
    section.add "X-Amz-Date", valid_605699
  var valid_605700 = header.getOrDefault("X-Amz-Credential")
  valid_605700 = validateParameter(valid_605700, JString, required = false,
                                 default = nil)
  if valid_605700 != nil:
    section.add "X-Amz-Credential", valid_605700
  var valid_605701 = header.getOrDefault("X-Amz-Security-Token")
  valid_605701 = validateParameter(valid_605701, JString, required = false,
                                 default = nil)
  if valid_605701 != nil:
    section.add "X-Amz-Security-Token", valid_605701
  var valid_605702 = header.getOrDefault("X-Amz-Algorithm")
  valid_605702 = validateParameter(valid_605702, JString, required = false,
                                 default = nil)
  if valid_605702 != nil:
    section.add "X-Amz-Algorithm", valid_605702
  var valid_605703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605703 = validateParameter(valid_605703, JString, required = false,
                                 default = nil)
  if valid_605703 != nil:
    section.add "X-Amz-SignedHeaders", valid_605703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605705: Call_ModifyWorkspaceCreationProperties_605693;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modify the default properties used to create WorkSpaces.
  ## 
  let valid = call_605705.validator(path, query, header, formData, body)
  let scheme = call_605705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605705.url(scheme.get, call_605705.host, call_605705.base,
                         call_605705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605705, url, valid)

proc call*(call_605706: Call_ModifyWorkspaceCreationProperties_605693;
          body: JsonNode): Recallable =
  ## modifyWorkspaceCreationProperties
  ## Modify the default properties used to create WorkSpaces.
  ##   body: JObject (required)
  var body_605707 = newJObject()
  if body != nil:
    body_605707 = body
  result = call_605706.call(nil, nil, nil, nil, body_605707)

var modifyWorkspaceCreationProperties* = Call_ModifyWorkspaceCreationProperties_605693(
    name: "modifyWorkspaceCreationProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceCreationProperties",
    validator: validate_ModifyWorkspaceCreationProperties_605694, base: "/",
    url: url_ModifyWorkspaceCreationProperties_605695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_605708 = ref object of OpenApiRestCall_604658
proc url_ModifyWorkspaceProperties_605710(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceProperties_605709(path: JsonNode; query: JsonNode;
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
  var valid_605711 = header.getOrDefault("X-Amz-Target")
  valid_605711 = validateParameter(valid_605711, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_605711 != nil:
    section.add "X-Amz-Target", valid_605711
  var valid_605712 = header.getOrDefault("X-Amz-Signature")
  valid_605712 = validateParameter(valid_605712, JString, required = false,
                                 default = nil)
  if valid_605712 != nil:
    section.add "X-Amz-Signature", valid_605712
  var valid_605713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605713 = validateParameter(valid_605713, JString, required = false,
                                 default = nil)
  if valid_605713 != nil:
    section.add "X-Amz-Content-Sha256", valid_605713
  var valid_605714 = header.getOrDefault("X-Amz-Date")
  valid_605714 = validateParameter(valid_605714, JString, required = false,
                                 default = nil)
  if valid_605714 != nil:
    section.add "X-Amz-Date", valid_605714
  var valid_605715 = header.getOrDefault("X-Amz-Credential")
  valid_605715 = validateParameter(valid_605715, JString, required = false,
                                 default = nil)
  if valid_605715 != nil:
    section.add "X-Amz-Credential", valid_605715
  var valid_605716 = header.getOrDefault("X-Amz-Security-Token")
  valid_605716 = validateParameter(valid_605716, JString, required = false,
                                 default = nil)
  if valid_605716 != nil:
    section.add "X-Amz-Security-Token", valid_605716
  var valid_605717 = header.getOrDefault("X-Amz-Algorithm")
  valid_605717 = validateParameter(valid_605717, JString, required = false,
                                 default = nil)
  if valid_605717 != nil:
    section.add "X-Amz-Algorithm", valid_605717
  var valid_605718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605718 = validateParameter(valid_605718, JString, required = false,
                                 default = nil)
  if valid_605718 != nil:
    section.add "X-Amz-SignedHeaders", valid_605718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605720: Call_ModifyWorkspaceProperties_605708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_605720.validator(path, query, header, formData, body)
  let scheme = call_605720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605720.url(scheme.get, call_605720.host, call_605720.base,
                         call_605720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605720, url, valid)

proc call*(call_605721: Call_ModifyWorkspaceProperties_605708; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_605722 = newJObject()
  if body != nil:
    body_605722 = body
  result = call_605721.call(nil, nil, nil, nil, body_605722)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_605708(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_605709, base: "/",
    url: url_ModifyWorkspaceProperties_605710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_605723 = ref object of OpenApiRestCall_604658
proc url_ModifyWorkspaceState_605725(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyWorkspaceState_605724(path: JsonNode; query: JsonNode;
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
  var valid_605726 = header.getOrDefault("X-Amz-Target")
  valid_605726 = validateParameter(valid_605726, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_605726 != nil:
    section.add "X-Amz-Target", valid_605726
  var valid_605727 = header.getOrDefault("X-Amz-Signature")
  valid_605727 = validateParameter(valid_605727, JString, required = false,
                                 default = nil)
  if valid_605727 != nil:
    section.add "X-Amz-Signature", valid_605727
  var valid_605728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605728 = validateParameter(valid_605728, JString, required = false,
                                 default = nil)
  if valid_605728 != nil:
    section.add "X-Amz-Content-Sha256", valid_605728
  var valid_605729 = header.getOrDefault("X-Amz-Date")
  valid_605729 = validateParameter(valid_605729, JString, required = false,
                                 default = nil)
  if valid_605729 != nil:
    section.add "X-Amz-Date", valid_605729
  var valid_605730 = header.getOrDefault("X-Amz-Credential")
  valid_605730 = validateParameter(valid_605730, JString, required = false,
                                 default = nil)
  if valid_605730 != nil:
    section.add "X-Amz-Credential", valid_605730
  var valid_605731 = header.getOrDefault("X-Amz-Security-Token")
  valid_605731 = validateParameter(valid_605731, JString, required = false,
                                 default = nil)
  if valid_605731 != nil:
    section.add "X-Amz-Security-Token", valid_605731
  var valid_605732 = header.getOrDefault("X-Amz-Algorithm")
  valid_605732 = validateParameter(valid_605732, JString, required = false,
                                 default = nil)
  if valid_605732 != nil:
    section.add "X-Amz-Algorithm", valid_605732
  var valid_605733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605733 = validateParameter(valid_605733, JString, required = false,
                                 default = nil)
  if valid_605733 != nil:
    section.add "X-Amz-SignedHeaders", valid_605733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605735: Call_ModifyWorkspaceState_605723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_605735.validator(path, query, header, formData, body)
  let scheme = call_605735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605735.url(scheme.get, call_605735.host, call_605735.base,
                         call_605735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605735, url, valid)

proc call*(call_605736: Call_ModifyWorkspaceState_605723; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_605737 = newJObject()
  if body != nil:
    body_605737 = body
  result = call_605736.call(nil, nil, nil, nil, body_605737)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_605723(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_605724, base: "/",
    url: url_ModifyWorkspaceState_605725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_605738 = ref object of OpenApiRestCall_604658
proc url_RebootWorkspaces_605740(protocol: Scheme; host: string; base: string;
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

proc validate_RebootWorkspaces_605739(path: JsonNode; query: JsonNode;
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
  var valid_605741 = header.getOrDefault("X-Amz-Target")
  valid_605741 = validateParameter(valid_605741, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_605741 != nil:
    section.add "X-Amz-Target", valid_605741
  var valid_605742 = header.getOrDefault("X-Amz-Signature")
  valid_605742 = validateParameter(valid_605742, JString, required = false,
                                 default = nil)
  if valid_605742 != nil:
    section.add "X-Amz-Signature", valid_605742
  var valid_605743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605743 = validateParameter(valid_605743, JString, required = false,
                                 default = nil)
  if valid_605743 != nil:
    section.add "X-Amz-Content-Sha256", valid_605743
  var valid_605744 = header.getOrDefault("X-Amz-Date")
  valid_605744 = validateParameter(valid_605744, JString, required = false,
                                 default = nil)
  if valid_605744 != nil:
    section.add "X-Amz-Date", valid_605744
  var valid_605745 = header.getOrDefault("X-Amz-Credential")
  valid_605745 = validateParameter(valid_605745, JString, required = false,
                                 default = nil)
  if valid_605745 != nil:
    section.add "X-Amz-Credential", valid_605745
  var valid_605746 = header.getOrDefault("X-Amz-Security-Token")
  valid_605746 = validateParameter(valid_605746, JString, required = false,
                                 default = nil)
  if valid_605746 != nil:
    section.add "X-Amz-Security-Token", valid_605746
  var valid_605747 = header.getOrDefault("X-Amz-Algorithm")
  valid_605747 = validateParameter(valid_605747, JString, required = false,
                                 default = nil)
  if valid_605747 != nil:
    section.add "X-Amz-Algorithm", valid_605747
  var valid_605748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605748 = validateParameter(valid_605748, JString, required = false,
                                 default = nil)
  if valid_605748 != nil:
    section.add "X-Amz-SignedHeaders", valid_605748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605750: Call_RebootWorkspaces_605738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_605750.validator(path, query, header, formData, body)
  let scheme = call_605750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605750.url(scheme.get, call_605750.host, call_605750.base,
                         call_605750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605750, url, valid)

proc call*(call_605751: Call_RebootWorkspaces_605738; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_605752 = newJObject()
  if body != nil:
    body_605752 = body
  result = call_605751.call(nil, nil, nil, nil, body_605752)

var rebootWorkspaces* = Call_RebootWorkspaces_605738(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_605739, base: "/",
    url: url_RebootWorkspaces_605740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_605753 = ref object of OpenApiRestCall_604658
proc url_RebuildWorkspaces_605755(protocol: Scheme; host: string; base: string;
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

proc validate_RebuildWorkspaces_605754(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
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
  var valid_605756 = header.getOrDefault("X-Amz-Target")
  valid_605756 = validateParameter(valid_605756, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_605756 != nil:
    section.add "X-Amz-Target", valid_605756
  var valid_605757 = header.getOrDefault("X-Amz-Signature")
  valid_605757 = validateParameter(valid_605757, JString, required = false,
                                 default = nil)
  if valid_605757 != nil:
    section.add "X-Amz-Signature", valid_605757
  var valid_605758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605758 = validateParameter(valid_605758, JString, required = false,
                                 default = nil)
  if valid_605758 != nil:
    section.add "X-Amz-Content-Sha256", valid_605758
  var valid_605759 = header.getOrDefault("X-Amz-Date")
  valid_605759 = validateParameter(valid_605759, JString, required = false,
                                 default = nil)
  if valid_605759 != nil:
    section.add "X-Amz-Date", valid_605759
  var valid_605760 = header.getOrDefault("X-Amz-Credential")
  valid_605760 = validateParameter(valid_605760, JString, required = false,
                                 default = nil)
  if valid_605760 != nil:
    section.add "X-Amz-Credential", valid_605760
  var valid_605761 = header.getOrDefault("X-Amz-Security-Token")
  valid_605761 = validateParameter(valid_605761, JString, required = false,
                                 default = nil)
  if valid_605761 != nil:
    section.add "X-Amz-Security-Token", valid_605761
  var valid_605762 = header.getOrDefault("X-Amz-Algorithm")
  valid_605762 = validateParameter(valid_605762, JString, required = false,
                                 default = nil)
  if valid_605762 != nil:
    section.add "X-Amz-Algorithm", valid_605762
  var valid_605763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605763 = validateParameter(valid_605763, JString, required = false,
                                 default = nil)
  if valid_605763 != nil:
    section.add "X-Amz-SignedHeaders", valid_605763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605765: Call_RebuildWorkspaces_605753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_605765.validator(path, query, header, formData, body)
  let scheme = call_605765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605765.url(scheme.get, call_605765.host, call_605765.base,
                         call_605765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605765, url, valid)

proc call*(call_605766: Call_RebuildWorkspaces_605753; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_605767 = newJObject()
  if body != nil:
    body_605767 = body
  result = call_605766.call(nil, nil, nil, nil, body_605767)

var rebuildWorkspaces* = Call_RebuildWorkspaces_605753(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_605754, base: "/",
    url: url_RebuildWorkspaces_605755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWorkspaceDirectory_605768 = ref object of OpenApiRestCall_604658
proc url_RegisterWorkspaceDirectory_605770(protocol: Scheme; host: string;
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

proc validate_RegisterWorkspaceDirectory_605769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
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
  var valid_605771 = header.getOrDefault("X-Amz-Target")
  valid_605771 = validateParameter(valid_605771, JString, required = true, default = newJString(
      "WorkspacesService.RegisterWorkspaceDirectory"))
  if valid_605771 != nil:
    section.add "X-Amz-Target", valid_605771
  var valid_605772 = header.getOrDefault("X-Amz-Signature")
  valid_605772 = validateParameter(valid_605772, JString, required = false,
                                 default = nil)
  if valid_605772 != nil:
    section.add "X-Amz-Signature", valid_605772
  var valid_605773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605773 = validateParameter(valid_605773, JString, required = false,
                                 default = nil)
  if valid_605773 != nil:
    section.add "X-Amz-Content-Sha256", valid_605773
  var valid_605774 = header.getOrDefault("X-Amz-Date")
  valid_605774 = validateParameter(valid_605774, JString, required = false,
                                 default = nil)
  if valid_605774 != nil:
    section.add "X-Amz-Date", valid_605774
  var valid_605775 = header.getOrDefault("X-Amz-Credential")
  valid_605775 = validateParameter(valid_605775, JString, required = false,
                                 default = nil)
  if valid_605775 != nil:
    section.add "X-Amz-Credential", valid_605775
  var valid_605776 = header.getOrDefault("X-Amz-Security-Token")
  valid_605776 = validateParameter(valid_605776, JString, required = false,
                                 default = nil)
  if valid_605776 != nil:
    section.add "X-Amz-Security-Token", valid_605776
  var valid_605777 = header.getOrDefault("X-Amz-Algorithm")
  valid_605777 = validateParameter(valid_605777, JString, required = false,
                                 default = nil)
  if valid_605777 != nil:
    section.add "X-Amz-Algorithm", valid_605777
  var valid_605778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605778 = validateParameter(valid_605778, JString, required = false,
                                 default = nil)
  if valid_605778 != nil:
    section.add "X-Amz-SignedHeaders", valid_605778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605780: Call_RegisterWorkspaceDirectory_605768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ## 
  let valid = call_605780.validator(path, query, header, formData, body)
  let scheme = call_605780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605780.url(scheme.get, call_605780.host, call_605780.base,
                         call_605780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605780, url, valid)

proc call*(call_605781: Call_RegisterWorkspaceDirectory_605768; body: JsonNode): Recallable =
  ## registerWorkspaceDirectory
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ##   body: JObject (required)
  var body_605782 = newJObject()
  if body != nil:
    body_605782 = body
  result = call_605781.call(nil, nil, nil, nil, body_605782)

var registerWorkspaceDirectory* = Call_RegisterWorkspaceDirectory_605768(
    name: "registerWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RegisterWorkspaceDirectory",
    validator: validate_RegisterWorkspaceDirectory_605769, base: "/",
    url: url_RegisterWorkspaceDirectory_605770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_605783 = ref object of OpenApiRestCall_604658
proc url_RestoreWorkspace_605785(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreWorkspace_605784(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
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
  var valid_605786 = header.getOrDefault("X-Amz-Target")
  valid_605786 = validateParameter(valid_605786, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_605786 != nil:
    section.add "X-Amz-Target", valid_605786
  var valid_605787 = header.getOrDefault("X-Amz-Signature")
  valid_605787 = validateParameter(valid_605787, JString, required = false,
                                 default = nil)
  if valid_605787 != nil:
    section.add "X-Amz-Signature", valid_605787
  var valid_605788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605788 = validateParameter(valid_605788, JString, required = false,
                                 default = nil)
  if valid_605788 != nil:
    section.add "X-Amz-Content-Sha256", valid_605788
  var valid_605789 = header.getOrDefault("X-Amz-Date")
  valid_605789 = validateParameter(valid_605789, JString, required = false,
                                 default = nil)
  if valid_605789 != nil:
    section.add "X-Amz-Date", valid_605789
  var valid_605790 = header.getOrDefault("X-Amz-Credential")
  valid_605790 = validateParameter(valid_605790, JString, required = false,
                                 default = nil)
  if valid_605790 != nil:
    section.add "X-Amz-Credential", valid_605790
  var valid_605791 = header.getOrDefault("X-Amz-Security-Token")
  valid_605791 = validateParameter(valid_605791, JString, required = false,
                                 default = nil)
  if valid_605791 != nil:
    section.add "X-Amz-Security-Token", valid_605791
  var valid_605792 = header.getOrDefault("X-Amz-Algorithm")
  valid_605792 = validateParameter(valid_605792, JString, required = false,
                                 default = nil)
  if valid_605792 != nil:
    section.add "X-Amz-Algorithm", valid_605792
  var valid_605793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605793 = validateParameter(valid_605793, JString, required = false,
                                 default = nil)
  if valid_605793 != nil:
    section.add "X-Amz-SignedHeaders", valid_605793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605795: Call_RestoreWorkspace_605783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_605795.validator(path, query, header, formData, body)
  let scheme = call_605795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605795.url(scheme.get, call_605795.host, call_605795.base,
                         call_605795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605795, url, valid)

proc call*(call_605796: Call_RestoreWorkspace_605783; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_605797 = newJObject()
  if body != nil:
    body_605797 = body
  result = call_605796.call(nil, nil, nil, nil, body_605797)

var restoreWorkspace* = Call_RestoreWorkspace_605783(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_605784, base: "/",
    url: url_RestoreWorkspace_605785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_605798 = ref object of OpenApiRestCall_604658
proc url_RevokeIpRules_605800(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeIpRules_605799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605801 = header.getOrDefault("X-Amz-Target")
  valid_605801 = validateParameter(valid_605801, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_605801 != nil:
    section.add "X-Amz-Target", valid_605801
  var valid_605802 = header.getOrDefault("X-Amz-Signature")
  valid_605802 = validateParameter(valid_605802, JString, required = false,
                                 default = nil)
  if valid_605802 != nil:
    section.add "X-Amz-Signature", valid_605802
  var valid_605803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605803 = validateParameter(valid_605803, JString, required = false,
                                 default = nil)
  if valid_605803 != nil:
    section.add "X-Amz-Content-Sha256", valid_605803
  var valid_605804 = header.getOrDefault("X-Amz-Date")
  valid_605804 = validateParameter(valid_605804, JString, required = false,
                                 default = nil)
  if valid_605804 != nil:
    section.add "X-Amz-Date", valid_605804
  var valid_605805 = header.getOrDefault("X-Amz-Credential")
  valid_605805 = validateParameter(valid_605805, JString, required = false,
                                 default = nil)
  if valid_605805 != nil:
    section.add "X-Amz-Credential", valid_605805
  var valid_605806 = header.getOrDefault("X-Amz-Security-Token")
  valid_605806 = validateParameter(valid_605806, JString, required = false,
                                 default = nil)
  if valid_605806 != nil:
    section.add "X-Amz-Security-Token", valid_605806
  var valid_605807 = header.getOrDefault("X-Amz-Algorithm")
  valid_605807 = validateParameter(valid_605807, JString, required = false,
                                 default = nil)
  if valid_605807 != nil:
    section.add "X-Amz-Algorithm", valid_605807
  var valid_605808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605808 = validateParameter(valid_605808, JString, required = false,
                                 default = nil)
  if valid_605808 != nil:
    section.add "X-Amz-SignedHeaders", valid_605808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605810: Call_RevokeIpRules_605798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_605810.validator(path, query, header, formData, body)
  let scheme = call_605810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605810.url(scheme.get, call_605810.host, call_605810.base,
                         call_605810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605810, url, valid)

proc call*(call_605811: Call_RevokeIpRules_605798; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_605812 = newJObject()
  if body != nil:
    body_605812 = body
  result = call_605811.call(nil, nil, nil, nil, body_605812)

var revokeIpRules* = Call_RevokeIpRules_605798(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_605799, base: "/", url: url_RevokeIpRules_605800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_605813 = ref object of OpenApiRestCall_604658
proc url_StartWorkspaces_605815(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkspaces_605814(path: JsonNode; query: JsonNode;
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
  var valid_605816 = header.getOrDefault("X-Amz-Target")
  valid_605816 = validateParameter(valid_605816, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_605816 != nil:
    section.add "X-Amz-Target", valid_605816
  var valid_605817 = header.getOrDefault("X-Amz-Signature")
  valid_605817 = validateParameter(valid_605817, JString, required = false,
                                 default = nil)
  if valid_605817 != nil:
    section.add "X-Amz-Signature", valid_605817
  var valid_605818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605818 = validateParameter(valid_605818, JString, required = false,
                                 default = nil)
  if valid_605818 != nil:
    section.add "X-Amz-Content-Sha256", valid_605818
  var valid_605819 = header.getOrDefault("X-Amz-Date")
  valid_605819 = validateParameter(valid_605819, JString, required = false,
                                 default = nil)
  if valid_605819 != nil:
    section.add "X-Amz-Date", valid_605819
  var valid_605820 = header.getOrDefault("X-Amz-Credential")
  valid_605820 = validateParameter(valid_605820, JString, required = false,
                                 default = nil)
  if valid_605820 != nil:
    section.add "X-Amz-Credential", valid_605820
  var valid_605821 = header.getOrDefault("X-Amz-Security-Token")
  valid_605821 = validateParameter(valid_605821, JString, required = false,
                                 default = nil)
  if valid_605821 != nil:
    section.add "X-Amz-Security-Token", valid_605821
  var valid_605822 = header.getOrDefault("X-Amz-Algorithm")
  valid_605822 = validateParameter(valid_605822, JString, required = false,
                                 default = nil)
  if valid_605822 != nil:
    section.add "X-Amz-Algorithm", valid_605822
  var valid_605823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605823 = validateParameter(valid_605823, JString, required = false,
                                 default = nil)
  if valid_605823 != nil:
    section.add "X-Amz-SignedHeaders", valid_605823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605825: Call_StartWorkspaces_605813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_605825.validator(path, query, header, formData, body)
  let scheme = call_605825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605825.url(scheme.get, call_605825.host, call_605825.base,
                         call_605825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605825, url, valid)

proc call*(call_605826: Call_StartWorkspaces_605813; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_605827 = newJObject()
  if body != nil:
    body_605827 = body
  result = call_605826.call(nil, nil, nil, nil, body_605827)

var startWorkspaces* = Call_StartWorkspaces_605813(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_605814, base: "/", url: url_StartWorkspaces_605815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_605828 = ref object of OpenApiRestCall_604658
proc url_StopWorkspaces_605830(protocol: Scheme; host: string; base: string;
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

proc validate_StopWorkspaces_605829(path: JsonNode; query: JsonNode;
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
  var valid_605831 = header.getOrDefault("X-Amz-Target")
  valid_605831 = validateParameter(valid_605831, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_605831 != nil:
    section.add "X-Amz-Target", valid_605831
  var valid_605832 = header.getOrDefault("X-Amz-Signature")
  valid_605832 = validateParameter(valid_605832, JString, required = false,
                                 default = nil)
  if valid_605832 != nil:
    section.add "X-Amz-Signature", valid_605832
  var valid_605833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605833 = validateParameter(valid_605833, JString, required = false,
                                 default = nil)
  if valid_605833 != nil:
    section.add "X-Amz-Content-Sha256", valid_605833
  var valid_605834 = header.getOrDefault("X-Amz-Date")
  valid_605834 = validateParameter(valid_605834, JString, required = false,
                                 default = nil)
  if valid_605834 != nil:
    section.add "X-Amz-Date", valid_605834
  var valid_605835 = header.getOrDefault("X-Amz-Credential")
  valid_605835 = validateParameter(valid_605835, JString, required = false,
                                 default = nil)
  if valid_605835 != nil:
    section.add "X-Amz-Credential", valid_605835
  var valid_605836 = header.getOrDefault("X-Amz-Security-Token")
  valid_605836 = validateParameter(valid_605836, JString, required = false,
                                 default = nil)
  if valid_605836 != nil:
    section.add "X-Amz-Security-Token", valid_605836
  var valid_605837 = header.getOrDefault("X-Amz-Algorithm")
  valid_605837 = validateParameter(valid_605837, JString, required = false,
                                 default = nil)
  if valid_605837 != nil:
    section.add "X-Amz-Algorithm", valid_605837
  var valid_605838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605838 = validateParameter(valid_605838, JString, required = false,
                                 default = nil)
  if valid_605838 != nil:
    section.add "X-Amz-SignedHeaders", valid_605838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605840: Call_StopWorkspaces_605828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_605840.validator(path, query, header, formData, body)
  let scheme = call_605840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605840.url(scheme.get, call_605840.host, call_605840.base,
                         call_605840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605840, url, valid)

proc call*(call_605841: Call_StopWorkspaces_605828; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_605842 = newJObject()
  if body != nil:
    body_605842 = body
  result = call_605841.call(nil, nil, nil, nil, body_605842)

var stopWorkspaces* = Call_StopWorkspaces_605828(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_605829, base: "/", url: url_StopWorkspaces_605830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_605843 = ref object of OpenApiRestCall_604658
proc url_TerminateWorkspaces_605845(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateWorkspaces_605844(path: JsonNode; query: JsonNode;
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
  var valid_605846 = header.getOrDefault("X-Amz-Target")
  valid_605846 = validateParameter(valid_605846, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_605846 != nil:
    section.add "X-Amz-Target", valid_605846
  var valid_605847 = header.getOrDefault("X-Amz-Signature")
  valid_605847 = validateParameter(valid_605847, JString, required = false,
                                 default = nil)
  if valid_605847 != nil:
    section.add "X-Amz-Signature", valid_605847
  var valid_605848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605848 = validateParameter(valid_605848, JString, required = false,
                                 default = nil)
  if valid_605848 != nil:
    section.add "X-Amz-Content-Sha256", valid_605848
  var valid_605849 = header.getOrDefault("X-Amz-Date")
  valid_605849 = validateParameter(valid_605849, JString, required = false,
                                 default = nil)
  if valid_605849 != nil:
    section.add "X-Amz-Date", valid_605849
  var valid_605850 = header.getOrDefault("X-Amz-Credential")
  valid_605850 = validateParameter(valid_605850, JString, required = false,
                                 default = nil)
  if valid_605850 != nil:
    section.add "X-Amz-Credential", valid_605850
  var valid_605851 = header.getOrDefault("X-Amz-Security-Token")
  valid_605851 = validateParameter(valid_605851, JString, required = false,
                                 default = nil)
  if valid_605851 != nil:
    section.add "X-Amz-Security-Token", valid_605851
  var valid_605852 = header.getOrDefault("X-Amz-Algorithm")
  valid_605852 = validateParameter(valid_605852, JString, required = false,
                                 default = nil)
  if valid_605852 != nil:
    section.add "X-Amz-Algorithm", valid_605852
  var valid_605853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605853 = validateParameter(valid_605853, JString, required = false,
                                 default = nil)
  if valid_605853 != nil:
    section.add "X-Amz-SignedHeaders", valid_605853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605855: Call_TerminateWorkspaces_605843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_605855.validator(path, query, header, formData, body)
  let scheme = call_605855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605855.url(scheme.get, call_605855.host, call_605855.base,
                         call_605855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605855, url, valid)

proc call*(call_605856: Call_TerminateWorkspaces_605843; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_605857 = newJObject()
  if body != nil:
    body_605857 = body
  result = call_605856.call(nil, nil, nil, nil, body_605857)

var terminateWorkspaces* = Call_TerminateWorkspaces_605843(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_605844, base: "/",
    url: url_TerminateWorkspaces_605845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_605858 = ref object of OpenApiRestCall_604658
proc url_UpdateRulesOfIpGroup_605860(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRulesOfIpGroup_605859(path: JsonNode; query: JsonNode;
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
  var valid_605861 = header.getOrDefault("X-Amz-Target")
  valid_605861 = validateParameter(valid_605861, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_605861 != nil:
    section.add "X-Amz-Target", valid_605861
  var valid_605862 = header.getOrDefault("X-Amz-Signature")
  valid_605862 = validateParameter(valid_605862, JString, required = false,
                                 default = nil)
  if valid_605862 != nil:
    section.add "X-Amz-Signature", valid_605862
  var valid_605863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605863 = validateParameter(valid_605863, JString, required = false,
                                 default = nil)
  if valid_605863 != nil:
    section.add "X-Amz-Content-Sha256", valid_605863
  var valid_605864 = header.getOrDefault("X-Amz-Date")
  valid_605864 = validateParameter(valid_605864, JString, required = false,
                                 default = nil)
  if valid_605864 != nil:
    section.add "X-Amz-Date", valid_605864
  var valid_605865 = header.getOrDefault("X-Amz-Credential")
  valid_605865 = validateParameter(valid_605865, JString, required = false,
                                 default = nil)
  if valid_605865 != nil:
    section.add "X-Amz-Credential", valid_605865
  var valid_605866 = header.getOrDefault("X-Amz-Security-Token")
  valid_605866 = validateParameter(valid_605866, JString, required = false,
                                 default = nil)
  if valid_605866 != nil:
    section.add "X-Amz-Security-Token", valid_605866
  var valid_605867 = header.getOrDefault("X-Amz-Algorithm")
  valid_605867 = validateParameter(valid_605867, JString, required = false,
                                 default = nil)
  if valid_605867 != nil:
    section.add "X-Amz-Algorithm", valid_605867
  var valid_605868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605868 = validateParameter(valid_605868, JString, required = false,
                                 default = nil)
  if valid_605868 != nil:
    section.add "X-Amz-SignedHeaders", valid_605868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605870: Call_UpdateRulesOfIpGroup_605858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_605870.validator(path, query, header, formData, body)
  let scheme = call_605870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605870.url(scheme.get, call_605870.host, call_605870.base,
                         call_605870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605870, url, valid)

proc call*(call_605871: Call_UpdateRulesOfIpGroup_605858; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_605872 = newJObject()
  if body != nil:
    body_605872 = body
  result = call_605871.call(nil, nil, nil, nil, body_605872)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_605858(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_605859, base: "/",
    url: url_UpdateRulesOfIpGroup_605860, schemes: {Scheme.Https, Scheme.Http})
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
