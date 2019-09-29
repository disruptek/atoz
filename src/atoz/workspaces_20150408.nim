
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_AssociateIpGroups_593774 = ref object of OpenApiRestCall_593437
proc url_AssociateIpGroups_593776(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateIpGroups_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AssociateIpGroups_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AssociateIpGroups_593774; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var associateIpGroups* = Call_AssociateIpGroups_593774(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_593775, base: "/",
    url: url_AssociateIpGroups_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_594043 = ref object of OpenApiRestCall_593437
proc url_AuthorizeIpRules_594045(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AuthorizeIpRules_594044(path: JsonNode; query: JsonNode;
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_AuthorizeIpRules_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_AuthorizeIpRules_594043; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var authorizeIpRules* = Call_AuthorizeIpRules_594043(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_594044, base: "/",
    url: url_AuthorizeIpRules_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_594058 = ref object of OpenApiRestCall_593437
proc url_CopyWorkspaceImage_594060(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyWorkspaceImage_594059(path: JsonNode; query: JsonNode;
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CopyWorkspaceImage_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CopyWorkspaceImage_594058; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_594058(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_594059, base: "/",
    url: url_CopyWorkspaceImage_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_594073 = ref object of OpenApiRestCall_593437
proc url_CreateIpGroup_594075(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIpGroup_594074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateIpGroup_594073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateIpGroup_594073; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createIpGroup* = Call_CreateIpGroup_594073(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_594074, base: "/", url: url_CreateIpGroup_594075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_594088 = ref object of OpenApiRestCall_593437
proc url_CreateTags_594090(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTags_594089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateTags_594088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateTags_594088; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createTags* = Call_CreateTags_594088(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_594089,
                                      base: "/", url: url_CreateTags_594090,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_594103 = ref object of OpenApiRestCall_593437
proc url_CreateWorkspaces_594105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkspaces_594104(path: JsonNode; query: JsonNode;
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateWorkspaces_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateWorkspaces_594103; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createWorkspaces* = Call_CreateWorkspaces_594103(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_594104, base: "/",
    url: url_CreateWorkspaces_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_594118 = ref object of OpenApiRestCall_593437
proc url_DeleteIpGroup_594120(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteIpGroup_594119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_DeleteIpGroup_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_DeleteIpGroup_594118; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var deleteIpGroup* = Call_DeleteIpGroup_594118(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_594119, base: "/", url: url_DeleteIpGroup_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_594133 = ref object of OpenApiRestCall_593437
proc url_DeleteTags_594135(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_594134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_DeleteTags_594133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_DeleteTags_594133; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var deleteTags* = Call_DeleteTags_594133(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_594134,
                                      base: "/", url: url_DeleteTags_594135,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_594148 = ref object of OpenApiRestCall_593437
proc url_DeleteWorkspaceImage_594150(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkspaceImage_594149(path: JsonNode; query: JsonNode;
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_DeleteWorkspaceImage_594148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_DeleteWorkspaceImage_594148; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_594148(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_594149, base: "/",
    url: url_DeleteWorkspaceImage_594150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_594163 = ref object of OpenApiRestCall_593437
proc url_DescribeAccount_594165(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccount_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_DescribeAccount_594163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_DescribeAccount_594163; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var describeAccount* = Call_DescribeAccount_594163(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_594164, base: "/", url: url_DescribeAccount_594165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_594178 = ref object of OpenApiRestCall_593437
proc url_DescribeAccountModifications_594180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccountModifications_594179(path: JsonNode; query: JsonNode;
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_DescribeAccountModifications_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_DescribeAccountModifications_594178; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var describeAccountModifications* = Call_DescribeAccountModifications_594178(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_594179, base: "/",
    url: url_DescribeAccountModifications_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_594193 = ref object of OpenApiRestCall_593437
proc url_DescribeClientProperties_594195(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeClientProperties_594194(path: JsonNode; query: JsonNode;
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_DescribeClientProperties_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_DescribeClientProperties_594193; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var describeClientProperties* = Call_DescribeClientProperties_594193(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_594194, base: "/",
    url: url_DescribeClientProperties_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_594208 = ref object of OpenApiRestCall_593437
proc url_DescribeIpGroups_594210(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeIpGroups_594209(path: JsonNode; query: JsonNode;
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_DescribeIpGroups_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_DescribeIpGroups_594208; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var describeIpGroups* = Call_DescribeIpGroups_594208(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_594209, base: "/",
    url: url_DescribeIpGroups_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_594223 = ref object of OpenApiRestCall_593437
proc url_DescribeTags_594225(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTags_594224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DescribeTags_594223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DescribeTags_594223; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var describeTags* = Call_DescribeTags_594223(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_594224, base: "/", url: url_DescribeTags_594225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_594238 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspaceBundles_594240(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceBundles_594239(path: JsonNode; query: JsonNode;
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
  var valid_594241 = query.getOrDefault("NextToken")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "NextToken", valid_594241
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
  var valid_594242 = header.getOrDefault("X-Amz-Date")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Date", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Security-Token")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Security-Token", valid_594243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594244 = header.getOrDefault("X-Amz-Target")
  valid_594244 = validateParameter(valid_594244, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_594244 != nil:
    section.add "X-Amz-Target", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Content-Sha256", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Algorithm")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Algorithm", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Signature")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Signature", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-SignedHeaders", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594251: Call_DescribeWorkspaceBundles_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_594251.validator(path, query, header, formData, body)
  let scheme = call_594251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594251.url(scheme.get, call_594251.host, call_594251.base,
                         call_594251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594251, url, valid)

proc call*(call_594252: Call_DescribeWorkspaceBundles_594238; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594253 = newJObject()
  var body_594254 = newJObject()
  add(query_594253, "NextToken", newJString(NextToken))
  if body != nil:
    body_594254 = body
  result = call_594252.call(nil, query_594253, nil, nil, body_594254)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_594238(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_594239, base: "/",
    url: url_DescribeWorkspaceBundles_594240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_594256 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspaceDirectories_594258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceDirectories_594257(path: JsonNode; query: JsonNode;
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
  var valid_594259 = query.getOrDefault("NextToken")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "NextToken", valid_594259
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
  var valid_594260 = header.getOrDefault("X-Amz-Date")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Date", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Security-Token")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Security-Token", valid_594261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594262 = header.getOrDefault("X-Amz-Target")
  valid_594262 = validateParameter(valid_594262, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_594262 != nil:
    section.add "X-Amz-Target", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Content-Sha256", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Algorithm")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Algorithm", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Signature")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Signature", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-SignedHeaders", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Credential")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Credential", valid_594267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594269: Call_DescribeWorkspaceDirectories_594256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_594269.validator(path, query, header, formData, body)
  let scheme = call_594269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594269.url(scheme.get, call_594269.host, call_594269.base,
                         call_594269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594269, url, valid)

proc call*(call_594270: Call_DescribeWorkspaceDirectories_594256; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available AWS Directory Service directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594271 = newJObject()
  var body_594272 = newJObject()
  add(query_594271, "NextToken", newJString(NextToken))
  if body != nil:
    body_594272 = body
  result = call_594270.call(nil, query_594271, nil, nil, body_594272)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_594256(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_594257, base: "/",
    url: url_DescribeWorkspaceDirectories_594258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_594273 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspaceImages_594275(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceImages_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = header.getOrDefault("X-Amz-Date")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Date", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Security-Token")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Security-Token", valid_594277
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594278 = header.getOrDefault("X-Amz-Target")
  valid_594278 = validateParameter(valid_594278, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_594278 != nil:
    section.add "X-Amz-Target", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Content-Sha256", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Algorithm")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Algorithm", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Signature")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Signature", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-SignedHeaders", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Credential")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Credential", valid_594283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594285: Call_DescribeWorkspaceImages_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_594285.validator(path, query, header, formData, body)
  let scheme = call_594285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594285.url(scheme.get, call_594285.host, call_594285.base,
                         call_594285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594285, url, valid)

proc call*(call_594286: Call_DescribeWorkspaceImages_594273; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_594287 = newJObject()
  if body != nil:
    body_594287 = body
  result = call_594286.call(nil, nil, nil, nil, body_594287)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_594273(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_594274, base: "/",
    url: url_DescribeWorkspaceImages_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_594288 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspaceSnapshots_594290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaceSnapshots_594289(path: JsonNode; query: JsonNode;
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
  var valid_594291 = header.getOrDefault("X-Amz-Date")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Date", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Security-Token")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Security-Token", valid_594292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594293 = header.getOrDefault("X-Amz-Target")
  valid_594293 = validateParameter(valid_594293, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_594293 != nil:
    section.add "X-Amz-Target", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Content-Sha256", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Algorithm")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Algorithm", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Signature")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Signature", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-SignedHeaders", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Credential")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Credential", valid_594298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594300: Call_DescribeWorkspaceSnapshots_594288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_594300.validator(path, query, header, formData, body)
  let scheme = call_594300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594300.url(scheme.get, call_594300.host, call_594300.base,
                         call_594300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594300, url, valid)

proc call*(call_594301: Call_DescribeWorkspaceSnapshots_594288; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_594302 = newJObject()
  if body != nil:
    body_594302 = body
  result = call_594301.call(nil, nil, nil, nil, body_594302)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_594288(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_594289, base: "/",
    url: url_DescribeWorkspaceSnapshots_594290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_594303 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspaces_594305(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspaces_594304(path: JsonNode; query: JsonNode;
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
  var valid_594306 = query.getOrDefault("Limit")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "Limit", valid_594306
  var valid_594307 = query.getOrDefault("NextToken")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "NextToken", valid_594307
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
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594310 = header.getOrDefault("X-Amz-Target")
  valid_594310 = validateParameter(valid_594310, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_594310 != nil:
    section.add "X-Amz-Target", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Content-Sha256", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Algorithm")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Algorithm", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Signature")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Signature", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-SignedHeaders", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Credential")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Credential", valid_594315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594317: Call_DescribeWorkspaces_594303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_594317.validator(path, query, header, formData, body)
  let scheme = call_594317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594317.url(scheme.get, call_594317.host, call_594317.base,
                         call_594317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594317, url, valid)

proc call*(call_594318: Call_DescribeWorkspaces_594303; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594319 = newJObject()
  var body_594320 = newJObject()
  add(query_594319, "Limit", newJString(Limit))
  add(query_594319, "NextToken", newJString(NextToken))
  if body != nil:
    body_594320 = body
  result = call_594318.call(nil, query_594319, nil, nil, body_594320)

var describeWorkspaces* = Call_DescribeWorkspaces_594303(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_594304, base: "/",
    url: url_DescribeWorkspaces_594305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_594321 = ref object of OpenApiRestCall_593437
proc url_DescribeWorkspacesConnectionStatus_594323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkspacesConnectionStatus_594322(path: JsonNode;
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
  var valid_594324 = header.getOrDefault("X-Amz-Date")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Date", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Security-Token")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Security-Token", valid_594325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594326 = header.getOrDefault("X-Amz-Target")
  valid_594326 = validateParameter(valid_594326, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_594326 != nil:
    section.add "X-Amz-Target", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Content-Sha256", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Algorithm")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Algorithm", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Signature")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Signature", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-SignedHeaders", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Credential")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Credential", valid_594331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594333: Call_DescribeWorkspacesConnectionStatus_594321;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_594333.validator(path, query, header, formData, body)
  let scheme = call_594333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594333.url(scheme.get, call_594333.host, call_594333.base,
                         call_594333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594333, url, valid)

proc call*(call_594334: Call_DescribeWorkspacesConnectionStatus_594321;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_594335 = newJObject()
  if body != nil:
    body_594335 = body
  result = call_594334.call(nil, nil, nil, nil, body_594335)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_594321(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_594322, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_594323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_594336 = ref object of OpenApiRestCall_593437
proc url_DisassociateIpGroups_594338(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateIpGroups_594337(path: JsonNode; query: JsonNode;
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
  var valid_594339 = header.getOrDefault("X-Amz-Date")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Date", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Security-Token")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Security-Token", valid_594340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594341 = header.getOrDefault("X-Amz-Target")
  valid_594341 = validateParameter(valid_594341, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_594341 != nil:
    section.add "X-Amz-Target", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Content-Sha256", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Algorithm")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Algorithm", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Signature")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Signature", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-SignedHeaders", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Credential")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Credential", valid_594346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594348: Call_DisassociateIpGroups_594336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_594348.validator(path, query, header, formData, body)
  let scheme = call_594348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594348.url(scheme.get, call_594348.host, call_594348.base,
                         call_594348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594348, url, valid)

proc call*(call_594349: Call_DisassociateIpGroups_594336; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_594350 = newJObject()
  if body != nil:
    body_594350 = body
  result = call_594349.call(nil, nil, nil, nil, body_594350)

var disassociateIpGroups* = Call_DisassociateIpGroups_594336(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_594337, base: "/",
    url: url_DisassociateIpGroups_594338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_594351 = ref object of OpenApiRestCall_593437
proc url_ImportWorkspaceImage_594353(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportWorkspaceImage_594352(path: JsonNode; query: JsonNode;
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
  var valid_594354 = header.getOrDefault("X-Amz-Date")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Date", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Security-Token")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Security-Token", valid_594355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594356 = header.getOrDefault("X-Amz-Target")
  valid_594356 = validateParameter(valid_594356, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_594356 != nil:
    section.add "X-Amz-Target", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Content-Sha256", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Algorithm")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Algorithm", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Signature")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Signature", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-SignedHeaders", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Credential")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Credential", valid_594361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594363: Call_ImportWorkspaceImage_594351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_594363.validator(path, query, header, formData, body)
  let scheme = call_594363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594363.url(scheme.get, call_594363.host, call_594363.base,
                         call_594363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594363, url, valid)

proc call*(call_594364: Call_ImportWorkspaceImage_594351; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 bring your own license (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_594365 = newJObject()
  if body != nil:
    body_594365 = body
  result = call_594364.call(nil, nil, nil, nil, body_594365)

var importWorkspaceImage* = Call_ImportWorkspaceImage_594351(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_594352, base: "/",
    url: url_ImportWorkspaceImage_594353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_594366 = ref object of OpenApiRestCall_593437
proc url_ListAvailableManagementCidrRanges_594368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAvailableManagementCidrRanges_594367(path: JsonNode;
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
  var valid_594369 = header.getOrDefault("X-Amz-Date")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Date", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Security-Token")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Security-Token", valid_594370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594371 = header.getOrDefault("X-Amz-Target")
  valid_594371 = validateParameter(valid_594371, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_594371 != nil:
    section.add "X-Amz-Target", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Content-Sha256", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-Algorithm")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-Algorithm", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Signature")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Signature", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-SignedHeaders", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Credential")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Credential", valid_594376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594378: Call_ListAvailableManagementCidrRanges_594366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_594378.validator(path, query, header, formData, body)
  let scheme = call_594378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594378.url(scheme.get, call_594378.host, call_594378.base,
                         call_594378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594378, url, valid)

proc call*(call_594379: Call_ListAvailableManagementCidrRanges_594366;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable bring your own license (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_594380 = newJObject()
  if body != nil:
    body_594380 = body
  result = call_594379.call(nil, nil, nil, nil, body_594380)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_594366(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_594367, base: "/",
    url: url_ListAvailableManagementCidrRanges_594368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_594381 = ref object of OpenApiRestCall_593437
proc url_ModifyAccount_594383(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyAccount_594382(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594384 = header.getOrDefault("X-Amz-Date")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Date", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Security-Token")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Security-Token", valid_594385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594386 = header.getOrDefault("X-Amz-Target")
  valid_594386 = validateParameter(valid_594386, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_594386 != nil:
    section.add "X-Amz-Target", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Content-Sha256", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Algorithm")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Algorithm", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Signature")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Signature", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-SignedHeaders", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Credential")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Credential", valid_594391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594393: Call_ModifyAccount_594381; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ## 
  let valid = call_594393.validator(path, query, header, formData, body)
  let scheme = call_594393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594393.url(scheme.get, call_594393.host, call_594393.base,
                         call_594393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594393, url, valid)

proc call*(call_594394: Call_ModifyAccount_594381; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of bring your own license (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_594395 = newJObject()
  if body != nil:
    body_594395 = body
  result = call_594394.call(nil, nil, nil, nil, body_594395)

var modifyAccount* = Call_ModifyAccount_594381(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_594382, base: "/", url: url_ModifyAccount_594383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_594396 = ref object of OpenApiRestCall_593437
proc url_ModifyClientProperties_594398(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyClientProperties_594397(path: JsonNode; query: JsonNode;
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
  var valid_594399 = header.getOrDefault("X-Amz-Date")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Date", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Security-Token")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Security-Token", valid_594400
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594401 = header.getOrDefault("X-Amz-Target")
  valid_594401 = validateParameter(valid_594401, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_594401 != nil:
    section.add "X-Amz-Target", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Content-Sha256", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Algorithm")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Algorithm", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Signature")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Signature", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-SignedHeaders", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Credential")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Credential", valid_594406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594408: Call_ModifyClientProperties_594396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_594408.validator(path, query, header, formData, body)
  let scheme = call_594408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594408.url(scheme.get, call_594408.host, call_594408.base,
                         call_594408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594408, url, valid)

proc call*(call_594409: Call_ModifyClientProperties_594396; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_594410 = newJObject()
  if body != nil:
    body_594410 = body
  result = call_594409.call(nil, nil, nil, nil, body_594410)

var modifyClientProperties* = Call_ModifyClientProperties_594396(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_594397, base: "/",
    url: url_ModifyClientProperties_594398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_594411 = ref object of OpenApiRestCall_593437
proc url_ModifyWorkspaceProperties_594413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceProperties_594412(path: JsonNode; query: JsonNode;
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
  var valid_594414 = header.getOrDefault("X-Amz-Date")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Date", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Security-Token")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Security-Token", valid_594415
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594416 = header.getOrDefault("X-Amz-Target")
  valid_594416 = validateParameter(valid_594416, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_594416 != nil:
    section.add "X-Amz-Target", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Content-Sha256", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Algorithm")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Algorithm", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Signature")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Signature", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-SignedHeaders", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Credential")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Credential", valid_594421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594423: Call_ModifyWorkspaceProperties_594411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_594423.validator(path, query, header, formData, body)
  let scheme = call_594423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594423.url(scheme.get, call_594423.host, call_594423.base,
                         call_594423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594423, url, valid)

proc call*(call_594424: Call_ModifyWorkspaceProperties_594411; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_594425 = newJObject()
  if body != nil:
    body_594425 = body
  result = call_594424.call(nil, nil, nil, nil, body_594425)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_594411(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_594412, base: "/",
    url: url_ModifyWorkspaceProperties_594413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_594426 = ref object of OpenApiRestCall_593437
proc url_ModifyWorkspaceState_594428(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyWorkspaceState_594427(path: JsonNode; query: JsonNode;
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
  var valid_594429 = header.getOrDefault("X-Amz-Date")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Date", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Security-Token")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Security-Token", valid_594430
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594431 = header.getOrDefault("X-Amz-Target")
  valid_594431 = validateParameter(valid_594431, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_594431 != nil:
    section.add "X-Amz-Target", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Content-Sha256", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Algorithm")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Algorithm", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Signature")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Signature", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-SignedHeaders", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Credential")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Credential", valid_594436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594438: Call_ModifyWorkspaceState_594426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_594438.validator(path, query, header, formData, body)
  let scheme = call_594438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594438.url(scheme.get, call_594438.host, call_594438.base,
                         call_594438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594438, url, valid)

proc call*(call_594439: Call_ModifyWorkspaceState_594426; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_594440 = newJObject()
  if body != nil:
    body_594440 = body
  result = call_594439.call(nil, nil, nil, nil, body_594440)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_594426(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_594427, base: "/",
    url: url_ModifyWorkspaceState_594428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_594441 = ref object of OpenApiRestCall_593437
proc url_RebootWorkspaces_594443(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootWorkspaces_594442(path: JsonNode; query: JsonNode;
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
  var valid_594444 = header.getOrDefault("X-Amz-Date")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Date", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Security-Token")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Security-Token", valid_594445
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594446 = header.getOrDefault("X-Amz-Target")
  valid_594446 = validateParameter(valid_594446, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_594446 != nil:
    section.add "X-Amz-Target", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Content-Sha256", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Algorithm")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Algorithm", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Signature")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Signature", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-SignedHeaders", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Credential")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Credential", valid_594451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594453: Call_RebootWorkspaces_594441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_594453.validator(path, query, header, formData, body)
  let scheme = call_594453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594453.url(scheme.get, call_594453.host, call_594453.base,
                         call_594453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594453, url, valid)

proc call*(call_594454: Call_RebootWorkspaces_594441; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_594455 = newJObject()
  if body != nil:
    body_594455 = body
  result = call_594454.call(nil, nil, nil, nil, body_594455)

var rebootWorkspaces* = Call_RebootWorkspaces_594441(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_594442, base: "/",
    url: url_RebootWorkspaces_594443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_594456 = ref object of OpenApiRestCall_593437
proc url_RebuildWorkspaces_594458(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebuildWorkspaces_594457(path: JsonNode; query: JsonNode;
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
  var valid_594459 = header.getOrDefault("X-Amz-Date")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Date", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Security-Token")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Security-Token", valid_594460
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594461 = header.getOrDefault("X-Amz-Target")
  valid_594461 = validateParameter(valid_594461, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_594461 != nil:
    section.add "X-Amz-Target", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Content-Sha256", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Algorithm")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Algorithm", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Signature")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Signature", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-SignedHeaders", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Credential")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Credential", valid_594466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594468: Call_RebuildWorkspaces_594456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_594468.validator(path, query, header, formData, body)
  let scheme = call_594468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594468.url(scheme.get, call_594468.host, call_594468.base,
                         call_594468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594468, url, valid)

proc call*(call_594469: Call_RebuildWorkspaces_594456; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_594470 = newJObject()
  if body != nil:
    body_594470 = body
  result = call_594469.call(nil, nil, nil, nil, body_594470)

var rebuildWorkspaces* = Call_RebuildWorkspaces_594456(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_594457, base: "/",
    url: url_RebuildWorkspaces_594458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_594471 = ref object of OpenApiRestCall_593437
proc url_RestoreWorkspace_594473(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreWorkspace_594472(path: JsonNode; query: JsonNode;
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
  var valid_594474 = header.getOrDefault("X-Amz-Date")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Date", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Security-Token")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Security-Token", valid_594475
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594476 = header.getOrDefault("X-Amz-Target")
  valid_594476 = validateParameter(valid_594476, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_594476 != nil:
    section.add "X-Amz-Target", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Content-Sha256", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Algorithm")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Algorithm", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Signature")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Signature", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-SignedHeaders", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Credential")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Credential", valid_594481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594483: Call_RestoreWorkspace_594471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_594483.validator(path, query, header, formData, body)
  let scheme = call_594483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594483.url(scheme.get, call_594483.host, call_594483.base,
                         call_594483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594483, url, valid)

proc call*(call_594484: Call_RestoreWorkspace_594471; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_594485 = newJObject()
  if body != nil:
    body_594485 = body
  result = call_594484.call(nil, nil, nil, nil, body_594485)

var restoreWorkspace* = Call_RestoreWorkspace_594471(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_594472, base: "/",
    url: url_RestoreWorkspace_594473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_594486 = ref object of OpenApiRestCall_593437
proc url_RevokeIpRules_594488(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeIpRules_594487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594489 = header.getOrDefault("X-Amz-Date")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Date", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Security-Token")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Security-Token", valid_594490
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594491 = header.getOrDefault("X-Amz-Target")
  valid_594491 = validateParameter(valid_594491, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_594491 != nil:
    section.add "X-Amz-Target", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Content-Sha256", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Algorithm")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Algorithm", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Signature")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Signature", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-SignedHeaders", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Credential")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Credential", valid_594496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594498: Call_RevokeIpRules_594486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_594498.validator(path, query, header, formData, body)
  let scheme = call_594498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594498.url(scheme.get, call_594498.host, call_594498.base,
                         call_594498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594498, url, valid)

proc call*(call_594499: Call_RevokeIpRules_594486; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_594500 = newJObject()
  if body != nil:
    body_594500 = body
  result = call_594499.call(nil, nil, nil, nil, body_594500)

var revokeIpRules* = Call_RevokeIpRules_594486(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_594487, base: "/", url: url_RevokeIpRules_594488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_594501 = ref object of OpenApiRestCall_593437
proc url_StartWorkspaces_594503(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkspaces_594502(path: JsonNode; query: JsonNode;
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
  var valid_594504 = header.getOrDefault("X-Amz-Date")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Date", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Security-Token")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Security-Token", valid_594505
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594506 = header.getOrDefault("X-Amz-Target")
  valid_594506 = validateParameter(valid_594506, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_594506 != nil:
    section.add "X-Amz-Target", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Content-Sha256", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Algorithm")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Algorithm", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Signature")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Signature", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-SignedHeaders", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Credential")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Credential", valid_594511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594513: Call_StartWorkspaces_594501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_594513.validator(path, query, header, formData, body)
  let scheme = call_594513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594513.url(scheme.get, call_594513.host, call_594513.base,
                         call_594513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594513, url, valid)

proc call*(call_594514: Call_StartWorkspaces_594501; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_594515 = newJObject()
  if body != nil:
    body_594515 = body
  result = call_594514.call(nil, nil, nil, nil, body_594515)

var startWorkspaces* = Call_StartWorkspaces_594501(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_594502, base: "/", url: url_StartWorkspaces_594503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_594516 = ref object of OpenApiRestCall_593437
proc url_StopWorkspaces_594518(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopWorkspaces_594517(path: JsonNode; query: JsonNode;
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
  var valid_594519 = header.getOrDefault("X-Amz-Date")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Date", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Security-Token")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Security-Token", valid_594520
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594521 = header.getOrDefault("X-Amz-Target")
  valid_594521 = validateParameter(valid_594521, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_594521 != nil:
    section.add "X-Amz-Target", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Content-Sha256", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Algorithm")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Algorithm", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Signature")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Signature", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-SignedHeaders", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Credential")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Credential", valid_594526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594528: Call_StopWorkspaces_594516; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_594528.validator(path, query, header, formData, body)
  let scheme = call_594528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594528.url(scheme.get, call_594528.host, call_594528.base,
                         call_594528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594528, url, valid)

proc call*(call_594529: Call_StopWorkspaces_594516; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_594530 = newJObject()
  if body != nil:
    body_594530 = body
  result = call_594529.call(nil, nil, nil, nil, body_594530)

var stopWorkspaces* = Call_StopWorkspaces_594516(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_594517, base: "/", url: url_StopWorkspaces_594518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_594531 = ref object of OpenApiRestCall_593437
proc url_TerminateWorkspaces_594533(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateWorkspaces_594532(path: JsonNode; query: JsonNode;
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
  var valid_594534 = header.getOrDefault("X-Amz-Date")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Date", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Security-Token")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Security-Token", valid_594535
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594536 = header.getOrDefault("X-Amz-Target")
  valid_594536 = validateParameter(valid_594536, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_594536 != nil:
    section.add "X-Amz-Target", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Content-Sha256", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Algorithm")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Algorithm", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Signature")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Signature", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-SignedHeaders", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Credential")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Credential", valid_594541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594543: Call_TerminateWorkspaces_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_594543.validator(path, query, header, formData, body)
  let scheme = call_594543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594543.url(scheme.get, call_594543.host, call_594543.base,
                         call_594543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594543, url, valid)

proc call*(call_594544: Call_TerminateWorkspaces_594531; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_594545 = newJObject()
  if body != nil:
    body_594545 = body
  result = call_594544.call(nil, nil, nil, nil, body_594545)

var terminateWorkspaces* = Call_TerminateWorkspaces_594531(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_594532, base: "/",
    url: url_TerminateWorkspaces_594533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_594546 = ref object of OpenApiRestCall_593437
proc url_UpdateRulesOfIpGroup_594548(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRulesOfIpGroup_594547(path: JsonNode; query: JsonNode;
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
  var valid_594549 = header.getOrDefault("X-Amz-Date")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Date", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Security-Token")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Security-Token", valid_594550
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594551 = header.getOrDefault("X-Amz-Target")
  valid_594551 = validateParameter(valid_594551, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_594551 != nil:
    section.add "X-Amz-Target", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Content-Sha256", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Algorithm")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Algorithm", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Signature")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Signature", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-SignedHeaders", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Credential")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Credential", valid_594556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594558: Call_UpdateRulesOfIpGroup_594546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_594558.validator(path, query, header, formData, body)
  let scheme = call_594558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594558.url(scheme.get, call_594558.host, call_594558.base,
                         call_594558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594558, url, valid)

proc call*(call_594559: Call_UpdateRulesOfIpGroup_594546; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_594560 = newJObject()
  if body != nil:
    body_594560 = body
  result = call_594559.call(nil, nil, nil, nil, body_594560)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_594546(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_594547, base: "/",
    url: url_UpdateRulesOfIpGroup_594548, schemes: {Scheme.Https, Scheme.Http})
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
