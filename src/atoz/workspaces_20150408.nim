
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "workspaces.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workspaces.ap-southeast-1.amazonaws.com", "us-west-2": "workspaces.us-west-2.amazonaws.com", "eu-west-2": "workspaces.eu-west-2.amazonaws.com", "ap-northeast-3": "workspaces.ap-northeast-3.amazonaws.com", "eu-central-1": "workspaces.eu-central-1.amazonaws.com", "us-east-2": "workspaces.us-east-2.amazonaws.com", "us-east-1": "workspaces.us-east-1.amazonaws.com", "cn-northwest-1": "workspaces.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "workspaces.ap-south-1.amazonaws.com", "eu-north-1": "workspaces.eu-north-1.amazonaws.com", "ap-northeast-2": "workspaces.ap-northeast-2.amazonaws.com", "us-west-1": "workspaces.us-west-1.amazonaws.com", "us-gov-east-1": "workspaces.us-gov-east-1.amazonaws.com", "eu-west-3": "workspaces.eu-west-3.amazonaws.com", "cn-north-1": "workspaces.cn-north-1.amazonaws.com.cn", "sa-east-1": "workspaces.sa-east-1.amazonaws.com", "eu-west-1": "workspaces.eu-west-1.amazonaws.com", "us-gov-west-1": "workspaces.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workspaces.ap-southeast-2.amazonaws.com", "ca-central-1": "workspaces.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateIpGroups_402656294 = ref object of OpenApiRestCall_402656044
proc url_AssociateIpGroups_402656296(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateIpGroups_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AssociateIpGroups_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified IP access control group with the specified directory.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AssociateIpGroups_402656294; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var associateIpGroups* = Call_AssociateIpGroups_402656294(
    name: "associateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_402656295, base: "/",
    makeUrl: url_AssociateIpGroups_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_402656489 = ref object of OpenApiRestCall_402656044
proc url_AuthorizeIpRules_402656491(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AuthorizeIpRules_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_AuthorizeIpRules_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AuthorizeIpRules_402656489; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   
                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var authorizeIpRules* = Call_AuthorizeIpRules_402656489(
    name: "authorizeIpRules", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_402656490, base: "/",
    makeUrl: url_AuthorizeIpRules_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_402656504 = ref object of OpenApiRestCall_402656044
proc url_CopyWorkspaceImage_402656506(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyWorkspaceImage_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CopyWorkspaceImage_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CopyWorkspaceImage_402656504; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   
                                                                                ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_402656504(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_402656505, base: "/",
    makeUrl: url_CopyWorkspaceImage_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateIpGroup_402656521(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIpGroup_402656520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_CreateIpGroup_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateIpGroup_402656519; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createIpGroup* = Call_CreateIpGroup_402656519(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_402656520, base: "/",
    makeUrl: url_CreateIpGroup_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateTags_402656536(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTags_402656535(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_CreateTags_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateTags_402656534; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createTags* = Call_CreateTags_402656534(name: "createTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateTags",
    validator: validate_CreateTags_402656535, base: "/",
    makeUrl: url_CreateTags_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateWorkspaces_402656551(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkspaces_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_CreateWorkspaces_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateWorkspaces_402656549; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   
                                                                                                                                ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createWorkspaces* = Call_CreateWorkspaces_402656549(
    name: "createWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_402656550, base: "/",
    makeUrl: url_CreateWorkspaces_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_402656564 = ref object of OpenApiRestCall_402656044
proc url_DeleteIpGroup_402656566(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIpGroup_402656565(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_DeleteIpGroup_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DeleteIpGroup_402656564; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   
                                                                                                                                                   ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var deleteIpGroup* = Call_DeleteIpGroup_402656564(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_402656565, base: "/",
    makeUrl: url_DeleteIpGroup_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_402656579 = ref object of OpenApiRestCall_402656044
proc url_DeleteTags_402656581(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_402656580(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_DeleteTags_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DeleteTags_402656579; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject 
                                                                       ## (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var deleteTags* = Call_DeleteTags_402656579(name: "deleteTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
    validator: validate_DeleteTags_402656580, base: "/",
    makeUrl: url_DeleteTags_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_402656594 = ref object of OpenApiRestCall_402656044
proc url_DeleteWorkspaceImage_402656596(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkspaceImage_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_DeleteWorkspaceImage_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DeleteWorkspaceImage_402656594; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_402656594(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_402656595, base: "/",
    makeUrl: url_DeleteWorkspaceImage_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWorkspaceDirectory_402656609 = ref object of OpenApiRestCall_402656044
proc url_DeregisterWorkspaceDirectory_402656611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterWorkspaceDirectory_402656610(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "WorkspacesService.DeregisterWorkspaceDirectory"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_DeregisterWorkspaceDirectory_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DeregisterWorkspaceDirectory_402656609;
           body: JsonNode): Recallable =
  ## deregisterWorkspaceDirectory
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ##   
                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var deregisterWorkspaceDirectory* = Call_DeregisterWorkspaceDirectory_402656609(
    name: "deregisterWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeregisterWorkspaceDirectory",
    validator: validate_DeregisterWorkspaceDirectory_402656610, base: "/",
    makeUrl: url_DeregisterWorkspaceDirectory_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_402656624 = ref object of OpenApiRestCall_402656044
proc url_DescribeAccount_402656626(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccount_402656625(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_DescribeAccount_402656624; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DescribeAccount_402656624; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   
                                                                                                                  ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var describeAccount* = Call_DescribeAccount_402656624(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_402656625, base: "/",
    makeUrl: url_DescribeAccount_402656626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_402656639 = ref object of OpenApiRestCall_402656044
proc url_DescribeAccountModifications_402656641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccountModifications_402656640(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DescribeAccountModifications_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DescribeAccountModifications_402656639;
           body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   
                                                                                                                                   ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var describeAccountModifications* = Call_DescribeAccountModifications_402656639(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_402656640, base: "/",
    makeUrl: url_DescribeAccountModifications_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_402656654 = ref object of OpenApiRestCall_402656044
proc url_DescribeClientProperties_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeClientProperties_402656655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_DescribeClientProperties_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DescribeClientProperties_402656654;
           body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   
                                                                                     ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var describeClientProperties* = Call_DescribeClientProperties_402656654(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_402656655, base: "/",
    makeUrl: url_DescribeClientProperties_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_402656669 = ref object of OpenApiRestCall_402656044
proc url_DescribeIpGroups_402656671(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeIpGroups_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_DescribeIpGroups_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more of your IP access control groups.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DescribeIpGroups_402656669; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var describeIpGroups* = Call_DescribeIpGroups_402656669(
    name: "describeIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_402656670, base: "/",
    makeUrl: url_DescribeIpGroups_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_402656684 = ref object of OpenApiRestCall_402656044
proc url_DescribeTags_402656686(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_402656685(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_DescribeTags_402656684; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DescribeTags_402656684; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var describeTags* = Call_DescribeTags_402656684(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_402656685, base: "/",
    makeUrl: url_DescribeTags_402656686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_402656699 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspaceBundles_402656701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspaceBundles_402656700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656702 = query.getOrDefault("NextToken")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "NextToken", valid_402656702
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656703 = header.getOrDefault("X-Amz-Target")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_402656703 != nil:
    section.add "X-Amz-Target", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Security-Token", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Signature")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Signature", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Algorithm", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Date")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Date", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Credential")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Credential", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656712: Call_DescribeWorkspaceBundles_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
                                                                                         ## 
  let valid = call_402656712.validator(path, query, header, formData, body, _)
  let scheme = call_402656712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656712.makeUrl(scheme.get, call_402656712.host, call_402656712.base,
                                   call_402656712.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656712, uri, valid, _)

proc call*(call_402656713: Call_DescribeWorkspaceBundles_402656699;
           body: JsonNode; NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   
                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                        ## NextToken: string
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                        ## token
  var query_402656714 = newJObject()
  var body_402656715 = newJObject()
  if body != nil:
    body_402656715 = body
  add(query_402656714, "NextToken", newJString(NextToken))
  result = call_402656713.call(nil, query_402656714, nil, nil, body_402656715)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_402656699(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_402656700, base: "/",
    makeUrl: url_DescribeWorkspaceBundles_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_402656716 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspaceDirectories_402656718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspaceDirectories_402656717(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656719 = query.getOrDefault("NextToken")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "NextToken", valid_402656719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656720 = header.getOrDefault("X-Amz-Target")
  valid_402656720 = validateParameter(valid_402656720, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_402656720 != nil:
    section.add "X-Amz-Target", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Security-Token", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Signature")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Signature", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Algorithm", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Date")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Date", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Credential")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Credential", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656729: Call_DescribeWorkspaceDirectories_402656716;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the available directories that are registered with Amazon WorkSpaces.
                                                                                         ## 
  let valid = call_402656729.validator(path, query, header, formData, body, _)
  let scheme = call_402656729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656729.makeUrl(scheme.get, call_402656729.host, call_402656729.base,
                                   call_402656729.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656729, uri, valid, _)

proc call*(call_402656730: Call_DescribeWorkspaceDirectories_402656716;
           body: JsonNode; NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ##   
                                                                                    ## body: JObject (required)
  ##   
                                                                                                               ## NextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## token
  var query_402656731 = newJObject()
  var body_402656732 = newJObject()
  if body != nil:
    body_402656732 = body
  add(query_402656731, "NextToken", newJString(NextToken))
  result = call_402656730.call(nil, query_402656731, nil, nil, body_402656732)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_402656716(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_402656717, base: "/",
    makeUrl: url_DescribeWorkspaceDirectories_402656718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_402656733 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspaceImages_402656735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspaceImages_402656734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656736 = header.getOrDefault("X-Amz-Target")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_402656736 != nil:
    section.add "X-Amz-Target", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Security-Token", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Signature")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Signature", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Algorithm", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Date")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Date", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Credential")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Credential", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656745: Call_DescribeWorkspaceImages_402656733;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
                                                                                         ## 
  let valid = call_402656745.validator(path, query, header, formData, body, _)
  let scheme = call_402656745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656745.makeUrl(scheme.get, call_402656745.host, call_402656745.base,
                                   call_402656745.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656745, uri, valid, _)

proc call*(call_402656746: Call_DescribeWorkspaceImages_402656733;
           body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   
                                                                                                                                                              ## body: JObject (required)
  var body_402656747 = newJObject()
  if body != nil:
    body_402656747 = body
  result = call_402656746.call(nil, nil, nil, nil, body_402656747)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_402656733(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_402656734, base: "/",
    makeUrl: url_DescribeWorkspaceImages_402656735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_402656748 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspaceSnapshots_402656750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspaceSnapshots_402656749(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656751 = header.getOrDefault("X-Amz-Target")
  valid_402656751 = validateParameter(valid_402656751, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_402656751 != nil:
    section.add "X-Amz-Target", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Security-Token", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Signature")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Signature", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Algorithm", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Date")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Date", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Credential")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Credential", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656760: Call_DescribeWorkspaceSnapshots_402656748;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
                                                                                         ## 
  let valid = call_402656760.validator(path, query, header, formData, body, _)
  let scheme = call_402656760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656760.makeUrl(scheme.get, call_402656760.host, call_402656760.base,
                                   call_402656760.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656760, uri, valid, _)

proc call*(call_402656761: Call_DescribeWorkspaceSnapshots_402656748;
           body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_402656762 = newJObject()
  if body != nil:
    body_402656762 = body
  result = call_402656761.call(nil, nil, nil, nil, body_402656762)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_402656748(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_402656749, base: "/",
    makeUrl: url_DescribeWorkspaceSnapshots_402656750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_402656763 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspaces_402656765(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspaces_402656764(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656766 = query.getOrDefault("NextToken")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "NextToken", valid_402656766
  var valid_402656767 = query.getOrDefault("Limit")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "Limit", valid_402656767
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656768 = header.getOrDefault("X-Amz-Target")
  valid_402656768 = validateParameter(valid_402656768, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_402656768 != nil:
    section.add "X-Amz-Target", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656777: Call_DescribeWorkspaces_402656763;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
                                                                                         ## 
  let valid = call_402656777.validator(path, query, header, formData, body, _)
  let scheme = call_402656777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656777.makeUrl(scheme.get, call_402656777.host, call_402656777.base,
                                   call_402656777.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656777, uri, valid, _)

proc call*(call_402656778: Call_DescribeWorkspaces_402656763; body: JsonNode;
           NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   
                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                           ## token
  ##   
                                                                                                                                                                                                                                   ## Limit: string
                                                                                                                                                                                                                                   ##        
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                   ## limit
  var query_402656779 = newJObject()
  var body_402656780 = newJObject()
  if body != nil:
    body_402656780 = body
  add(query_402656779, "NextToken", newJString(NextToken))
  add(query_402656779, "Limit", newJString(Limit))
  result = call_402656778.call(nil, query_402656779, nil, nil, body_402656780)

var describeWorkspaces* = Call_DescribeWorkspaces_402656763(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_402656764, base: "/",
    makeUrl: url_DescribeWorkspaces_402656765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_402656781 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkspacesConnectionStatus_402656783(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkspacesConnectionStatus_402656782(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656784 = header.getOrDefault("X-Amz-Target")
  valid_402656784 = validateParameter(valid_402656784, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_402656784 != nil:
    section.add "X-Amz-Target", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Security-Token", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Signature")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Signature", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Algorithm", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Date")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Date", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Credential")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Credential", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656793: Call_DescribeWorkspacesConnectionStatus_402656781;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
                                                                                         ## 
  let valid = call_402656793.validator(path, query, header, formData, body, _)
  let scheme = call_402656793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656793.makeUrl(scheme.get, call_402656793.host, call_402656793.base,
                                   call_402656793.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656793, uri, valid, _)

proc call*(call_402656794: Call_DescribeWorkspacesConnectionStatus_402656781;
           body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_402656795 = newJObject()
  if body != nil:
    body_402656795 = body
  result = call_402656794.call(nil, nil, nil, nil, body_402656795)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_402656781(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_402656782, base: "/",
    makeUrl: url_DescribeWorkspacesConnectionStatus_402656783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_402656796 = ref object of OpenApiRestCall_402656044
proc url_DisassociateIpGroups_402656798(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateIpGroups_402656797(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656799 = header.getOrDefault("X-Amz-Target")
  valid_402656799 = validateParameter(valid_402656799, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_402656799 != nil:
    section.add "X-Amz-Target", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Security-Token", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Signature")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Signature", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Algorithm", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Date")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Date", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Credential")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Credential", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656808: Call_DisassociateIpGroups_402656796;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
                                                                                         ## 
  let valid = call_402656808.validator(path, query, header, formData, body, _)
  let scheme = call_402656808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656808.makeUrl(scheme.get, call_402656808.host, call_402656808.base,
                                   call_402656808.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656808, uri, valid, _)

proc call*(call_402656809: Call_DisassociateIpGroups_402656796; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   
                                                                                      ## body: JObject (required)
  var body_402656810 = newJObject()
  if body != nil:
    body_402656810 = body
  result = call_402656809.call(nil, nil, nil, nil, body_402656810)

var disassociateIpGroups* = Call_DisassociateIpGroups_402656796(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_402656797, base: "/",
    makeUrl: url_DisassociateIpGroups_402656798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_402656811 = ref object of OpenApiRestCall_402656044
proc url_ImportWorkspaceImage_402656813(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportWorkspaceImage_402656812(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656814 = header.getOrDefault("X-Amz-Target")
  valid_402656814 = validateParameter(valid_402656814, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_402656814 != nil:
    section.add "X-Amz-Target", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Security-Token", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Signature")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Signature", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Algorithm", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Date")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Date", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Credential")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Credential", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656823: Call_ImportWorkspaceImage_402656811;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
                                                                                         ## 
  let valid = call_402656823.validator(path, query, header, formData, body, _)
  let scheme = call_402656823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656823.makeUrl(scheme.get, call_402656823.host, call_402656823.base,
                                   call_402656823.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656823, uri, valid, _)

proc call*(call_402656824: Call_ImportWorkspaceImage_402656811; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   
                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656825 = newJObject()
  if body != nil:
    body_402656825 = body
  result = call_402656824.call(nil, nil, nil, nil, body_402656825)

var importWorkspaceImage* = Call_ImportWorkspaceImage_402656811(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_402656812, base: "/",
    makeUrl: url_ImportWorkspaceImage_402656813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_402656826 = ref object of OpenApiRestCall_402656044
proc url_ListAvailableManagementCidrRanges_402656828(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAvailableManagementCidrRanges_402656827(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656829 = header.getOrDefault("X-Amz-Target")
  valid_402656829 = validateParameter(valid_402656829, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_402656829 != nil:
    section.add "X-Amz-Target", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Security-Token", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Signature")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Signature", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Algorithm", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Date")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Date", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Credential")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Credential", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656838: Call_ListAvailableManagementCidrRanges_402656826;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
                                                                                         ## 
  let valid = call_402656838.validator(path, query, header, formData, body, _)
  let scheme = call_402656838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656838.makeUrl(scheme.get, call_402656838.host, call_402656838.base,
                                   call_402656838.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656838, uri, valid, _)

proc call*(call_402656839: Call_ListAvailableManagementCidrRanges_402656826;
           body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656840 = newJObject()
  if body != nil:
    body_402656840 = body
  result = call_402656839.call(nil, nil, nil, nil, body_402656840)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_402656826(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_402656827, base: "/",
    makeUrl: url_ListAvailableManagementCidrRanges_402656828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MigrateWorkspace_402656841 = ref object of OpenApiRestCall_402656044
proc url_MigrateWorkspace_402656843(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MigrateWorkspace_402656842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656844 = header.getOrDefault("X-Amz-Target")
  valid_402656844 = validateParameter(valid_402656844, JString, required = true, default = newJString(
      "WorkspacesService.MigrateWorkspace"))
  if valid_402656844 != nil:
    section.add "X-Amz-Target", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Security-Token", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Signature")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Signature", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Algorithm", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Date")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Date", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Credential")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Credential", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656853: Call_MigrateWorkspace_402656841;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
                                                                                         ## 
  let valid = call_402656853.validator(path, query, header, formData, body, _)
  let scheme = call_402656853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656853.makeUrl(scheme.get, call_402656853.host, call_402656853.base,
                                   call_402656853.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656853, uri, valid, _)

proc call*(call_402656854: Call_MigrateWorkspace_402656841; body: JsonNode): Recallable =
  ## migrateWorkspace
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656855 = newJObject()
  if body != nil:
    body_402656855 = body
  result = call_402656854.call(nil, nil, nil, nil, body_402656855)

var migrateWorkspace* = Call_MigrateWorkspace_402656841(
    name: "migrateWorkspace", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.MigrateWorkspace",
    validator: validate_MigrateWorkspace_402656842, base: "/",
    makeUrl: url_MigrateWorkspace_402656843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_402656856 = ref object of OpenApiRestCall_402656044
proc url_ModifyAccount_402656858(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyAccount_402656857(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656859 = header.getOrDefault("X-Amz-Target")
  valid_402656859 = validateParameter(valid_402656859, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_402656859 != nil:
    section.add "X-Amz-Target", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Security-Token", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Signature")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Signature", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Algorithm", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Date")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Date", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Credential")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Credential", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656868: Call_ModifyAccount_402656856; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
                                                                                         ## 
  let valid = call_402656868.validator(path, query, header, formData, body, _)
  let scheme = call_402656868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656868.makeUrl(scheme.get, call_402656868.host, call_402656868.base,
                                   call_402656868.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656868, uri, valid, _)

proc call*(call_402656869: Call_ModifyAccount_402656856; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   
                                                                                           ## body: JObject (required)
  var body_402656870 = newJObject()
  if body != nil:
    body_402656870 = body
  result = call_402656869.call(nil, nil, nil, nil, body_402656870)

var modifyAccount* = Call_ModifyAccount_402656856(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_402656857, base: "/",
    makeUrl: url_ModifyAccount_402656858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_402656871 = ref object of OpenApiRestCall_402656044
proc url_ModifyClientProperties_402656873(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyClientProperties_402656872(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656874 = header.getOrDefault("X-Amz-Target")
  valid_402656874 = validateParameter(valid_402656874, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_402656874 != nil:
    section.add "X-Amz-Target", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Security-Token", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Signature")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Signature", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Algorithm", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Date")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Date", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Credential")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Credential", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656883: Call_ModifyClientProperties_402656871;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
                                                                                         ## 
  let valid = call_402656883.validator(path, query, header, formData, body, _)
  let scheme = call_402656883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656883.makeUrl(scheme.get, call_402656883.host, call_402656883.base,
                                   call_402656883.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656883, uri, valid, _)

proc call*(call_402656884: Call_ModifyClientProperties_402656871; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656885 = newJObject()
  if body != nil:
    body_402656885 = body
  result = call_402656884.call(nil, nil, nil, nil, body_402656885)

var modifyClientProperties* = Call_ModifyClientProperties_402656871(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_402656872, base: "/",
    makeUrl: url_ModifyClientProperties_402656873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifySelfservicePermissions_402656886 = ref object of OpenApiRestCall_402656044
proc url_ModifySelfservicePermissions_402656888(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifySelfservicePermissions_402656887(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656889 = header.getOrDefault("X-Amz-Target")
  valid_402656889 = validateParameter(valid_402656889, JString, required = true, default = newJString(
      "WorkspacesService.ModifySelfservicePermissions"))
  if valid_402656889 != nil:
    section.add "X-Amz-Target", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Security-Token", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Signature")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Signature", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Algorithm", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Date")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Date", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Credential")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Credential", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656898: Call_ModifySelfservicePermissions_402656886;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
                                                                                         ## 
  let valid = call_402656898.validator(path, query, header, formData, body, _)
  let scheme = call_402656898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656898.makeUrl(scheme.get, call_402656898.host, call_402656898.base,
                                   call_402656898.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656898, uri, valid, _)

proc call*(call_402656899: Call_ModifySelfservicePermissions_402656886;
           body: JsonNode): Recallable =
  ## modifySelfservicePermissions
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ##   
                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656900 = newJObject()
  if body != nil:
    body_402656900 = body
  result = call_402656899.call(nil, nil, nil, nil, body_402656900)

var modifySelfservicePermissions* = Call_ModifySelfservicePermissions_402656886(
    name: "modifySelfservicePermissions", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifySelfservicePermissions",
    validator: validate_ModifySelfservicePermissions_402656887, base: "/",
    makeUrl: url_ModifySelfservicePermissions_402656888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceAccessProperties_402656901 = ref object of OpenApiRestCall_402656044
proc url_ModifyWorkspaceAccessProperties_402656903(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyWorkspaceAccessProperties_402656902(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656904 = header.getOrDefault("X-Amz-Target")
  valid_402656904 = validateParameter(valid_402656904, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceAccessProperties"))
  if valid_402656904 != nil:
    section.add "X-Amz-Target", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Security-Token", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Signature")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Signature", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Algorithm", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Date")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Date", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Credential")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Credential", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656913: Call_ModifyWorkspaceAccessProperties_402656901;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
                                                                                         ## 
  let valid = call_402656913.validator(path, query, header, formData, body, _)
  let scheme = call_402656913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656913.makeUrl(scheme.get, call_402656913.host, call_402656913.base,
                                   call_402656913.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656913, uri, valid, _)

proc call*(call_402656914: Call_ModifyWorkspaceAccessProperties_402656901;
           body: JsonNode): Recallable =
  ## modifyWorkspaceAccessProperties
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ##   
                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656915 = newJObject()
  if body != nil:
    body_402656915 = body
  result = call_402656914.call(nil, nil, nil, nil, body_402656915)

var modifyWorkspaceAccessProperties* = Call_ModifyWorkspaceAccessProperties_402656901(
    name: "modifyWorkspaceAccessProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceAccessProperties",
    validator: validate_ModifyWorkspaceAccessProperties_402656902, base: "/",
    makeUrl: url_ModifyWorkspaceAccessProperties_402656903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceCreationProperties_402656916 = ref object of OpenApiRestCall_402656044
proc url_ModifyWorkspaceCreationProperties_402656918(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyWorkspaceCreationProperties_402656917(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656919 = header.getOrDefault("X-Amz-Target")
  valid_402656919 = validateParameter(valid_402656919, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceCreationProperties"))
  if valid_402656919 != nil:
    section.add "X-Amz-Target", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Security-Token", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Signature")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Signature", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Algorithm", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Date")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Date", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Credential")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Credential", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656928: Call_ModifyWorkspaceCreationProperties_402656916;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modify the default properties used to create WorkSpaces.
                                                                                         ## 
  let valid = call_402656928.validator(path, query, header, formData, body, _)
  let scheme = call_402656928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656928.makeUrl(scheme.get, call_402656928.host, call_402656928.base,
                                   call_402656928.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656928, uri, valid, _)

proc call*(call_402656929: Call_ModifyWorkspaceCreationProperties_402656916;
           body: JsonNode): Recallable =
  ## modifyWorkspaceCreationProperties
  ## Modify the default properties used to create WorkSpaces.
  ##   body: JObject (required)
  var body_402656930 = newJObject()
  if body != nil:
    body_402656930 = body
  result = call_402656929.call(nil, nil, nil, nil, body_402656930)

var modifyWorkspaceCreationProperties* = Call_ModifyWorkspaceCreationProperties_402656916(
    name: "modifyWorkspaceCreationProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceCreationProperties",
    validator: validate_ModifyWorkspaceCreationProperties_402656917, base: "/",
    makeUrl: url_ModifyWorkspaceCreationProperties_402656918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_402656931 = ref object of OpenApiRestCall_402656044
proc url_ModifyWorkspaceProperties_402656933(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyWorkspaceProperties_402656932(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656934 = header.getOrDefault("X-Amz-Target")
  valid_402656934 = validateParameter(valid_402656934, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_402656934 != nil:
    section.add "X-Amz-Target", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Security-Token", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Signature")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Signature", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Algorithm", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Date")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Date", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Credential")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Credential", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656943: Call_ModifyWorkspaceProperties_402656931;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the specified WorkSpace properties.
                                                                                         ## 
  let valid = call_402656943.validator(path, query, header, formData, body, _)
  let scheme = call_402656943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656943.makeUrl(scheme.get, call_402656943.host, call_402656943.base,
                                   call_402656943.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656943, uri, valid, _)

proc call*(call_402656944: Call_ModifyWorkspaceProperties_402656931;
           body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_402656945 = newJObject()
  if body != nil:
    body_402656945 = body
  result = call_402656944.call(nil, nil, nil, nil, body_402656945)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_402656931(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_402656932, base: "/",
    makeUrl: url_ModifyWorkspaceProperties_402656933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_402656946 = ref object of OpenApiRestCall_402656044
proc url_ModifyWorkspaceState_402656948(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyWorkspaceState_402656947(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656949 = header.getOrDefault("X-Amz-Target")
  valid_402656949 = validateParameter(valid_402656949, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_402656949 != nil:
    section.add "X-Amz-Target", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Security-Token", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Signature")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Signature", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Algorithm", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Date")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Date", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Credential")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Credential", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656958: Call_ModifyWorkspaceState_402656946;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
                                                                                         ## 
  let valid = call_402656958.validator(path, query, header, formData, body, _)
  let scheme = call_402656958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656958.makeUrl(scheme.get, call_402656958.host, call_402656958.base,
                                   call_402656958.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656958, uri, valid, _)

proc call*(call_402656959: Call_ModifyWorkspaceState_402656946; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656960 = newJObject()
  if body != nil:
    body_402656960 = body
  result = call_402656959.call(nil, nil, nil, nil, body_402656960)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_402656946(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_402656947, base: "/",
    makeUrl: url_ModifyWorkspaceState_402656948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_402656961 = ref object of OpenApiRestCall_402656044
proc url_RebootWorkspaces_402656963(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootWorkspaces_402656962(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656964 = header.getOrDefault("X-Amz-Target")
  valid_402656964 = validateParameter(valid_402656964, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_402656964 != nil:
    section.add "X-Amz-Target", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Security-Token", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Signature")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Signature", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Algorithm", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Date")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Date", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Credential")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Credential", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656973: Call_RebootWorkspaces_402656961;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
                                                                                         ## 
  let valid = call_402656973.validator(path, query, header, formData, body, _)
  let scheme = call_402656973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656973.makeUrl(scheme.get, call_402656973.host, call_402656973.base,
                                   call_402656973.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656973, uri, valid, _)

proc call*(call_402656974: Call_RebootWorkspaces_402656961; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   
                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656975 = newJObject()
  if body != nil:
    body_402656975 = body
  result = call_402656974.call(nil, nil, nil, nil, body_402656975)

var rebootWorkspaces* = Call_RebootWorkspaces_402656961(
    name: "rebootWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_402656962, base: "/",
    makeUrl: url_RebootWorkspaces_402656963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_402656976 = ref object of OpenApiRestCall_402656044
proc url_RebuildWorkspaces_402656978(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebuildWorkspaces_402656977(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656979 = header.getOrDefault("X-Amz-Target")
  valid_402656979 = validateParameter(valid_402656979, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_402656979 != nil:
    section.add "X-Amz-Target", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Security-Token", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Signature")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Signature", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Algorithm", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Date")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Date", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Credential")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Credential", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656988: Call_RebuildWorkspaces_402656976;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
                                                                                         ## 
  let valid = call_402656988.validator(path, query, header, formData, body, _)
  let scheme = call_402656988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656988.makeUrl(scheme.get, call_402656988.host, call_402656988.base,
                                   call_402656988.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656988, uri, valid, _)

proc call*(call_402656989: Call_RebuildWorkspaces_402656976; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656990 = newJObject()
  if body != nil:
    body_402656990 = body
  result = call_402656989.call(nil, nil, nil, nil, body_402656990)

var rebuildWorkspaces* = Call_RebuildWorkspaces_402656976(
    name: "rebuildWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_402656977, base: "/",
    makeUrl: url_RebuildWorkspaces_402656978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWorkspaceDirectory_402656991 = ref object of OpenApiRestCall_402656044
proc url_RegisterWorkspaceDirectory_402656993(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterWorkspaceDirectory_402656992(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656994 = header.getOrDefault("X-Amz-Target")
  valid_402656994 = validateParameter(valid_402656994, JString, required = true, default = newJString(
      "WorkspacesService.RegisterWorkspaceDirectory"))
  if valid_402656994 != nil:
    section.add "X-Amz-Target", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Security-Token", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Signature")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Signature", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Algorithm", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Date")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Date", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Credential")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Credential", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657003: Call_RegisterWorkspaceDirectory_402656991;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
                                                                                         ## 
  let valid = call_402657003.validator(path, query, header, formData, body, _)
  let scheme = call_402657003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657003.makeUrl(scheme.get, call_402657003.host, call_402657003.base,
                                   call_402657003.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657003, uri, valid, _)

proc call*(call_402657004: Call_RegisterWorkspaceDirectory_402656991;
           body: JsonNode): Recallable =
  ## registerWorkspaceDirectory
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657005 = newJObject()
  if body != nil:
    body_402657005 = body
  result = call_402657004.call(nil, nil, nil, nil, body_402657005)

var registerWorkspaceDirectory* = Call_RegisterWorkspaceDirectory_402656991(
    name: "registerWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RegisterWorkspaceDirectory",
    validator: validate_RegisterWorkspaceDirectory_402656992, base: "/",
    makeUrl: url_RegisterWorkspaceDirectory_402656993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_402657006 = ref object of OpenApiRestCall_402656044
proc url_RestoreWorkspace_402657008(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreWorkspace_402657007(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657009 = header.getOrDefault("X-Amz-Target")
  valid_402657009 = validateParameter(valid_402657009, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_402657009 != nil:
    section.add "X-Amz-Target", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Security-Token", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Signature")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Signature", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Algorithm", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Date")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Date", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Credential")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Credential", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657018: Call_RestoreWorkspace_402657006;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
                                                                                         ## 
  let valid = call_402657018.validator(path, query, header, formData, body, _)
  let scheme = call_402657018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657018.makeUrl(scheme.get, call_402657018.host, call_402657018.base,
                                   call_402657018.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657018, uri, valid, _)

proc call*(call_402657019: Call_RestoreWorkspace_402657006; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, <code>UNHEALTHY</code>, or <code>STOPPED</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657020 = newJObject()
  if body != nil:
    body_402657020 = body
  result = call_402657019.call(nil, nil, nil, nil, body_402657020)

var restoreWorkspace* = Call_RestoreWorkspace_402657006(
    name: "restoreWorkspace", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_402657007, base: "/",
    makeUrl: url_RestoreWorkspace_402657008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_402657021 = ref object of OpenApiRestCall_402656044
proc url_RevokeIpRules_402657023(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeIpRules_402657022(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657024 = header.getOrDefault("X-Amz-Target")
  valid_402657024 = validateParameter(valid_402657024, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_402657024 != nil:
    section.add "X-Amz-Target", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Security-Token", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Signature")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Signature", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Algorithm", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Date")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Date", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Credential")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Credential", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657033: Call_RevokeIpRules_402657021; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more rules from the specified IP access control group.
                                                                                         ## 
  let valid = call_402657033.validator(path, query, header, formData, body, _)
  let scheme = call_402657033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657033.makeUrl(scheme.get, call_402657033.host, call_402657033.base,
                                   call_402657033.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657033, uri, valid, _)

proc call*(call_402657034: Call_RevokeIpRules_402657021; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: 
                                                                          ## JObject (required)
  var body_402657035 = newJObject()
  if body != nil:
    body_402657035 = body
  result = call_402657034.call(nil, nil, nil, nil, body_402657035)

var revokeIpRules* = Call_RevokeIpRules_402657021(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_402657022, base: "/",
    makeUrl: url_RevokeIpRules_402657023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_402657036 = ref object of OpenApiRestCall_402656044
proc url_StartWorkspaces_402657038(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartWorkspaces_402657037(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657039 = header.getOrDefault("X-Amz-Target")
  valid_402657039 = validateParameter(valid_402657039, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_402657039 != nil:
    section.add "X-Amz-Target", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Security-Token", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Signature")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Signature", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Algorithm", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Date")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Date", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Credential")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Credential", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657048: Call_StartWorkspaces_402657036; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
                                                                                         ## 
  let valid = call_402657048.validator(path, query, header, formData, body, _)
  let scheme = call_402657048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657048.makeUrl(scheme.get, call_402657048.host, call_402657048.base,
                                   call_402657048.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657048, uri, valid, _)

proc call*(call_402657049: Call_StartWorkspaces_402657036; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   
                                                                                                                                                                           ## body: JObject (required)
  var body_402657050 = newJObject()
  if body != nil:
    body_402657050 = body
  result = call_402657049.call(nil, nil, nil, nil, body_402657050)

var startWorkspaces* = Call_StartWorkspaces_402657036(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_402657037, base: "/",
    makeUrl: url_StartWorkspaces_402657038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_402657051 = ref object of OpenApiRestCall_402656044
proc url_StopWorkspaces_402657053(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopWorkspaces_402657052(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657054 = header.getOrDefault("X-Amz-Target")
  valid_402657054 = validateParameter(valid_402657054, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_402657054 != nil:
    section.add "X-Amz-Target", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Security-Token", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Signature")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Signature", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Algorithm", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Date")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Date", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Credential")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Credential", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657063: Call_StopWorkspaces_402657051; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
                                                                                         ## 
  let valid = call_402657063.validator(path, query, header, formData, body, _)
  let scheme = call_402657063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657063.makeUrl(scheme.get, call_402657063.host, call_402657063.base,
                                   call_402657063.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657063, uri, valid, _)

proc call*(call_402657064: Call_StopWorkspaces_402657051; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   
                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402657065 = newJObject()
  if body != nil:
    body_402657065 = body
  result = call_402657064.call(nil, nil, nil, nil, body_402657065)

var stopWorkspaces* = Call_StopWorkspaces_402657051(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_402657052, base: "/",
    makeUrl: url_StopWorkspaces_402657053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_402657066 = ref object of OpenApiRestCall_402656044
proc url_TerminateWorkspaces_402657068(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateWorkspaces_402657067(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657069 = header.getOrDefault("X-Amz-Target")
  valid_402657069 = validateParameter(valid_402657069, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_402657069 != nil:
    section.add "X-Amz-Target", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Security-Token", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Signature")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Signature", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Algorithm", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Date")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Date", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Credential")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Credential", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657078: Call_TerminateWorkspaces_402657066;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
                                                                                         ## 
  let valid = call_402657078.validator(path, query, header, formData, body, _)
  let scheme = call_402657078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657078.makeUrl(scheme.get, call_402657078.host, call_402657078.base,
                                   call_402657078.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657078, uri, valid, _)

proc call*(call_402657079: Call_TerminateWorkspaces_402657066; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657080 = newJObject()
  if body != nil:
    body_402657080 = body
  result = call_402657079.call(nil, nil, nil, nil, body_402657080)

var terminateWorkspaces* = Call_TerminateWorkspaces_402657066(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_402657067, base: "/",
    makeUrl: url_TerminateWorkspaces_402657068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_402657081 = ref object of OpenApiRestCall_402656044
proc url_UpdateRulesOfIpGroup_402657083(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRulesOfIpGroup_402657082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657084 = header.getOrDefault("X-Amz-Target")
  valid_402657084 = validateParameter(valid_402657084, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_402657084 != nil:
    section.add "X-Amz-Target", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Security-Token", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Signature")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Signature", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Algorithm", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Date")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Date", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Credential")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Credential", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657093: Call_UpdateRulesOfIpGroup_402657081;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
                                                                                         ## 
  let valid = call_402657093.validator(path, query, header, formData, body, _)
  let scheme = call_402657093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657093.makeUrl(scheme.get, call_402657093.host, call_402657093.base,
                                   call_402657093.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657093, uri, valid, _)

proc call*(call_402657094: Call_UpdateRulesOfIpGroup_402657081; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   
                                                                                                  ## body: JObject (required)
  var body_402657095 = newJObject()
  if body != nil:
    body_402657095 = body
  result = call_402657094.call(nil, nil, nil, nil, body_402657095)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_402657081(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_402657082, base: "/",
    makeUrl: url_UpdateRulesOfIpGroup_402657083,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}