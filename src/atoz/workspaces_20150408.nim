
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
  Call_AssociateIpGroups_600774 = ref object of OpenApiRestCall_600437
proc url_AssociateIpGroups_600776(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateIpGroups_600775(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600903 = header.getOrDefault("X-Amz-Target")
  valid_600903 = validateParameter(valid_600903, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_600903 != nil:
    section.add "X-Amz-Target", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_AssociateIpGroups_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600932, url, valid)

proc call*(call_601003: Call_AssociateIpGroups_600774; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_601004 = newJObject()
  if body != nil:
    body_601004 = body
  result = call_601003.call(nil, nil, nil, nil, body_601004)

var associateIpGroups* = Call_AssociateIpGroups_600774(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_600775, base: "/",
    url: url_AssociateIpGroups_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_601043 = ref object of OpenApiRestCall_600437
proc url_AuthorizeIpRules_601045(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AuthorizeIpRules_601044(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601048 = header.getOrDefault("X-Amz-Target")
  valid_601048 = validateParameter(valid_601048, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_601048 != nil:
    section.add "X-Amz-Target", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_AuthorizeIpRules_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_AuthorizeIpRules_601043; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_601057 = newJObject()
  if body != nil:
    body_601057 = body
  result = call_601056.call(nil, nil, nil, nil, body_601057)

var authorizeIpRules* = Call_AuthorizeIpRules_601043(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_601044, base: "/",
    url: url_AuthorizeIpRules_601045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_601058 = ref object of OpenApiRestCall_600437
proc url_CopyWorkspaceImage_601060(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyWorkspaceImage_601059(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601063 = header.getOrDefault("X-Amz-Target")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_601063 != nil:
    section.add "X-Amz-Target", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Content-Sha256", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Algorithm")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Algorithm", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Signature")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Signature", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-SignedHeaders", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Credential")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Credential", valid_601068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601070: Call_CopyWorkspaceImage_601058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_601070.validator(path, query, header, formData, body)
  let scheme = call_601070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601070.url(scheme.get, call_601070.host, call_601070.base,
                         call_601070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601070, url, valid)

proc call*(call_601071: Call_CopyWorkspaceImage_601058; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  result = call_601071.call(nil, nil, nil, nil, body_601072)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_601058(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_601059, base: "/",
    url: url_CopyWorkspaceImage_601060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_601073 = ref object of OpenApiRestCall_600437
proc url_CreateIpGroup_601075(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIpGroup_601074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601078 = header.getOrDefault("X-Amz-Target")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_601078 != nil:
    section.add "X-Amz-Target", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_CreateIpGroup_601073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601085, url, valid)

proc call*(call_601086: Call_CreateIpGroup_601073; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_601087 = newJObject()
  if body != nil:
    body_601087 = body
  result = call_601086.call(nil, nil, nil, nil, body_601087)

var createIpGroup* = Call_CreateIpGroup_601073(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_601074, base: "/", url: url_CreateIpGroup_601075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_601088 = ref object of OpenApiRestCall_600437
proc url_CreateTags_601090(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTags_601089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601093 = header.getOrDefault("X-Amz-Target")
  valid_601093 = validateParameter(valid_601093, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_601093 != nil:
    section.add "X-Amz-Target", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_CreateTags_601088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_CreateTags_601088; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_601102 = newJObject()
  if body != nil:
    body_601102 = body
  result = call_601101.call(nil, nil, nil, nil, body_601102)

var createTags* = Call_CreateTags_601088(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_601089,
                                      base: "/", url: url_CreateTags_601090,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_601103 = ref object of OpenApiRestCall_600437
proc url_CreateWorkspaces_601105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkspaces_601104(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601108 = header.getOrDefault("X-Amz-Target")
  valid_601108 = validateParameter(valid_601108, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_601108 != nil:
    section.add "X-Amz-Target", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_CreateWorkspaces_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_CreateWorkspaces_601103; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_601117 = newJObject()
  if body != nil:
    body_601117 = body
  result = call_601116.call(nil, nil, nil, nil, body_601117)

var createWorkspaces* = Call_CreateWorkspaces_601103(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_601104, base: "/",
    url: url_CreateWorkspaces_601105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_601118 = ref object of OpenApiRestCall_600437
proc url_DeleteIpGroup_601120(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteIpGroup_601119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DeleteIpGroup_601118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DeleteIpGroup_601118; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var deleteIpGroup* = Call_DeleteIpGroup_601118(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_601119, base: "/", url: url_DeleteIpGroup_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_601133 = ref object of OpenApiRestCall_600437
proc url_DeleteTags_601135(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_601134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_DeleteTags_601133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_DeleteTags_601133; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var deleteTags* = Call_DeleteTags_601133(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_601134,
                                      base: "/", url: url_DeleteTags_601135,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_601148 = ref object of OpenApiRestCall_600437
proc url_DeleteWorkspaceImage_601150(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkspaceImage_601149(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_DeleteWorkspaceImage_601148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_DeleteWorkspaceImage_601148; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_601148(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_601149, base: "/",
    url: url_DeleteWorkspaceImage_601150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_601163 = ref object of OpenApiRestCall_600437
proc url_DescribeAccount_601165(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccount_601164(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_DescribeAccount_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_DescribeAccount_601163; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_601177 = newJObject()
  if body != nil:
    body_601177 = body
  result = call_601176.call(nil, nil, nil, nil, body_601177)

var describeAccount* = Call_DescribeAccount_601163(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_601164, base: "/", url: url_DescribeAccount_601165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_601178 = ref object of OpenApiRestCall_600437
proc url_DescribeAccountModifications_601180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccountModifications_601179(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_DescribeAccountModifications_601178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_DescribeAccountModifications_601178; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_601192 = newJObject()
  if body != nil:
    body_601192 = body
  result = call_601191.call(nil, nil, nil, nil, body_601192)

var describeAccountModifications* = Call_DescribeAccountModifications_601178(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_601179, base: "/",
    url: url_DescribeAccountModifications_601180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_601193 = ref object of OpenApiRestCall_600437
proc url_DescribeClientProperties_601195(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeClientProperties_601194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_DescribeClientProperties_601193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_DescribeClientProperties_601193; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  result = call_601206.call(nil, nil, nil, nil, body_601207)

var describeClientProperties* = Call_DescribeClientProperties_601193(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_601194, base: "/",
    url: url_DescribeClientProperties_601195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_601208 = ref object of OpenApiRestCall_600437
proc url_DescribeIpGroups_601210(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeIpGroups_601209(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601211 = header.getOrDefault("X-Amz-Date")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Date", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Security-Token")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Security-Token", valid_601212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601213 = header.getOrDefault("X-Amz-Target")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_601213 != nil:
    section.add "X-Amz-Target", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_DescribeIpGroups_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_DescribeIpGroups_601208; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_601222 = newJObject()
  if body != nil:
    body_601222 = body
  result = call_601221.call(nil, nil, nil, nil, body_601222)

var describeIpGroups* = Call_DescribeIpGroups_601208(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_601209, base: "/",
    url: url_DescribeIpGroups_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_601223 = ref object of OpenApiRestCall_600437
proc url_DescribeTags_601225(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTags_601224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_DescribeTags_601223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_DescribeTags_601223; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_601237 = newJObject()
  if body != nil:
    body_601237 = body
  result = call_601236.call(nil, nil, nil, nil, body_601237)

var describeTags* = Call_DescribeTags_601223(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_601224, base: "/", url: url_DescribeTags_601225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_601238 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspaceBundles_601240(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceBundles_601239(path: JsonNode; query: JsonNode;
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
  var valid_601241 = query.getOrDefault("NextToken")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "NextToken", valid_601241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_DescribeWorkspaceBundles_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_DescribeWorkspaceBundles_601238; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601253 = newJObject()
  var body_601254 = newJObject()
  add(query_601253, "NextToken", newJString(NextToken))
  if body != nil:
    body_601254 = body
  result = call_601252.call(nil, query_601253, nil, nil, body_601254)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_601238(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_601239, base: "/",
    url: url_DescribeWorkspaceBundles_601240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_601256 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspaceDirectories_601258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceDirectories_601257(path: JsonNode; query: JsonNode;
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
  var valid_601259 = query.getOrDefault("NextToken")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "NextToken", valid_601259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601260 = header.getOrDefault("X-Amz-Date")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Date", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Security-Token")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Security-Token", valid_601261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601262 = header.getOrDefault("X-Amz-Target")
  valid_601262 = validateParameter(valid_601262, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_601262 != nil:
    section.add "X-Amz-Target", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Content-Sha256", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Algorithm")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Algorithm", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Signature")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Signature", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-SignedHeaders", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Credential")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Credential", valid_601267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601269: Call_DescribeWorkspaceDirectories_601256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_601269.validator(path, query, header, formData, body)
  let scheme = call_601269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601269.url(scheme.get, call_601269.host, call_601269.base,
                         call_601269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601269, url, valid)

proc call*(call_601270: Call_DescribeWorkspaceDirectories_601256; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601271 = newJObject()
  var body_601272 = newJObject()
  add(query_601271, "NextToken", newJString(NextToken))
  if body != nil:
    body_601272 = body
  result = call_601270.call(nil, query_601271, nil, nil, body_601272)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_601256(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_601257, base: "/",
    url: url_DescribeWorkspaceDirectories_601258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_601273 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspaceImages_601275(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceImages_601274(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601276 = header.getOrDefault("X-Amz-Date")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Date", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Security-Token")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Security-Token", valid_601277
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601278 = header.getOrDefault("X-Amz-Target")
  valid_601278 = validateParameter(valid_601278, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_601278 != nil:
    section.add "X-Amz-Target", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Content-Sha256", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Algorithm")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Algorithm", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Signature")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Signature", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-SignedHeaders", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Credential")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Credential", valid_601283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601285: Call_DescribeWorkspaceImages_601273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_601285.validator(path, query, header, formData, body)
  let scheme = call_601285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601285.url(scheme.get, call_601285.host, call_601285.base,
                         call_601285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601285, url, valid)

proc call*(call_601286: Call_DescribeWorkspaceImages_601273; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_601287 = newJObject()
  if body != nil:
    body_601287 = body
  result = call_601286.call(nil, nil, nil, nil, body_601287)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_601273(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_601274, base: "/",
    url: url_DescribeWorkspaceImages_601275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_601288 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspaceSnapshots_601290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceSnapshots_601289(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601291 = header.getOrDefault("X-Amz-Date")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Date", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Security-Token")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Security-Token", valid_601292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601293 = header.getOrDefault("X-Amz-Target")
  valid_601293 = validateParameter(valid_601293, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_601293 != nil:
    section.add "X-Amz-Target", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Content-Sha256", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Algorithm")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Algorithm", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Signature")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Signature", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-SignedHeaders", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Credential")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Credential", valid_601298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601300: Call_DescribeWorkspaceSnapshots_601288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_601300.validator(path, query, header, formData, body)
  let scheme = call_601300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601300.url(scheme.get, call_601300.host, call_601300.base,
                         call_601300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601300, url, valid)

proc call*(call_601301: Call_DescribeWorkspaceSnapshots_601288; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_601302 = newJObject()
  if body != nil:
    body_601302 = body
  result = call_601301.call(nil, nil, nil, nil, body_601302)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_601288(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_601289, base: "/",
    url: url_DescribeWorkspaceSnapshots_601290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_601303 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspaces_601305(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaces_601304(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601306 = query.getOrDefault("Limit")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "Limit", valid_601306
  var valid_601307 = query.getOrDefault("NextToken")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "NextToken", valid_601307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601308 = header.getOrDefault("X-Amz-Date")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Date", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Security-Token")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Security-Token", valid_601309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601310 = header.getOrDefault("X-Amz-Target")
  valid_601310 = validateParameter(valid_601310, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_601310 != nil:
    section.add "X-Amz-Target", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Content-Sha256", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Algorithm")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Algorithm", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Signature")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Signature", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-SignedHeaders", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Credential")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Credential", valid_601315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_DescribeWorkspaces_601303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_DescribeWorkspaces_601303; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601319 = newJObject()
  var body_601320 = newJObject()
  add(query_601319, "Limit", newJString(Limit))
  add(query_601319, "NextToken", newJString(NextToken))
  if body != nil:
    body_601320 = body
  result = call_601318.call(nil, query_601319, nil, nil, body_601320)

var describeWorkspaces* = Call_DescribeWorkspaces_601303(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_601304, base: "/",
    url: url_DescribeWorkspaces_601305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_601321 = ref object of OpenApiRestCall_600437
proc url_DescribeWorkspacesConnectionStatus_601323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspacesConnectionStatus_601322(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601324 = header.getOrDefault("X-Amz-Date")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Date", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Security-Token")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Security-Token", valid_601325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601326 = header.getOrDefault("X-Amz-Target")
  valid_601326 = validateParameter(valid_601326, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_601326 != nil:
    section.add "X-Amz-Target", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Content-Sha256", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Algorithm")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Algorithm", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Signature")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Signature", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-SignedHeaders", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Credential")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Credential", valid_601331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601333: Call_DescribeWorkspacesConnectionStatus_601321;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_601333.validator(path, query, header, formData, body)
  let scheme = call_601333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601333.url(scheme.get, call_601333.host, call_601333.base,
                         call_601333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601333, url, valid)

proc call*(call_601334: Call_DescribeWorkspacesConnectionStatus_601321;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_601335 = newJObject()
  if body != nil:
    body_601335 = body
  result = call_601334.call(nil, nil, nil, nil, body_601335)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_601321(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_601322, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_601323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_601336 = ref object of OpenApiRestCall_600437
proc url_DisassociateIpGroups_601338(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateIpGroups_601337(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601339 = header.getOrDefault("X-Amz-Date")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Date", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Security-Token")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Security-Token", valid_601340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601341 = header.getOrDefault("X-Amz-Target")
  valid_601341 = validateParameter(valid_601341, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_601341 != nil:
    section.add "X-Amz-Target", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Content-Sha256", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Algorithm")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Algorithm", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Signature")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Signature", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-SignedHeaders", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Credential")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Credential", valid_601346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601348: Call_DisassociateIpGroups_601336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_601348.validator(path, query, header, formData, body)
  let scheme = call_601348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601348.url(scheme.get, call_601348.host, call_601348.base,
                         call_601348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601348, url, valid)

proc call*(call_601349: Call_DisassociateIpGroups_601336; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_601350 = newJObject()
  if body != nil:
    body_601350 = body
  result = call_601349.call(nil, nil, nil, nil, body_601350)

var disassociateIpGroups* = Call_DisassociateIpGroups_601336(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_601337, base: "/",
    url: url_DisassociateIpGroups_601338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_601351 = ref object of OpenApiRestCall_600437
proc url_ImportWorkspaceImage_601353(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportWorkspaceImage_601352(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601354 = header.getOrDefault("X-Amz-Date")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Date", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Security-Token")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Security-Token", valid_601355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601356 = header.getOrDefault("X-Amz-Target")
  valid_601356 = validateParameter(valid_601356, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_601356 != nil:
    section.add "X-Amz-Target", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Content-Sha256", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Algorithm")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Algorithm", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Signature")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Signature", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-SignedHeaders", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Credential")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Credential", valid_601361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601363: Call_ImportWorkspaceImage_601351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_601363.validator(path, query, header, formData, body)
  let scheme = call_601363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601363.url(scheme.get, call_601363.host, call_601363.base,
                         call_601363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601363, url, valid)

proc call*(call_601364: Call_ImportWorkspaceImage_601351; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_601365 = newJObject()
  if body != nil:
    body_601365 = body
  result = call_601364.call(nil, nil, nil, nil, body_601365)

var importWorkspaceImage* = Call_ImportWorkspaceImage_601351(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_601352, base: "/",
    url: url_ImportWorkspaceImage_601353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_601366 = ref object of OpenApiRestCall_600437
proc url_ListAvailableManagementCidrRanges_601368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAvailableManagementCidrRanges_601367(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601369 = header.getOrDefault("X-Amz-Date")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Date", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Security-Token")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Security-Token", valid_601370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601371 = header.getOrDefault("X-Amz-Target")
  valid_601371 = validateParameter(valid_601371, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_601371 != nil:
    section.add "X-Amz-Target", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Content-Sha256", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Algorithm")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Algorithm", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Signature")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Signature", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-SignedHeaders", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Credential")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Credential", valid_601376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601378: Call_ListAvailableManagementCidrRanges_601366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_601378.validator(path, query, header, formData, body)
  let scheme = call_601378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601378.url(scheme.get, call_601378.host, call_601378.base,
                         call_601378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601378, url, valid)

proc call*(call_601379: Call_ListAvailableManagementCidrRanges_601366;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_601380 = newJObject()
  if body != nil:
    body_601380 = body
  result = call_601379.call(nil, nil, nil, nil, body_601380)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_601366(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_601367, base: "/",
    url: url_ListAvailableManagementCidrRanges_601368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_601381 = ref object of OpenApiRestCall_600437
proc url_ModifyAccount_601383(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyAccount_601382(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601384 = header.getOrDefault("X-Amz-Date")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Date", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Security-Token")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Security-Token", valid_601385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601386 = header.getOrDefault("X-Amz-Target")
  valid_601386 = validateParameter(valid_601386, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_601386 != nil:
    section.add "X-Amz-Target", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Content-Sha256", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Algorithm")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Algorithm", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Signature")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Signature", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-SignedHeaders", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Credential")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Credential", valid_601391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601393: Call_ModifyAccount_601381; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_601393.validator(path, query, header, formData, body)
  let scheme = call_601393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601393.url(scheme.get, call_601393.host, call_601393.base,
                         call_601393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601393, url, valid)

proc call*(call_601394: Call_ModifyAccount_601381; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_601395 = newJObject()
  if body != nil:
    body_601395 = body
  result = call_601394.call(nil, nil, nil, nil, body_601395)

var modifyAccount* = Call_ModifyAccount_601381(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_601382, base: "/", url: url_ModifyAccount_601383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_601396 = ref object of OpenApiRestCall_600437
proc url_ModifyClientProperties_601398(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyClientProperties_601397(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601399 = header.getOrDefault("X-Amz-Date")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Date", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Security-Token")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Security-Token", valid_601400
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601401 = header.getOrDefault("X-Amz-Target")
  valid_601401 = validateParameter(valid_601401, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_601401 != nil:
    section.add "X-Amz-Target", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Content-Sha256", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Algorithm")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Algorithm", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Signature")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Signature", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-SignedHeaders", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Credential")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Credential", valid_601406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601408: Call_ModifyClientProperties_601396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_601408.validator(path, query, header, formData, body)
  let scheme = call_601408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601408.url(scheme.get, call_601408.host, call_601408.base,
                         call_601408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601408, url, valid)

proc call*(call_601409: Call_ModifyClientProperties_601396; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_601410 = newJObject()
  if body != nil:
    body_601410 = body
  result = call_601409.call(nil, nil, nil, nil, body_601410)

var modifyClientProperties* = Call_ModifyClientProperties_601396(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_601397, base: "/",
    url: url_ModifyClientProperties_601398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_601411 = ref object of OpenApiRestCall_600437
proc url_ModifyWorkspaceProperties_601413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceProperties_601412(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601414 = header.getOrDefault("X-Amz-Date")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Date", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Security-Token")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Security-Token", valid_601415
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601416 = header.getOrDefault("X-Amz-Target")
  valid_601416 = validateParameter(valid_601416, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_601416 != nil:
    section.add "X-Amz-Target", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601423: Call_ModifyWorkspaceProperties_601411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_601423.validator(path, query, header, formData, body)
  let scheme = call_601423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601423.url(scheme.get, call_601423.host, call_601423.base,
                         call_601423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601423, url, valid)

proc call*(call_601424: Call_ModifyWorkspaceProperties_601411; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_601425 = newJObject()
  if body != nil:
    body_601425 = body
  result = call_601424.call(nil, nil, nil, nil, body_601425)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_601411(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_601412, base: "/",
    url: url_ModifyWorkspaceProperties_601413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_601426 = ref object of OpenApiRestCall_600437
proc url_ModifyWorkspaceState_601428(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceState_601427(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601429 = header.getOrDefault("X-Amz-Date")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Date", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Security-Token")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Security-Token", valid_601430
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601431 = header.getOrDefault("X-Amz-Target")
  valid_601431 = validateParameter(valid_601431, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_601431 != nil:
    section.add "X-Amz-Target", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Content-Sha256", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Algorithm")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Algorithm", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Signature")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Signature", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-SignedHeaders", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Credential")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Credential", valid_601436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601438: Call_ModifyWorkspaceState_601426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_601438.validator(path, query, header, formData, body)
  let scheme = call_601438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601438.url(scheme.get, call_601438.host, call_601438.base,
                         call_601438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601438, url, valid)

proc call*(call_601439: Call_ModifyWorkspaceState_601426; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_601440 = newJObject()
  if body != nil:
    body_601440 = body
  result = call_601439.call(nil, nil, nil, nil, body_601440)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_601426(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_601427, base: "/",
    url: url_ModifyWorkspaceState_601428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_601441 = ref object of OpenApiRestCall_600437
proc url_RebootWorkspaces_601443(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootWorkspaces_601442(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601444 = header.getOrDefault("X-Amz-Date")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Date", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Security-Token")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Security-Token", valid_601445
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601446 = header.getOrDefault("X-Amz-Target")
  valid_601446 = validateParameter(valid_601446, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_601446 != nil:
    section.add "X-Amz-Target", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Content-Sha256", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Algorithm")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Algorithm", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Signature")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Signature", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-SignedHeaders", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Credential")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Credential", valid_601451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601453: Call_RebootWorkspaces_601441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_601453.validator(path, query, header, formData, body)
  let scheme = call_601453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601453.url(scheme.get, call_601453.host, call_601453.base,
                         call_601453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601453, url, valid)

proc call*(call_601454: Call_RebootWorkspaces_601441; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_601455 = newJObject()
  if body != nil:
    body_601455 = body
  result = call_601454.call(nil, nil, nil, nil, body_601455)

var rebootWorkspaces* = Call_RebootWorkspaces_601441(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_601442, base: "/",
    url: url_RebootWorkspaces_601443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_601456 = ref object of OpenApiRestCall_600437
proc url_RebuildWorkspaces_601458(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebuildWorkspaces_601457(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601459 = header.getOrDefault("X-Amz-Date")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Date", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Security-Token")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Security-Token", valid_601460
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601461 = header.getOrDefault("X-Amz-Target")
  valid_601461 = validateParameter(valid_601461, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_601461 != nil:
    section.add "X-Amz-Target", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Content-Sha256", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Algorithm")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Algorithm", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Signature")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Signature", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-SignedHeaders", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Credential")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Credential", valid_601466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601468: Call_RebuildWorkspaces_601456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_601468.validator(path, query, header, formData, body)
  let scheme = call_601468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601468.url(scheme.get, call_601468.host, call_601468.base,
                         call_601468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601468, url, valid)

proc call*(call_601469: Call_RebuildWorkspaces_601456; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_601470 = newJObject()
  if body != nil:
    body_601470 = body
  result = call_601469.call(nil, nil, nil, nil, body_601470)

var rebuildWorkspaces* = Call_RebuildWorkspaces_601456(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_601457, base: "/",
    url: url_RebuildWorkspaces_601458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_601471 = ref object of OpenApiRestCall_600437
proc url_RestoreWorkspace_601473(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreWorkspace_601472(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601474 = header.getOrDefault("X-Amz-Date")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Date", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Security-Token")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Security-Token", valid_601475
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601476 = header.getOrDefault("X-Amz-Target")
  valid_601476 = validateParameter(valid_601476, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_601476 != nil:
    section.add "X-Amz-Target", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Content-Sha256", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Algorithm")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Algorithm", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Signature")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Signature", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-SignedHeaders", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Credential")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Credential", valid_601481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601483: Call_RestoreWorkspace_601471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_601483.validator(path, query, header, formData, body)
  let scheme = call_601483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601483.url(scheme.get, call_601483.host, call_601483.base,
                         call_601483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601483, url, valid)

proc call*(call_601484: Call_RestoreWorkspace_601471; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_601485 = newJObject()
  if body != nil:
    body_601485 = body
  result = call_601484.call(nil, nil, nil, nil, body_601485)

var restoreWorkspace* = Call_RestoreWorkspace_601471(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_601472, base: "/",
    url: url_RestoreWorkspace_601473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_601486 = ref object of OpenApiRestCall_600437
proc url_RevokeIpRules_601488(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeIpRules_601487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601489 = header.getOrDefault("X-Amz-Date")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Date", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Security-Token")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Security-Token", valid_601490
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601491 = header.getOrDefault("X-Amz-Target")
  valid_601491 = validateParameter(valid_601491, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_601491 != nil:
    section.add "X-Amz-Target", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Content-Sha256", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Algorithm")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Algorithm", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Signature")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Signature", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-SignedHeaders", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Credential")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Credential", valid_601496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601498: Call_RevokeIpRules_601486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_601498.validator(path, query, header, formData, body)
  let scheme = call_601498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601498.url(scheme.get, call_601498.host, call_601498.base,
                         call_601498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601498, url, valid)

proc call*(call_601499: Call_RevokeIpRules_601486; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_601500 = newJObject()
  if body != nil:
    body_601500 = body
  result = call_601499.call(nil, nil, nil, nil, body_601500)

var revokeIpRules* = Call_RevokeIpRules_601486(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_601487, base: "/", url: url_RevokeIpRules_601488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_601501 = ref object of OpenApiRestCall_600437
proc url_StartWorkspaces_601503(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkspaces_601502(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601504 = header.getOrDefault("X-Amz-Date")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Date", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Security-Token")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Security-Token", valid_601505
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601506 = header.getOrDefault("X-Amz-Target")
  valid_601506 = validateParameter(valid_601506, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_601506 != nil:
    section.add "X-Amz-Target", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Content-Sha256", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Algorithm")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Algorithm", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Signature")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Signature", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-SignedHeaders", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Credential")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Credential", valid_601511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601513: Call_StartWorkspaces_601501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_601513.validator(path, query, header, formData, body)
  let scheme = call_601513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601513.url(scheme.get, call_601513.host, call_601513.base,
                         call_601513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601513, url, valid)

proc call*(call_601514: Call_StartWorkspaces_601501; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_601515 = newJObject()
  if body != nil:
    body_601515 = body
  result = call_601514.call(nil, nil, nil, nil, body_601515)

var startWorkspaces* = Call_StartWorkspaces_601501(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_601502, base: "/", url: url_StartWorkspaces_601503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_601516 = ref object of OpenApiRestCall_600437
proc url_StopWorkspaces_601518(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopWorkspaces_601517(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601519 = header.getOrDefault("X-Amz-Date")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Date", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Security-Token")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Security-Token", valid_601520
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601521 = header.getOrDefault("X-Amz-Target")
  valid_601521 = validateParameter(valid_601521, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_601521 != nil:
    section.add "X-Amz-Target", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Content-Sha256", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Algorithm")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Algorithm", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Signature")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Signature", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-SignedHeaders", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-Credential")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Credential", valid_601526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601528: Call_StopWorkspaces_601516; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_601528.validator(path, query, header, formData, body)
  let scheme = call_601528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601528.url(scheme.get, call_601528.host, call_601528.base,
                         call_601528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601528, url, valid)

proc call*(call_601529: Call_StopWorkspaces_601516; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_601530 = newJObject()
  if body != nil:
    body_601530 = body
  result = call_601529.call(nil, nil, nil, nil, body_601530)

var stopWorkspaces* = Call_StopWorkspaces_601516(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_601517, base: "/", url: url_StopWorkspaces_601518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_601531 = ref object of OpenApiRestCall_600437
proc url_TerminateWorkspaces_601533(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateWorkspaces_601532(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601534 = header.getOrDefault("X-Amz-Date")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Date", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Security-Token")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Security-Token", valid_601535
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601536 = header.getOrDefault("X-Amz-Target")
  valid_601536 = validateParameter(valid_601536, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_601536 != nil:
    section.add "X-Amz-Target", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Content-Sha256", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Algorithm")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Algorithm", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Signature")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Signature", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-SignedHeaders", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Credential")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Credential", valid_601541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601543: Call_TerminateWorkspaces_601531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_601543.validator(path, query, header, formData, body)
  let scheme = call_601543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601543.url(scheme.get, call_601543.host, call_601543.base,
                         call_601543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601543, url, valid)

proc call*(call_601544: Call_TerminateWorkspaces_601531; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_601545 = newJObject()
  if body != nil:
    body_601545 = body
  result = call_601544.call(nil, nil, nil, nil, body_601545)

var terminateWorkspaces* = Call_TerminateWorkspaces_601531(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_601532, base: "/",
    url: url_TerminateWorkspaces_601533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_601546 = ref object of OpenApiRestCall_600437
proc url_UpdateRulesOfIpGroup_601548(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRulesOfIpGroup_601547(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601549 = header.getOrDefault("X-Amz-Date")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Date", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Security-Token")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Security-Token", valid_601550
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601551 = header.getOrDefault("X-Amz-Target")
  valid_601551 = validateParameter(valid_601551, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_601551 != nil:
    section.add "X-Amz-Target", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Content-Sha256", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Algorithm")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Algorithm", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Signature")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Signature", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-SignedHeaders", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Credential")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Credential", valid_601556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601558: Call_UpdateRulesOfIpGroup_601546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_601558.validator(path, query, header, formData, body)
  let scheme = call_601558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601558.url(scheme.get, call_601558.host, call_601558.base,
                         call_601558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601558, url, valid)

proc call*(call_601559: Call_UpdateRulesOfIpGroup_601546; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_601560 = newJObject()
  if body != nil:
    body_601560 = body
  result = call_601559.call(nil, nil, nil, nil, body_601560)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_601546(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_601547, base: "/",
    url: url_UpdateRulesOfIpGroup_601548, schemes: {Scheme.Https, Scheme.Http})
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
