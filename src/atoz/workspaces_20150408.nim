
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_AssociateIpGroups_612996 = ref object of OpenApiRestCall_612658
proc url_AssociateIpGroups_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateIpGroups_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AssociateIpGroups_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AssociateIpGroups_612996; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var associateIpGroups* = Call_AssociateIpGroups_612996(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_612997, base: "/",
    url: url_AssociateIpGroups_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_613265 = ref object of OpenApiRestCall_612658
proc url_AuthorizeIpRules_613267(protocol: Scheme; host: string; base: string;
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

proc validate_AuthorizeIpRules_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_AuthorizeIpRules_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AuthorizeIpRules_613265; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var authorizeIpRules* = Call_AuthorizeIpRules_613265(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_613266, base: "/",
    url: url_AuthorizeIpRules_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_613280 = ref object of OpenApiRestCall_612658
proc url_CopyWorkspaceImage_613282(protocol: Scheme; host: string; base: string;
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

proc validate_CopyWorkspaceImage_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CopyWorkspaceImage_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CopyWorkspaceImage_613280; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_613280(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_613281, base: "/",
    url: url_CopyWorkspaceImage_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_613295 = ref object of OpenApiRestCall_612658
proc url_CreateIpGroup_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIpGroup_613296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateIpGroup_613295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateIpGroup_613295; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createIpGroup* = Call_CreateIpGroup_613295(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_613296, base: "/", url: url_CreateIpGroup_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_613310 = ref object of OpenApiRestCall_612658
proc url_CreateTags_613312(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_613311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_CreateTags_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateTags_613310; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createTags* = Call_CreateTags_613310(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_613311,
                                      base: "/", url: url_CreateTags_613312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_613325 = ref object of OpenApiRestCall_612658
proc url_CreateWorkspaces_613327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkspaces_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_CreateWorkspaces_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateWorkspaces_613325; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createWorkspaces* = Call_CreateWorkspaces_613325(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_613326, base: "/",
    url: url_CreateWorkspaces_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_613340 = ref object of OpenApiRestCall_612658
proc url_DeleteIpGroup_613342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIpGroup_613341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DeleteIpGroup_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DeleteIpGroup_613340; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var deleteIpGroup* = Call_DeleteIpGroup_613340(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_613341, base: "/", url: url_DeleteIpGroup_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_613355 = ref object of OpenApiRestCall_612658
proc url_DeleteTags_613357(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_613356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DeleteTags_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DeleteTags_613355; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var deleteTags* = Call_DeleteTags_613355(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_613356,
                                      base: "/", url: url_DeleteTags_613357,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_613370 = ref object of OpenApiRestCall_612658
proc url_DeleteWorkspaceImage_613372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkspaceImage_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_DeleteWorkspaceImage_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_DeleteWorkspaceImage_613370; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_613370(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_613371, base: "/",
    url: url_DeleteWorkspaceImage_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWorkspaceDirectory_613385 = ref object of OpenApiRestCall_612658
proc url_DeregisterWorkspaceDirectory_613387(protocol: Scheme; host: string;
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

proc validate_DeregisterWorkspaceDirectory_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "WorkspacesService.DeregisterWorkspaceDirectory"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_DeregisterWorkspaceDirectory_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_DeregisterWorkspaceDirectory_613385; body: JsonNode): Recallable =
  ## deregisterWorkspaceDirectory
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var deregisterWorkspaceDirectory* = Call_DeregisterWorkspaceDirectory_613385(
    name: "deregisterWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeregisterWorkspaceDirectory",
    validator: validate_DeregisterWorkspaceDirectory_613386, base: "/",
    url: url_DeregisterWorkspaceDirectory_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_613400 = ref object of OpenApiRestCall_612658
proc url_DescribeAccount_613402(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAccount_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_DescribeAccount_613400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_DescribeAccount_613400; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var describeAccount* = Call_DescribeAccount_613400(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_613401, base: "/", url: url_DescribeAccount_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_613415 = ref object of OpenApiRestCall_612658
proc url_DescribeAccountModifications_613417(protocol: Scheme; host: string;
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

proc validate_DescribeAccountModifications_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_DescribeAccountModifications_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_DescribeAccountModifications_613415; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var describeAccountModifications* = Call_DescribeAccountModifications_613415(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_613416, base: "/",
    url: url_DescribeAccountModifications_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_613430 = ref object of OpenApiRestCall_612658
proc url_DescribeClientProperties_613432(protocol: Scheme; host: string;
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

proc validate_DescribeClientProperties_613431(path: JsonNode; query: JsonNode;
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
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

proc call*(call_613442: Call_DescribeClientProperties_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_DescribeClientProperties_613430; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var describeClientProperties* = Call_DescribeClientProperties_613430(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_613431, base: "/",
    url: url_DescribeClientProperties_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_613445 = ref object of OpenApiRestCall_612658
proc url_DescribeIpGroups_613447(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIpGroups_613446(path: JsonNode; query: JsonNode;
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_DescribeIpGroups_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_DescribeIpGroups_613445; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var describeIpGroups* = Call_DescribeIpGroups_613445(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_613446, base: "/",
    url: url_DescribeIpGroups_613447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_613460 = ref object of OpenApiRestCall_612658
proc url_DescribeTags_613462(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_613461(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_DescribeTags_613460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_DescribeTags_613460; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var describeTags* = Call_DescribeTags_613460(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_613461, base: "/", url: url_DescribeTags_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_613475 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspaceBundles_613477(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceBundles_613476(path: JsonNode; query: JsonNode;
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
  var valid_613478 = query.getOrDefault("NextToken")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "NextToken", valid_613478
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
  var valid_613479 = header.getOrDefault("X-Amz-Target")
  valid_613479 = validateParameter(valid_613479, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_613479 != nil:
    section.add "X-Amz-Target", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_DescribeWorkspaceBundles_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_DescribeWorkspaceBundles_613475; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613490 = newJObject()
  var body_613491 = newJObject()
  add(query_613490, "NextToken", newJString(NextToken))
  if body != nil:
    body_613491 = body
  result = call_613489.call(nil, query_613490, nil, nil, body_613491)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_613475(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_613476, base: "/",
    url: url_DescribeWorkspaceBundles_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_613493 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspaceDirectories_613495(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceDirectories_613494(path: JsonNode; query: JsonNode;
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
  var valid_613496 = query.getOrDefault("NextToken")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "NextToken", valid_613496
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
  var valid_613497 = header.getOrDefault("X-Amz-Target")
  valid_613497 = validateParameter(valid_613497, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_613497 != nil:
    section.add "X-Amz-Target", valid_613497
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
  var valid_613502 = header.getOrDefault("X-Amz-Security-Token")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Security-Token", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Algorithm")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Algorithm", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-SignedHeaders", valid_613504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613506: Call_DescribeWorkspaceDirectories_613493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_613506.validator(path, query, header, formData, body)
  let scheme = call_613506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613506.url(scheme.get, call_613506.host, call_613506.base,
                         call_613506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613506, url, valid)

proc call*(call_613507: Call_DescribeWorkspaceDirectories_613493; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613508 = newJObject()
  var body_613509 = newJObject()
  add(query_613508, "NextToken", newJString(NextToken))
  if body != nil:
    body_613509 = body
  result = call_613507.call(nil, query_613508, nil, nil, body_613509)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_613493(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_613494, base: "/",
    url: url_DescribeWorkspaceDirectories_613495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_613510 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspaceImages_613512(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaceImages_613511(path: JsonNode; query: JsonNode;
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
  var valid_613513 = header.getOrDefault("X-Amz-Target")
  valid_613513 = validateParameter(valid_613513, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_613513 != nil:
    section.add "X-Amz-Target", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Signature")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Signature", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Content-Sha256", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Date")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Date", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Credential")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Credential", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Security-Token")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Security-Token", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Algorithm")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Algorithm", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-SignedHeaders", valid_613520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613522: Call_DescribeWorkspaceImages_613510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_613522.validator(path, query, header, formData, body)
  let scheme = call_613522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613522.url(scheme.get, call_613522.host, call_613522.base,
                         call_613522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613522, url, valid)

proc call*(call_613523: Call_DescribeWorkspaceImages_613510; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_613524 = newJObject()
  if body != nil:
    body_613524 = body
  result = call_613523.call(nil, nil, nil, nil, body_613524)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_613510(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_613511, base: "/",
    url: url_DescribeWorkspaceImages_613512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_613525 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspaceSnapshots_613527(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceSnapshots_613526(path: JsonNode; query: JsonNode;
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
  var valid_613528 = header.getOrDefault("X-Amz-Target")
  valid_613528 = validateParameter(valid_613528, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_613528 != nil:
    section.add "X-Amz-Target", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Signature")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Signature", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Content-Sha256", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Date")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Date", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Credential")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Credential", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Security-Token")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Security-Token", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Algorithm")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Algorithm", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-SignedHeaders", valid_613535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613537: Call_DescribeWorkspaceSnapshots_613525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_613537.validator(path, query, header, formData, body)
  let scheme = call_613537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613537.url(scheme.get, call_613537.host, call_613537.base,
                         call_613537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613537, url, valid)

proc call*(call_613538: Call_DescribeWorkspaceSnapshots_613525; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_613539 = newJObject()
  if body != nil:
    body_613539 = body
  result = call_613538.call(nil, nil, nil, nil, body_613539)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_613525(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_613526, base: "/",
    url: url_DescribeWorkspaceSnapshots_613527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_613540 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspaces_613542(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaces_613541(path: JsonNode; query: JsonNode;
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
  var valid_613543 = query.getOrDefault("NextToken")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "NextToken", valid_613543
  var valid_613544 = query.getOrDefault("Limit")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "Limit", valid_613544
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
  var valid_613545 = header.getOrDefault("X-Amz-Target")
  valid_613545 = validateParameter(valid_613545, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_613545 != nil:
    section.add "X-Amz-Target", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Signature")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Signature", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Content-Sha256", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Date")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Date", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Credential")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Credential", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Security-Token")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Security-Token", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Algorithm")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Algorithm", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-SignedHeaders", valid_613552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613554: Call_DescribeWorkspaces_613540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_613554.validator(path, query, header, formData, body)
  let scheme = call_613554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613554.url(scheme.get, call_613554.host, call_613554.base,
                         call_613554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613554, url, valid)

proc call*(call_613555: Call_DescribeWorkspaces_613540; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_613556 = newJObject()
  var body_613557 = newJObject()
  add(query_613556, "NextToken", newJString(NextToken))
  add(query_613556, "Limit", newJString(Limit))
  if body != nil:
    body_613557 = body
  result = call_613555.call(nil, query_613556, nil, nil, body_613557)

var describeWorkspaces* = Call_DescribeWorkspaces_613540(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_613541, base: "/",
    url: url_DescribeWorkspaces_613542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_613558 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkspacesConnectionStatus_613560(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspacesConnectionStatus_613559(path: JsonNode;
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
  var valid_613561 = header.getOrDefault("X-Amz-Target")
  valid_613561 = validateParameter(valid_613561, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_613561 != nil:
    section.add "X-Amz-Target", valid_613561
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
  var valid_613566 = header.getOrDefault("X-Amz-Security-Token")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Security-Token", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Algorithm")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Algorithm", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-SignedHeaders", valid_613568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613570: Call_DescribeWorkspacesConnectionStatus_613558;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_613570.validator(path, query, header, formData, body)
  let scheme = call_613570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613570.url(scheme.get, call_613570.host, call_613570.base,
                         call_613570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613570, url, valid)

proc call*(call_613571: Call_DescribeWorkspacesConnectionStatus_613558;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_613572 = newJObject()
  if body != nil:
    body_613572 = body
  result = call_613571.call(nil, nil, nil, nil, body_613572)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_613558(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_613559, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_613560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_613573 = ref object of OpenApiRestCall_612658
proc url_DisassociateIpGroups_613575(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateIpGroups_613574(path: JsonNode; query: JsonNode;
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
  var valid_613576 = header.getOrDefault("X-Amz-Target")
  valid_613576 = validateParameter(valid_613576, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_613576 != nil:
    section.add "X-Amz-Target", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Signature")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Signature", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Content-Sha256", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Date")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Date", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Credential")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Credential", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Security-Token")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Security-Token", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Algorithm")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Algorithm", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-SignedHeaders", valid_613583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613585: Call_DisassociateIpGroups_613573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_613585.validator(path, query, header, formData, body)
  let scheme = call_613585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613585.url(scheme.get, call_613585.host, call_613585.base,
                         call_613585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613585, url, valid)

proc call*(call_613586: Call_DisassociateIpGroups_613573; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_613587 = newJObject()
  if body != nil:
    body_613587 = body
  result = call_613586.call(nil, nil, nil, nil, body_613587)

var disassociateIpGroups* = Call_DisassociateIpGroups_613573(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_613574, base: "/",
    url: url_DisassociateIpGroups_613575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_613588 = ref object of OpenApiRestCall_612658
proc url_ImportWorkspaceImage_613590(protocol: Scheme; host: string; base: string;
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

proc validate_ImportWorkspaceImage_613589(path: JsonNode; query: JsonNode;
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
  var valid_613591 = header.getOrDefault("X-Amz-Target")
  valid_613591 = validateParameter(valid_613591, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_613591 != nil:
    section.add "X-Amz-Target", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Signature")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Signature", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Content-Sha256", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Date")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Date", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Credential")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Credential", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Security-Token")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Security-Token", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Algorithm")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Algorithm", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-SignedHeaders", valid_613598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613600: Call_ImportWorkspaceImage_613588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_613600.validator(path, query, header, formData, body)
  let scheme = call_613600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613600.url(scheme.get, call_613600.host, call_613600.base,
                         call_613600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613600, url, valid)

proc call*(call_613601: Call_ImportWorkspaceImage_613588; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_613602 = newJObject()
  if body != nil:
    body_613602 = body
  result = call_613601.call(nil, nil, nil, nil, body_613602)

var importWorkspaceImage* = Call_ImportWorkspaceImage_613588(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_613589, base: "/",
    url: url_ImportWorkspaceImage_613590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_613603 = ref object of OpenApiRestCall_612658
proc url_ListAvailableManagementCidrRanges_613605(protocol: Scheme; host: string;
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

proc validate_ListAvailableManagementCidrRanges_613604(path: JsonNode;
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
  var valid_613606 = header.getOrDefault("X-Amz-Target")
  valid_613606 = validateParameter(valid_613606, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_613606 != nil:
    section.add "X-Amz-Target", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Signature")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Signature", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Content-Sha256", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Date")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Date", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Credential")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Credential", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Security-Token")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Security-Token", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Algorithm")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Algorithm", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-SignedHeaders", valid_613613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613615: Call_ListAvailableManagementCidrRanges_613603;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_613615.validator(path, query, header, formData, body)
  let scheme = call_613615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613615.url(scheme.get, call_613615.host, call_613615.base,
                         call_613615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613615, url, valid)

proc call*(call_613616: Call_ListAvailableManagementCidrRanges_613603;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_613617 = newJObject()
  if body != nil:
    body_613617 = body
  result = call_613616.call(nil, nil, nil, nil, body_613617)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_613603(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_613604, base: "/",
    url: url_ListAvailableManagementCidrRanges_613605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MigrateWorkspace_613618 = ref object of OpenApiRestCall_612658
proc url_MigrateWorkspace_613620(protocol: Scheme; host: string; base: string;
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

proc validate_MigrateWorkspace_613619(path: JsonNode; query: JsonNode;
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
  var valid_613621 = header.getOrDefault("X-Amz-Target")
  valid_613621 = validateParameter(valid_613621, JString, required = true, default = newJString(
      "WorkspacesService.MigrateWorkspace"))
  if valid_613621 != nil:
    section.add "X-Amz-Target", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Signature")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Signature", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Content-Sha256", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Date")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Date", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Credential")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Credential", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Security-Token")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Security-Token", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Algorithm")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Algorithm", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-SignedHeaders", valid_613628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613630: Call_MigrateWorkspace_613618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ## 
  let valid = call_613630.validator(path, query, header, formData, body)
  let scheme = call_613630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613630.url(scheme.get, call_613630.host, call_613630.base,
                         call_613630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613630, url, valid)

proc call*(call_613631: Call_MigrateWorkspace_613618; body: JsonNode): Recallable =
  ## migrateWorkspace
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ##   body: JObject (required)
  var body_613632 = newJObject()
  if body != nil:
    body_613632 = body
  result = call_613631.call(nil, nil, nil, nil, body_613632)

var migrateWorkspace* = Call_MigrateWorkspace_613618(name: "migrateWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.MigrateWorkspace",
    validator: validate_MigrateWorkspace_613619, base: "/",
    url: url_MigrateWorkspace_613620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_613633 = ref object of OpenApiRestCall_612658
proc url_ModifyAccount_613635(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyAccount_613634(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613636 = header.getOrDefault("X-Amz-Target")
  valid_613636 = validateParameter(valid_613636, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_613636 != nil:
    section.add "X-Amz-Target", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Signature")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Signature", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Content-Sha256", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Date")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Date", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Credential")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Credential", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Security-Token")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Security-Token", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Algorithm")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Algorithm", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-SignedHeaders", valid_613643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613645: Call_ModifyAccount_613633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_613645.validator(path, query, header, formData, body)
  let scheme = call_613645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613645.url(scheme.get, call_613645.host, call_613645.base,
                         call_613645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613645, url, valid)

proc call*(call_613646: Call_ModifyAccount_613633; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_613647 = newJObject()
  if body != nil:
    body_613647 = body
  result = call_613646.call(nil, nil, nil, nil, body_613647)

var modifyAccount* = Call_ModifyAccount_613633(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_613634, base: "/", url: url_ModifyAccount_613635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_613648 = ref object of OpenApiRestCall_612658
proc url_ModifyClientProperties_613650(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyClientProperties_613649(path: JsonNode; query: JsonNode;
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
  var valid_613651 = header.getOrDefault("X-Amz-Target")
  valid_613651 = validateParameter(valid_613651, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_613651 != nil:
    section.add "X-Amz-Target", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Signature")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Signature", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Content-Sha256", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Date")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Date", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Credential")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Credential", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Security-Token")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Security-Token", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Algorithm")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Algorithm", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-SignedHeaders", valid_613658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613660: Call_ModifyClientProperties_613648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_613660.validator(path, query, header, formData, body)
  let scheme = call_613660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613660.url(scheme.get, call_613660.host, call_613660.base,
                         call_613660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613660, url, valid)

proc call*(call_613661: Call_ModifyClientProperties_613648; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_613662 = newJObject()
  if body != nil:
    body_613662 = body
  result = call_613661.call(nil, nil, nil, nil, body_613662)

var modifyClientProperties* = Call_ModifyClientProperties_613648(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_613649, base: "/",
    url: url_ModifyClientProperties_613650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifySelfservicePermissions_613663 = ref object of OpenApiRestCall_612658
proc url_ModifySelfservicePermissions_613665(protocol: Scheme; host: string;
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

proc validate_ModifySelfservicePermissions_613664(path: JsonNode; query: JsonNode;
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
  var valid_613666 = header.getOrDefault("X-Amz-Target")
  valid_613666 = validateParameter(valid_613666, JString, required = true, default = newJString(
      "WorkspacesService.ModifySelfservicePermissions"))
  if valid_613666 != nil:
    section.add "X-Amz-Target", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Signature")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Signature", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Content-Sha256", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Date")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Date", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Credential")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Credential", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Security-Token")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Security-Token", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Algorithm")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Algorithm", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-SignedHeaders", valid_613673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613675: Call_ModifySelfservicePermissions_613663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ## 
  let valid = call_613675.validator(path, query, header, formData, body)
  let scheme = call_613675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613675.url(scheme.get, call_613675.host, call_613675.base,
                         call_613675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613675, url, valid)

proc call*(call_613676: Call_ModifySelfservicePermissions_613663; body: JsonNode): Recallable =
  ## modifySelfservicePermissions
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ##   body: JObject (required)
  var body_613677 = newJObject()
  if body != nil:
    body_613677 = body
  result = call_613676.call(nil, nil, nil, nil, body_613677)

var modifySelfservicePermissions* = Call_ModifySelfservicePermissions_613663(
    name: "modifySelfservicePermissions", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifySelfservicePermissions",
    validator: validate_ModifySelfservicePermissions_613664, base: "/",
    url: url_ModifySelfservicePermissions_613665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceAccessProperties_613678 = ref object of OpenApiRestCall_612658
proc url_ModifyWorkspaceAccessProperties_613680(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceAccessProperties_613679(path: JsonNode;
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
  var valid_613681 = header.getOrDefault("X-Amz-Target")
  valid_613681 = validateParameter(valid_613681, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceAccessProperties"))
  if valid_613681 != nil:
    section.add "X-Amz-Target", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Signature")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Signature", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Content-Sha256", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Date")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Date", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Credential")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Credential", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Security-Token")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Security-Token", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Algorithm")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Algorithm", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-SignedHeaders", valid_613688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613690: Call_ModifyWorkspaceAccessProperties_613678;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ## 
  let valid = call_613690.validator(path, query, header, formData, body)
  let scheme = call_613690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613690.url(scheme.get, call_613690.host, call_613690.base,
                         call_613690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613690, url, valid)

proc call*(call_613691: Call_ModifyWorkspaceAccessProperties_613678; body: JsonNode): Recallable =
  ## modifyWorkspaceAccessProperties
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ##   body: JObject (required)
  var body_613692 = newJObject()
  if body != nil:
    body_613692 = body
  result = call_613691.call(nil, nil, nil, nil, body_613692)

var modifyWorkspaceAccessProperties* = Call_ModifyWorkspaceAccessProperties_613678(
    name: "modifyWorkspaceAccessProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceAccessProperties",
    validator: validate_ModifyWorkspaceAccessProperties_613679, base: "/",
    url: url_ModifyWorkspaceAccessProperties_613680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceCreationProperties_613693 = ref object of OpenApiRestCall_612658
proc url_ModifyWorkspaceCreationProperties_613695(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceCreationProperties_613694(path: JsonNode;
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
  var valid_613696 = header.getOrDefault("X-Amz-Target")
  valid_613696 = validateParameter(valid_613696, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceCreationProperties"))
  if valid_613696 != nil:
    section.add "X-Amz-Target", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Signature")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Signature", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Content-Sha256", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Date")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Date", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Credential")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Credential", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Security-Token")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Security-Token", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Algorithm")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Algorithm", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-SignedHeaders", valid_613703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613705: Call_ModifyWorkspaceCreationProperties_613693;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modify the default properties used to create WorkSpaces.
  ## 
  let valid = call_613705.validator(path, query, header, formData, body)
  let scheme = call_613705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613705.url(scheme.get, call_613705.host, call_613705.base,
                         call_613705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613705, url, valid)

proc call*(call_613706: Call_ModifyWorkspaceCreationProperties_613693;
          body: JsonNode): Recallable =
  ## modifyWorkspaceCreationProperties
  ## Modify the default properties used to create WorkSpaces.
  ##   body: JObject (required)
  var body_613707 = newJObject()
  if body != nil:
    body_613707 = body
  result = call_613706.call(nil, nil, nil, nil, body_613707)

var modifyWorkspaceCreationProperties* = Call_ModifyWorkspaceCreationProperties_613693(
    name: "modifyWorkspaceCreationProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceCreationProperties",
    validator: validate_ModifyWorkspaceCreationProperties_613694, base: "/",
    url: url_ModifyWorkspaceCreationProperties_613695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_613708 = ref object of OpenApiRestCall_612658
proc url_ModifyWorkspaceProperties_613710(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceProperties_613709(path: JsonNode; query: JsonNode;
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
  var valid_613711 = header.getOrDefault("X-Amz-Target")
  valid_613711 = validateParameter(valid_613711, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_613711 != nil:
    section.add "X-Amz-Target", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Signature")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Signature", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Content-Sha256", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Date")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Date", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Credential")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Credential", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Security-Token")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Security-Token", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Algorithm")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Algorithm", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-SignedHeaders", valid_613718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613720: Call_ModifyWorkspaceProperties_613708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_613720.validator(path, query, header, formData, body)
  let scheme = call_613720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613720.url(scheme.get, call_613720.host, call_613720.base,
                         call_613720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613720, url, valid)

proc call*(call_613721: Call_ModifyWorkspaceProperties_613708; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_613722 = newJObject()
  if body != nil:
    body_613722 = body
  result = call_613721.call(nil, nil, nil, nil, body_613722)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_613708(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_613709, base: "/",
    url: url_ModifyWorkspaceProperties_613710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_613723 = ref object of OpenApiRestCall_612658
proc url_ModifyWorkspaceState_613725(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyWorkspaceState_613724(path: JsonNode; query: JsonNode;
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
  var valid_613726 = header.getOrDefault("X-Amz-Target")
  valid_613726 = validateParameter(valid_613726, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_613726 != nil:
    section.add "X-Amz-Target", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Signature")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Signature", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Content-Sha256", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Date")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Date", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Credential")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Credential", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Security-Token")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Security-Token", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Algorithm")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Algorithm", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-SignedHeaders", valid_613733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613735: Call_ModifyWorkspaceState_613723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_613735.validator(path, query, header, formData, body)
  let scheme = call_613735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613735.url(scheme.get, call_613735.host, call_613735.base,
                         call_613735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613735, url, valid)

proc call*(call_613736: Call_ModifyWorkspaceState_613723; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_613737 = newJObject()
  if body != nil:
    body_613737 = body
  result = call_613736.call(nil, nil, nil, nil, body_613737)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_613723(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_613724, base: "/",
    url: url_ModifyWorkspaceState_613725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_613738 = ref object of OpenApiRestCall_612658
proc url_RebootWorkspaces_613740(protocol: Scheme; host: string; base: string;
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

proc validate_RebootWorkspaces_613739(path: JsonNode; query: JsonNode;
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
  var valid_613741 = header.getOrDefault("X-Amz-Target")
  valid_613741 = validateParameter(valid_613741, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_613741 != nil:
    section.add "X-Amz-Target", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Signature")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Signature", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Content-Sha256", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Date")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Date", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Credential")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Credential", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Security-Token")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Security-Token", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Algorithm")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Algorithm", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-SignedHeaders", valid_613748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613750: Call_RebootWorkspaces_613738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_613750.validator(path, query, header, formData, body)
  let scheme = call_613750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613750.url(scheme.get, call_613750.host, call_613750.base,
                         call_613750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613750, url, valid)

proc call*(call_613751: Call_RebootWorkspaces_613738; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_613752 = newJObject()
  if body != nil:
    body_613752 = body
  result = call_613751.call(nil, nil, nil, nil, body_613752)

var rebootWorkspaces* = Call_RebootWorkspaces_613738(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_613739, base: "/",
    url: url_RebootWorkspaces_613740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_613753 = ref object of OpenApiRestCall_612658
proc url_RebuildWorkspaces_613755(protocol: Scheme; host: string; base: string;
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

proc validate_RebuildWorkspaces_613754(path: JsonNode; query: JsonNode;
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
  var valid_613756 = header.getOrDefault("X-Amz-Target")
  valid_613756 = validateParameter(valid_613756, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_613756 != nil:
    section.add "X-Amz-Target", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Signature")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Signature", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Content-Sha256", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Date")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Date", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Credential")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Credential", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Security-Token")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Security-Token", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Algorithm")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Algorithm", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-SignedHeaders", valid_613763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613765: Call_RebuildWorkspaces_613753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_613765.validator(path, query, header, formData, body)
  let scheme = call_613765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613765.url(scheme.get, call_613765.host, call_613765.base,
                         call_613765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613765, url, valid)

proc call*(call_613766: Call_RebuildWorkspaces_613753; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_613767 = newJObject()
  if body != nil:
    body_613767 = body
  result = call_613766.call(nil, nil, nil, nil, body_613767)

var rebuildWorkspaces* = Call_RebuildWorkspaces_613753(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_613754, base: "/",
    url: url_RebuildWorkspaces_613755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWorkspaceDirectory_613768 = ref object of OpenApiRestCall_612658
proc url_RegisterWorkspaceDirectory_613770(protocol: Scheme; host: string;
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

proc validate_RegisterWorkspaceDirectory_613769(path: JsonNode; query: JsonNode;
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
  var valid_613771 = header.getOrDefault("X-Amz-Target")
  valid_613771 = validateParameter(valid_613771, JString, required = true, default = newJString(
      "WorkspacesService.RegisterWorkspaceDirectory"))
  if valid_613771 != nil:
    section.add "X-Amz-Target", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Signature")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Signature", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Content-Sha256", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Date")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Date", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Credential")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Credential", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Security-Token")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Security-Token", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Algorithm")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Algorithm", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-SignedHeaders", valid_613778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613780: Call_RegisterWorkspaceDirectory_613768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ## 
  let valid = call_613780.validator(path, query, header, formData, body)
  let scheme = call_613780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613780.url(scheme.get, call_613780.host, call_613780.base,
                         call_613780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613780, url, valid)

proc call*(call_613781: Call_RegisterWorkspaceDirectory_613768; body: JsonNode): Recallable =
  ## registerWorkspaceDirectory
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ##   body: JObject (required)
  var body_613782 = newJObject()
  if body != nil:
    body_613782 = body
  result = call_613781.call(nil, nil, nil, nil, body_613782)

var registerWorkspaceDirectory* = Call_RegisterWorkspaceDirectory_613768(
    name: "registerWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RegisterWorkspaceDirectory",
    validator: validate_RegisterWorkspaceDirectory_613769, base: "/",
    url: url_RegisterWorkspaceDirectory_613770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_613783 = ref object of OpenApiRestCall_612658
proc url_RestoreWorkspace_613785(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreWorkspace_613784(path: JsonNode; query: JsonNode;
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
  var valid_613786 = header.getOrDefault("X-Amz-Target")
  valid_613786 = validateParameter(valid_613786, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_613786 != nil:
    section.add "X-Amz-Target", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Signature")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Signature", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Content-Sha256", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Date")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Date", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Credential")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Credential", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Security-Token")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Security-Token", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Algorithm")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Algorithm", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-SignedHeaders", valid_613793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613795: Call_RestoreWorkspace_613783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_613795.validator(path, query, header, formData, body)
  let scheme = call_613795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613795.url(scheme.get, call_613795.host, call_613795.base,
                         call_613795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613795, url, valid)

proc call*(call_613796: Call_RestoreWorkspace_613783; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_613797 = newJObject()
  if body != nil:
    body_613797 = body
  result = call_613796.call(nil, nil, nil, nil, body_613797)

var restoreWorkspace* = Call_RestoreWorkspace_613783(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_613784, base: "/",
    url: url_RestoreWorkspace_613785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_613798 = ref object of OpenApiRestCall_612658
proc url_RevokeIpRules_613800(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeIpRules_613799(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613801 = header.getOrDefault("X-Amz-Target")
  valid_613801 = validateParameter(valid_613801, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_613801 != nil:
    section.add "X-Amz-Target", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Signature")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Signature", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Content-Sha256", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Date")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Date", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Credential")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Credential", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Security-Token")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Security-Token", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Algorithm")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Algorithm", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-SignedHeaders", valid_613808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613810: Call_RevokeIpRules_613798; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_613810.validator(path, query, header, formData, body)
  let scheme = call_613810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613810.url(scheme.get, call_613810.host, call_613810.base,
                         call_613810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613810, url, valid)

proc call*(call_613811: Call_RevokeIpRules_613798; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_613812 = newJObject()
  if body != nil:
    body_613812 = body
  result = call_613811.call(nil, nil, nil, nil, body_613812)

var revokeIpRules* = Call_RevokeIpRules_613798(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_613799, base: "/", url: url_RevokeIpRules_613800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_613813 = ref object of OpenApiRestCall_612658
proc url_StartWorkspaces_613815(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkspaces_613814(path: JsonNode; query: JsonNode;
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
  var valid_613816 = header.getOrDefault("X-Amz-Target")
  valid_613816 = validateParameter(valid_613816, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_613816 != nil:
    section.add "X-Amz-Target", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Signature")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Signature", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Content-Sha256", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Date")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Date", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Credential")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Credential", valid_613820
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

proc call*(call_613825: Call_StartWorkspaces_613813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_613825.validator(path, query, header, formData, body)
  let scheme = call_613825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613825.url(scheme.get, call_613825.host, call_613825.base,
                         call_613825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613825, url, valid)

proc call*(call_613826: Call_StartWorkspaces_613813; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_613827 = newJObject()
  if body != nil:
    body_613827 = body
  result = call_613826.call(nil, nil, nil, nil, body_613827)

var startWorkspaces* = Call_StartWorkspaces_613813(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_613814, base: "/", url: url_StartWorkspaces_613815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_613828 = ref object of OpenApiRestCall_612658
proc url_StopWorkspaces_613830(protocol: Scheme; host: string; base: string;
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

proc validate_StopWorkspaces_613829(path: JsonNode; query: JsonNode;
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
  var valid_613831 = header.getOrDefault("X-Amz-Target")
  valid_613831 = validateParameter(valid_613831, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_613831 != nil:
    section.add "X-Amz-Target", valid_613831
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
  var valid_613836 = header.getOrDefault("X-Amz-Security-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Security-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Algorithm")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Algorithm", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-SignedHeaders", valid_613838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613840: Call_StopWorkspaces_613828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_613840.validator(path, query, header, formData, body)
  let scheme = call_613840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613840.url(scheme.get, call_613840.host, call_613840.base,
                         call_613840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613840, url, valid)

proc call*(call_613841: Call_StopWorkspaces_613828; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_613842 = newJObject()
  if body != nil:
    body_613842 = body
  result = call_613841.call(nil, nil, nil, nil, body_613842)

var stopWorkspaces* = Call_StopWorkspaces_613828(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_613829, base: "/", url: url_StopWorkspaces_613830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_613843 = ref object of OpenApiRestCall_612658
proc url_TerminateWorkspaces_613845(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateWorkspaces_613844(path: JsonNode; query: JsonNode;
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
  var valid_613846 = header.getOrDefault("X-Amz-Target")
  valid_613846 = validateParameter(valid_613846, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_613846 != nil:
    section.add "X-Amz-Target", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Signature")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Signature", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Content-Sha256", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Date")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Date", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Credential")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Credential", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Security-Token")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Security-Token", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Algorithm")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Algorithm", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-SignedHeaders", valid_613853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613855: Call_TerminateWorkspaces_613843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_613855.validator(path, query, header, formData, body)
  let scheme = call_613855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613855.url(scheme.get, call_613855.host, call_613855.base,
                         call_613855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613855, url, valid)

proc call*(call_613856: Call_TerminateWorkspaces_613843; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_613857 = newJObject()
  if body != nil:
    body_613857 = body
  result = call_613856.call(nil, nil, nil, nil, body_613857)

var terminateWorkspaces* = Call_TerminateWorkspaces_613843(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_613844, base: "/",
    url: url_TerminateWorkspaces_613845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_613858 = ref object of OpenApiRestCall_612658
proc url_UpdateRulesOfIpGroup_613860(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRulesOfIpGroup_613859(path: JsonNode; query: JsonNode;
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
  var valid_613861 = header.getOrDefault("X-Amz-Target")
  valid_613861 = validateParameter(valid_613861, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_613861 != nil:
    section.add "X-Amz-Target", valid_613861
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
  var valid_613866 = header.getOrDefault("X-Amz-Security-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Security-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Algorithm")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Algorithm", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-SignedHeaders", valid_613868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613870: Call_UpdateRulesOfIpGroup_613858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_613870.validator(path, query, header, formData, body)
  let scheme = call_613870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613870.url(scheme.get, call_613870.host, call_613870.base,
                         call_613870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613870, url, valid)

proc call*(call_613871: Call_UpdateRulesOfIpGroup_613858; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_613872 = newJObject()
  if body != nil:
    body_613872 = body
  result = call_613871.call(nil, nil, nil, nil, body_613872)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_613858(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_613859, base: "/",
    url: url_UpdateRulesOfIpGroup_613860, schemes: {Scheme.Https, Scheme.Http})
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
