
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

  OpenApiRestCall_603389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_603389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_603389): Option[Scheme] {.used.} =
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
  Call_AssociateIpGroups_603727 = ref object of OpenApiRestCall_603389
proc url_AssociateIpGroups_603729(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateIpGroups_603728(path: JsonNode; query: JsonNode;
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
  var valid_603854 = header.getOrDefault("X-Amz-Target")
  valid_603854 = validateParameter(valid_603854, JString, required = true, default = newJString(
      "WorkspacesService.AssociateIpGroups"))
  if valid_603854 != nil:
    section.add "X-Amz-Target", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Content-Sha256", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Date")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Date", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Security-Token")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Security-Token", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Algorithm")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Algorithm", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603885: Call_AssociateIpGroups_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified IP access control group with the specified directory.
  ## 
  let valid = call_603885.validator(path, query, header, formData, body)
  let scheme = call_603885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603885.url(scheme.get, call_603885.host, call_603885.base,
                         call_603885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603885, url, valid)

proc call*(call_603956: Call_AssociateIpGroups_603727; body: JsonNode): Recallable =
  ## associateIpGroups
  ## Associates the specified IP access control group with the specified directory.
  ##   body: JObject (required)
  var body_603957 = newJObject()
  if body != nil:
    body_603957 = body
  result = call_603956.call(nil, nil, nil, nil, body_603957)

var associateIpGroups* = Call_AssociateIpGroups_603727(name: "associateIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AssociateIpGroups",
    validator: validate_AssociateIpGroups_603728, base: "/",
    url: url_AssociateIpGroups_603729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AuthorizeIpRules_603996 = ref object of OpenApiRestCall_603389
proc url_AuthorizeIpRules_603998(protocol: Scheme; host: string; base: string;
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

proc validate_AuthorizeIpRules_603997(path: JsonNode; query: JsonNode;
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
  var valid_603999 = header.getOrDefault("X-Amz-Target")
  valid_603999 = validateParameter(valid_603999, JString, required = true, default = newJString(
      "WorkspacesService.AuthorizeIpRules"))
  if valid_603999 != nil:
    section.add "X-Amz-Target", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Signature")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Signature", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Content-Sha256", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Date")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Date", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Credential")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Credential", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Security-Token")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Security-Token", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Algorithm")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Algorithm", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_AuthorizeIpRules_603996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ## 
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604008, url, valid)

proc call*(call_604009: Call_AuthorizeIpRules_603996; body: JsonNode): Recallable =
  ## authorizeIpRules
  ## <p>Adds one or more rules to the specified IP access control group.</p> <p>This action gives users permission to access their WorkSpaces from the CIDR address ranges specified in the rules.</p>
  ##   body: JObject (required)
  var body_604010 = newJObject()
  if body != nil:
    body_604010 = body
  result = call_604009.call(nil, nil, nil, nil, body_604010)

var authorizeIpRules* = Call_AuthorizeIpRules_603996(name: "authorizeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.AuthorizeIpRules",
    validator: validate_AuthorizeIpRules_603997, base: "/",
    url: url_AuthorizeIpRules_603998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyWorkspaceImage_604011 = ref object of OpenApiRestCall_603389
proc url_CopyWorkspaceImage_604013(protocol: Scheme; host: string; base: string;
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

proc validate_CopyWorkspaceImage_604012(path: JsonNode; query: JsonNode;
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
  var valid_604014 = header.getOrDefault("X-Amz-Target")
  valid_604014 = validateParameter(valid_604014, JString, required = true, default = newJString(
      "WorkspacesService.CopyWorkspaceImage"))
  if valid_604014 != nil:
    section.add "X-Amz-Target", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Signature")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Signature", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Content-Sha256", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Date")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Date", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Credential")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Credential", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Security-Token")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Security-Token", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Algorithm")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Algorithm", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-SignedHeaders", valid_604021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604023: Call_CopyWorkspaceImage_604011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified image from the specified Region to the current Region.
  ## 
  let valid = call_604023.validator(path, query, header, formData, body)
  let scheme = call_604023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604023.url(scheme.get, call_604023.host, call_604023.base,
                         call_604023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604023, url, valid)

proc call*(call_604024: Call_CopyWorkspaceImage_604011; body: JsonNode): Recallable =
  ## copyWorkspaceImage
  ## Copies the specified image from the specified Region to the current Region.
  ##   body: JObject (required)
  var body_604025 = newJObject()
  if body != nil:
    body_604025 = body
  result = call_604024.call(nil, nil, nil, nil, body_604025)

var copyWorkspaceImage* = Call_CopyWorkspaceImage_604011(
    name: "copyWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CopyWorkspaceImage",
    validator: validate_CopyWorkspaceImage_604012, base: "/",
    url: url_CopyWorkspaceImage_604013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIpGroup_604026 = ref object of OpenApiRestCall_603389
proc url_CreateIpGroup_604028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIpGroup_604027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604029 = header.getOrDefault("X-Amz-Target")
  valid_604029 = validateParameter(valid_604029, JString, required = true, default = newJString(
      "WorkspacesService.CreateIpGroup"))
  if valid_604029 != nil:
    section.add "X-Amz-Target", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Signature")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Signature", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Content-Sha256", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Date")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Date", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Credential")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Credential", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Security-Token")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Security-Token", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Algorithm")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Algorithm", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-SignedHeaders", valid_604036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604038: Call_CreateIpGroup_604026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ## 
  let valid = call_604038.validator(path, query, header, formData, body)
  let scheme = call_604038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604038.url(scheme.get, call_604038.host, call_604038.base,
                         call_604038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604038, url, valid)

proc call*(call_604039: Call_CreateIpGroup_604026; body: JsonNode): Recallable =
  ## createIpGroup
  ## <p>Creates an IP access control group.</p> <p>An IP access control group provides you with the ability to control the IP addresses from which users are allowed to access their WorkSpaces. To specify the CIDR address ranges, add rules to your IP access control group and then associate the group with your directory. You can add rules when you create the group or at any time using <a>AuthorizeIpRules</a>.</p> <p>There is a default IP access control group associated with your directory. If you don't associate an IP access control group with your directory, the default group is used. The default group includes a default rule that allows users to access their WorkSpaces from anywhere. You cannot modify the default IP access control group for your directory.</p>
  ##   body: JObject (required)
  var body_604040 = newJObject()
  if body != nil:
    body_604040 = body
  result = call_604039.call(nil, nil, nil, nil, body_604040)

var createIpGroup* = Call_CreateIpGroup_604026(name: "createIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateIpGroup",
    validator: validate_CreateIpGroup_604027, base: "/", url: url_CreateIpGroup_604028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_604041 = ref object of OpenApiRestCall_603389
proc url_CreateTags_604043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_604042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604044 = header.getOrDefault("X-Amz-Target")
  valid_604044 = validateParameter(valid_604044, JString, required = true, default = newJString(
      "WorkspacesService.CreateTags"))
  if valid_604044 != nil:
    section.add "X-Amz-Target", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Signature")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Signature", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Content-Sha256", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Date")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Date", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Credential")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Credential", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Security-Token")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Security-Token", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Algorithm")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Algorithm", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-SignedHeaders", valid_604051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604053: Call_CreateTags_604041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_604053.validator(path, query, header, formData, body)
  let scheme = call_604053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604053.url(scheme.get, call_604053.host, call_604053.base,
                         call_604053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604053, url, valid)

proc call*(call_604054: Call_CreateTags_604041; body: JsonNode): Recallable =
  ## createTags
  ## Creates the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_604055 = newJObject()
  if body != nil:
    body_604055 = body
  result = call_604054.call(nil, nil, nil, nil, body_604055)

var createTags* = Call_CreateTags_604041(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.CreateTags",
                                      validator: validate_CreateTags_604042,
                                      base: "/", url: url_CreateTags_604043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkspaces_604056 = ref object of OpenApiRestCall_603389
proc url_CreateWorkspaces_604058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkspaces_604057(path: JsonNode; query: JsonNode;
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
  var valid_604059 = header.getOrDefault("X-Amz-Target")
  valid_604059 = validateParameter(valid_604059, JString, required = true, default = newJString(
      "WorkspacesService.CreateWorkspaces"))
  if valid_604059 != nil:
    section.add "X-Amz-Target", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Signature")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Signature", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Content-Sha256", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Date")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Date", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Credential")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Credential", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Security-Token")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Security-Token", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Algorithm")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Algorithm", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-SignedHeaders", valid_604066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604068: Call_CreateWorkspaces_604056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ## 
  let valid = call_604068.validator(path, query, header, formData, body)
  let scheme = call_604068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604068.url(scheme.get, call_604068.host, call_604068.base,
                         call_604068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604068, url, valid)

proc call*(call_604069: Call_CreateWorkspaces_604056; body: JsonNode): Recallable =
  ## createWorkspaces
  ## <p>Creates one or more WorkSpaces.</p> <p>This operation is asynchronous and returns before the WorkSpaces are created.</p>
  ##   body: JObject (required)
  var body_604070 = newJObject()
  if body != nil:
    body_604070 = body
  result = call_604069.call(nil, nil, nil, nil, body_604070)

var createWorkspaces* = Call_CreateWorkspaces_604056(name: "createWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.CreateWorkspaces",
    validator: validate_CreateWorkspaces_604057, base: "/",
    url: url_CreateWorkspaces_604058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIpGroup_604071 = ref object of OpenApiRestCall_603389
proc url_DeleteIpGroup_604073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIpGroup_604072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604074 = header.getOrDefault("X-Amz-Target")
  valid_604074 = validateParameter(valid_604074, JString, required = true, default = newJString(
      "WorkspacesService.DeleteIpGroup"))
  if valid_604074 != nil:
    section.add "X-Amz-Target", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Signature")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Signature", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Content-Sha256", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Date")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Date", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Credential")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Credential", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Security-Token")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Security-Token", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Algorithm")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Algorithm", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-SignedHeaders", valid_604081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_DeleteIpGroup_604071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ## 
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604083, url, valid)

proc call*(call_604084: Call_DeleteIpGroup_604071; body: JsonNode): Recallable =
  ## deleteIpGroup
  ## <p>Deletes the specified IP access control group.</p> <p>You cannot delete an IP access control group that is associated with a directory.</p>
  ##   body: JObject (required)
  var body_604085 = newJObject()
  if body != nil:
    body_604085 = body
  result = call_604084.call(nil, nil, nil, nil, body_604085)

var deleteIpGroup* = Call_DeleteIpGroup_604071(name: "deleteIpGroup",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteIpGroup",
    validator: validate_DeleteIpGroup_604072, base: "/", url: url_DeleteIpGroup_604073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_604086 = ref object of OpenApiRestCall_603389
proc url_DeleteTags_604088(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_604087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604089 = header.getOrDefault("X-Amz-Target")
  valid_604089 = validateParameter(valid_604089, JString, required = true, default = newJString(
      "WorkspacesService.DeleteTags"))
  if valid_604089 != nil:
    section.add "X-Amz-Target", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Signature")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Signature", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Content-Sha256", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Date")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Date", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Credential")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Credential", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Security-Token")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Security-Token", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Algorithm")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Algorithm", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-SignedHeaders", valid_604096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604098: Call_DeleteTags_604086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ## 
  let valid = call_604098.validator(path, query, header, formData, body)
  let scheme = call_604098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604098.url(scheme.get, call_604098.host, call_604098.base,
                         call_604098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604098, url, valid)

proc call*(call_604099: Call_DeleteTags_604086; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the specified tags from the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_604100 = newJObject()
  if body != nil:
    body_604100 = body
  result = call_604099.call(nil, nil, nil, nil, body_604100)

var deleteTags* = Call_DeleteTags_604086(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DeleteTags",
                                      validator: validate_DeleteTags_604087,
                                      base: "/", url: url_DeleteTags_604088,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkspaceImage_604101 = ref object of OpenApiRestCall_603389
proc url_DeleteWorkspaceImage_604103(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkspaceImage_604102(path: JsonNode; query: JsonNode;
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
  var valid_604104 = header.getOrDefault("X-Amz-Target")
  valid_604104 = validateParameter(valid_604104, JString, required = true, default = newJString(
      "WorkspacesService.DeleteWorkspaceImage"))
  if valid_604104 != nil:
    section.add "X-Amz-Target", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Signature")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Signature", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Content-Sha256", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Date")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Date", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Credential")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Credential", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Security-Token")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Security-Token", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Algorithm")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Algorithm", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-SignedHeaders", valid_604111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604113: Call_DeleteWorkspaceImage_604101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ## 
  let valid = call_604113.validator(path, query, header, formData, body)
  let scheme = call_604113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604113.url(scheme.get, call_604113.host, call_604113.base,
                         call_604113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604113, url, valid)

proc call*(call_604114: Call_DeleteWorkspaceImage_604101; body: JsonNode): Recallable =
  ## deleteWorkspaceImage
  ## Deletes the specified image from your account. To delete an image, you must first delete any bundles that are associated with the image and un-share the image if it is shared with other accounts. 
  ##   body: JObject (required)
  var body_604115 = newJObject()
  if body != nil:
    body_604115 = body
  result = call_604114.call(nil, nil, nil, nil, body_604115)

var deleteWorkspaceImage* = Call_DeleteWorkspaceImage_604101(
    name: "deleteWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeleteWorkspaceImage",
    validator: validate_DeleteWorkspaceImage_604102, base: "/",
    url: url_DeleteWorkspaceImage_604103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterWorkspaceDirectory_604116 = ref object of OpenApiRestCall_603389
proc url_DeregisterWorkspaceDirectory_604118(protocol: Scheme; host: string;
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

proc validate_DeregisterWorkspaceDirectory_604117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604119 = header.getOrDefault("X-Amz-Target")
  valid_604119 = validateParameter(valid_604119, JString, required = true, default = newJString(
      "WorkspacesService.DeregisterWorkspaceDirectory"))
  if valid_604119 != nil:
    section.add "X-Amz-Target", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Signature")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Signature", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Content-Sha256", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Date")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Date", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Credential")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Credential", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Security-Token")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Security-Token", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Algorithm")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Algorithm", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-SignedHeaders", valid_604126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604128: Call_DeregisterWorkspaceDirectory_604116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ## 
  let valid = call_604128.validator(path, query, header, formData, body)
  let scheme = call_604128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604128.url(scheme.get, call_604128.host, call_604128.base,
                         call_604128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604128, url, valid)

proc call*(call_604129: Call_DeregisterWorkspaceDirectory_604116; body: JsonNode): Recallable =
  ## deregisterWorkspaceDirectory
  ## Deregisters the specified directory. This operation is asynchronous and returns before the WorkSpace directory is deregistered. If any WorkSpaces are registered to this directory, you must remove them before you can deregister the directory.
  ##   body: JObject (required)
  var body_604130 = newJObject()
  if body != nil:
    body_604130 = body
  result = call_604129.call(nil, nil, nil, nil, body_604130)

var deregisterWorkspaceDirectory* = Call_DeregisterWorkspaceDirectory_604116(
    name: "deregisterWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DeregisterWorkspaceDirectory",
    validator: validate_DeregisterWorkspaceDirectory_604117, base: "/",
    url: url_DeregisterWorkspaceDirectory_604118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccount_604131 = ref object of OpenApiRestCall_603389
proc url_DescribeAccount_604133(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAccount_604132(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604134 = header.getOrDefault("X-Amz-Target")
  valid_604134 = validateParameter(valid_604134, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccount"))
  if valid_604134 != nil:
    section.add "X-Amz-Target", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-Signature")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Signature", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Content-Sha256", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-Date")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-Date", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Credential")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Credential", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Security-Token")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Security-Token", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Algorithm")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Algorithm", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604143: Call_DescribeAccount_604131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_604143.validator(path, query, header, formData, body)
  let scheme = call_604143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604143.url(scheme.get, call_604143.host, call_604143.base,
                         call_604143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604143, url, valid)

proc call*(call_604144: Call_DescribeAccount_604131; body: JsonNode): Recallable =
  ## describeAccount
  ## Retrieves a list that describes the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_604145 = newJObject()
  if body != nil:
    body_604145 = body
  result = call_604144.call(nil, nil, nil, nil, body_604145)

var describeAccount* = Call_DescribeAccount_604131(name: "describeAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccount",
    validator: validate_DescribeAccount_604132, base: "/", url: url_DescribeAccount_604133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountModifications_604146 = ref object of OpenApiRestCall_603389
proc url_DescribeAccountModifications_604148(protocol: Scheme; host: string;
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

proc validate_DescribeAccountModifications_604147(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604149 = header.getOrDefault("X-Amz-Target")
  valid_604149 = validateParameter(valid_604149, JString, required = true, default = newJString(
      "WorkspacesService.DescribeAccountModifications"))
  if valid_604149 != nil:
    section.add "X-Amz-Target", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Signature")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Signature", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Content-Sha256", valid_604151
  var valid_604152 = header.getOrDefault("X-Amz-Date")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Date", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Credential")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Credential", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Security-Token")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Security-Token", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Algorithm")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Algorithm", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-SignedHeaders", valid_604156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604158: Call_DescribeAccountModifications_604146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_604158.validator(path, query, header, formData, body)
  let scheme = call_604158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604158.url(scheme.get, call_604158.host, call_604158.base,
                         call_604158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604158, url, valid)

proc call*(call_604159: Call_DescribeAccountModifications_604146; body: JsonNode): Recallable =
  ## describeAccountModifications
  ## Retrieves a list that describes modifications to the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_604160 = newJObject()
  if body != nil:
    body_604160 = body
  result = call_604159.call(nil, nil, nil, nil, body_604160)

var describeAccountModifications* = Call_DescribeAccountModifications_604146(
    name: "describeAccountModifications", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeAccountModifications",
    validator: validate_DescribeAccountModifications_604147, base: "/",
    url: url_DescribeAccountModifications_604148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClientProperties_604161 = ref object of OpenApiRestCall_603389
proc url_DescribeClientProperties_604163(protocol: Scheme; host: string;
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

proc validate_DescribeClientProperties_604162(path: JsonNode; query: JsonNode;
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
  var valid_604164 = header.getOrDefault("X-Amz-Target")
  valid_604164 = validateParameter(valid_604164, JString, required = true, default = newJString(
      "WorkspacesService.DescribeClientProperties"))
  if valid_604164 != nil:
    section.add "X-Amz-Target", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Signature")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Signature", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Content-Sha256", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Date")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Date", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Credential")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Credential", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-Security-Token")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Security-Token", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Algorithm")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Algorithm", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-SignedHeaders", valid_604171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604173: Call_DescribeClientProperties_604161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ## 
  let valid = call_604173.validator(path, query, header, formData, body)
  let scheme = call_604173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604173.url(scheme.get, call_604173.host, call_604173.base,
                         call_604173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604173, url, valid)

proc call*(call_604174: Call_DescribeClientProperties_604161; body: JsonNode): Recallable =
  ## describeClientProperties
  ## Retrieves a list that describes one or more specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_604175 = newJObject()
  if body != nil:
    body_604175 = body
  result = call_604174.call(nil, nil, nil, nil, body_604175)

var describeClientProperties* = Call_DescribeClientProperties_604161(
    name: "describeClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeClientProperties",
    validator: validate_DescribeClientProperties_604162, base: "/",
    url: url_DescribeClientProperties_604163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIpGroups_604176 = ref object of OpenApiRestCall_603389
proc url_DescribeIpGroups_604178(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIpGroups_604177(path: JsonNode; query: JsonNode;
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
  var valid_604179 = header.getOrDefault("X-Amz-Target")
  valid_604179 = validateParameter(valid_604179, JString, required = true, default = newJString(
      "WorkspacesService.DescribeIpGroups"))
  if valid_604179 != nil:
    section.add "X-Amz-Target", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Signature")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Signature", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Content-Sha256", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Date")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Date", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Credential")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Credential", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Security-Token")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Security-Token", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Algorithm")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Algorithm", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-SignedHeaders", valid_604186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604188: Call_DescribeIpGroups_604176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your IP access control groups.
  ## 
  let valid = call_604188.validator(path, query, header, formData, body)
  let scheme = call_604188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604188.url(scheme.get, call_604188.host, call_604188.base,
                         call_604188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604188, url, valid)

proc call*(call_604189: Call_DescribeIpGroups_604176; body: JsonNode): Recallable =
  ## describeIpGroups
  ## Describes one or more of your IP access control groups.
  ##   body: JObject (required)
  var body_604190 = newJObject()
  if body != nil:
    body_604190 = body
  result = call_604189.call(nil, nil, nil, nil, body_604190)

var describeIpGroups* = Call_DescribeIpGroups_604176(name: "describeIpGroups",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeIpGroups",
    validator: validate_DescribeIpGroups_604177, base: "/",
    url: url_DescribeIpGroups_604178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_604191 = ref object of OpenApiRestCall_603389
proc url_DescribeTags_604193(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_604192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604194 = header.getOrDefault("X-Amz-Target")
  valid_604194 = validateParameter(valid_604194, JString, required = true, default = newJString(
      "WorkspacesService.DescribeTags"))
  if valid_604194 != nil:
    section.add "X-Amz-Target", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Signature")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Signature", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Content-Sha256", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Date")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Date", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Credential")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Credential", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Security-Token")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Security-Token", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Algorithm")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Algorithm", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-SignedHeaders", valid_604201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604203: Call_DescribeTags_604191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified tags for the specified WorkSpaces resource.
  ## 
  let valid = call_604203.validator(path, query, header, formData, body)
  let scheme = call_604203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604203.url(scheme.get, call_604203.host, call_604203.base,
                         call_604203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604203, url, valid)

proc call*(call_604204: Call_DescribeTags_604191; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the specified tags for the specified WorkSpaces resource.
  ##   body: JObject (required)
  var body_604205 = newJObject()
  if body != nil:
    body_604205 = body
  result = call_604204.call(nil, nil, nil, nil, body_604205)

var describeTags* = Call_DescribeTags_604191(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeTags",
    validator: validate_DescribeTags_604192, base: "/", url: url_DescribeTags_604193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceBundles_604206 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspaceBundles_604208(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceBundles_604207(path: JsonNode; query: JsonNode;
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
  var valid_604209 = query.getOrDefault("NextToken")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "NextToken", valid_604209
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
  var valid_604210 = header.getOrDefault("X-Amz-Target")
  valid_604210 = validateParameter(valid_604210, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceBundles"))
  if valid_604210 != nil:
    section.add "X-Amz-Target", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Signature")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Signature", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Content-Sha256", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Date")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Date", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Credential")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Credential", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Security-Token")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Security-Token", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Algorithm")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Algorithm", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-SignedHeaders", valid_604217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604219: Call_DescribeWorkspaceBundles_604206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ## 
  let valid = call_604219.validator(path, query, header, formData, body)
  let scheme = call_604219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604219.url(scheme.get, call_604219.host, call_604219.base,
                         call_604219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604219, url, valid)

proc call*(call_604220: Call_DescribeWorkspaceBundles_604206; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceBundles
  ## <p>Retrieves a list that describes the available WorkSpace bundles.</p> <p>You can filter the results using either bundle ID or owner, but not both.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_604221 = newJObject()
  var body_604222 = newJObject()
  add(query_604221, "NextToken", newJString(NextToken))
  if body != nil:
    body_604222 = body
  result = call_604220.call(nil, query_604221, nil, nil, body_604222)

var describeWorkspaceBundles* = Call_DescribeWorkspaceBundles_604206(
    name: "describeWorkspaceBundles", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceBundles",
    validator: validate_DescribeWorkspaceBundles_604207, base: "/",
    url: url_DescribeWorkspaceBundles_604208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceDirectories_604224 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspaceDirectories_604226(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceDirectories_604225(path: JsonNode; query: JsonNode;
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
  var valid_604227 = query.getOrDefault("NextToken")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "NextToken", valid_604227
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
  var valid_604228 = header.getOrDefault("X-Amz-Target")
  valid_604228 = validateParameter(valid_604228, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceDirectories"))
  if valid_604228 != nil:
    section.add "X-Amz-Target", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Signature")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Signature", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Content-Sha256", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Date")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Date", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Credential")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Credential", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Security-Token")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Security-Token", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Algorithm")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Algorithm", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-SignedHeaders", valid_604235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604237: Call_DescribeWorkspaceDirectories_604224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ## 
  let valid = call_604237.validator(path, query, header, formData, body)
  let scheme = call_604237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604237.url(scheme.get, call_604237.host, call_604237.base,
                         call_604237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604237, url, valid)

proc call*(call_604238: Call_DescribeWorkspaceDirectories_604224; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## describeWorkspaceDirectories
  ## Describes the available directories that are registered with Amazon WorkSpaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_604239 = newJObject()
  var body_604240 = newJObject()
  add(query_604239, "NextToken", newJString(NextToken))
  if body != nil:
    body_604240 = body
  result = call_604238.call(nil, query_604239, nil, nil, body_604240)

var describeWorkspaceDirectories* = Call_DescribeWorkspaceDirectories_604224(
    name: "describeWorkspaceDirectories", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceDirectories",
    validator: validate_DescribeWorkspaceDirectories_604225, base: "/",
    url: url_DescribeWorkspaceDirectories_604226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceImages_604241 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspaceImages_604243(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaceImages_604242(path: JsonNode; query: JsonNode;
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
  var valid_604244 = header.getOrDefault("X-Amz-Target")
  valid_604244 = validateParameter(valid_604244, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceImages"))
  if valid_604244 != nil:
    section.add "X-Amz-Target", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Signature")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Signature", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Content-Sha256", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Date")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Date", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Credential")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Credential", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Security-Token")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Security-Token", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Algorithm")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Algorithm", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-SignedHeaders", valid_604251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604253: Call_DescribeWorkspaceImages_604241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ## 
  let valid = call_604253.validator(path, query, header, formData, body)
  let scheme = call_604253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604253.url(scheme.get, call_604253.host, call_604253.base,
                         call_604253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604253, url, valid)

proc call*(call_604254: Call_DescribeWorkspaceImages_604241; body: JsonNode): Recallable =
  ## describeWorkspaceImages
  ## Retrieves a list that describes one or more specified images, if the image identifiers are provided. Otherwise, all images in the account are described. 
  ##   body: JObject (required)
  var body_604255 = newJObject()
  if body != nil:
    body_604255 = body
  result = call_604254.call(nil, nil, nil, nil, body_604255)

var describeWorkspaceImages* = Call_DescribeWorkspaceImages_604241(
    name: "describeWorkspaceImages", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceImages",
    validator: validate_DescribeWorkspaceImages_604242, base: "/",
    url: url_DescribeWorkspaceImages_604243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaceSnapshots_604256 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspaceSnapshots_604258(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspaceSnapshots_604257(path: JsonNode; query: JsonNode;
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
  var valid_604259 = header.getOrDefault("X-Amz-Target")
  valid_604259 = validateParameter(valid_604259, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaceSnapshots"))
  if valid_604259 != nil:
    section.add "X-Amz-Target", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Signature")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Signature", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Content-Sha256", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Date")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Date", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Credential")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Credential", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Security-Token")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Security-Token", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Algorithm")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Algorithm", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-SignedHeaders", valid_604266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604268: Call_DescribeWorkspaceSnapshots_604256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the snapshots for the specified WorkSpace.
  ## 
  let valid = call_604268.validator(path, query, header, formData, body)
  let scheme = call_604268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604268.url(scheme.get, call_604268.host, call_604268.base,
                         call_604268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604268, url, valid)

proc call*(call_604269: Call_DescribeWorkspaceSnapshots_604256; body: JsonNode): Recallable =
  ## describeWorkspaceSnapshots
  ## Describes the snapshots for the specified WorkSpace.
  ##   body: JObject (required)
  var body_604270 = newJObject()
  if body != nil:
    body_604270 = body
  result = call_604269.call(nil, nil, nil, nil, body_604270)

var describeWorkspaceSnapshots* = Call_DescribeWorkspaceSnapshots_604256(
    name: "describeWorkspaceSnapshots", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaceSnapshots",
    validator: validate_DescribeWorkspaceSnapshots_604257, base: "/",
    url: url_DescribeWorkspaceSnapshots_604258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspaces_604271 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspaces_604273(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkspaces_604272(path: JsonNode; query: JsonNode;
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
  var valid_604274 = query.getOrDefault("NextToken")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "NextToken", valid_604274
  var valid_604275 = query.getOrDefault("Limit")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "Limit", valid_604275
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
  var valid_604276 = header.getOrDefault("X-Amz-Target")
  valid_604276 = validateParameter(valid_604276, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspaces"))
  if valid_604276 != nil:
    section.add "X-Amz-Target", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Signature")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Signature", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Content-Sha256", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Date")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Date", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Credential")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Credential", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Security-Token")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Security-Token", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Algorithm")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Algorithm", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-SignedHeaders", valid_604283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604285: Call_DescribeWorkspaces_604271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ## 
  let valid = call_604285.validator(path, query, header, formData, body)
  let scheme = call_604285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604285.url(scheme.get, call_604285.host, call_604285.base,
                         call_604285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604285, url, valid)

proc call*(call_604286: Call_DescribeWorkspaces_604271; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeWorkspaces
  ## <p>Describes the specified WorkSpaces.</p> <p>You can filter the results by using the bundle identifier, directory identifier, or owner, but you can specify only one filter at a time.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_604287 = newJObject()
  var body_604288 = newJObject()
  add(query_604287, "NextToken", newJString(NextToken))
  add(query_604287, "Limit", newJString(Limit))
  if body != nil:
    body_604288 = body
  result = call_604286.call(nil, query_604287, nil, nil, body_604288)

var describeWorkspaces* = Call_DescribeWorkspaces_604271(
    name: "describeWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspaces",
    validator: validate_DescribeWorkspaces_604272, base: "/",
    url: url_DescribeWorkspaces_604273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkspacesConnectionStatus_604289 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkspacesConnectionStatus_604291(protocol: Scheme; host: string;
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

proc validate_DescribeWorkspacesConnectionStatus_604290(path: JsonNode;
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
  var valid_604292 = header.getOrDefault("X-Amz-Target")
  valid_604292 = validateParameter(valid_604292, JString, required = true, default = newJString(
      "WorkspacesService.DescribeWorkspacesConnectionStatus"))
  if valid_604292 != nil:
    section.add "X-Amz-Target", valid_604292
  var valid_604293 = header.getOrDefault("X-Amz-Signature")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "X-Amz-Signature", valid_604293
  var valid_604294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "X-Amz-Content-Sha256", valid_604294
  var valid_604295 = header.getOrDefault("X-Amz-Date")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "X-Amz-Date", valid_604295
  var valid_604296 = header.getOrDefault("X-Amz-Credential")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Credential", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Security-Token")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Security-Token", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Algorithm")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Algorithm", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-SignedHeaders", valid_604299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604301: Call_DescribeWorkspacesConnectionStatus_604289;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the connection status of the specified WorkSpaces.
  ## 
  let valid = call_604301.validator(path, query, header, formData, body)
  let scheme = call_604301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604301.url(scheme.get, call_604301.host, call_604301.base,
                         call_604301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604301, url, valid)

proc call*(call_604302: Call_DescribeWorkspacesConnectionStatus_604289;
          body: JsonNode): Recallable =
  ## describeWorkspacesConnectionStatus
  ## Describes the connection status of the specified WorkSpaces.
  ##   body: JObject (required)
  var body_604303 = newJObject()
  if body != nil:
    body_604303 = body
  result = call_604302.call(nil, nil, nil, nil, body_604303)

var describeWorkspacesConnectionStatus* = Call_DescribeWorkspacesConnectionStatus_604289(
    name: "describeWorkspacesConnectionStatus", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.DescribeWorkspacesConnectionStatus",
    validator: validate_DescribeWorkspacesConnectionStatus_604290, base: "/",
    url: url_DescribeWorkspacesConnectionStatus_604291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateIpGroups_604304 = ref object of OpenApiRestCall_603389
proc url_DisassociateIpGroups_604306(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateIpGroups_604305(path: JsonNode; query: JsonNode;
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
  var valid_604307 = header.getOrDefault("X-Amz-Target")
  valid_604307 = validateParameter(valid_604307, JString, required = true, default = newJString(
      "WorkspacesService.DisassociateIpGroups"))
  if valid_604307 != nil:
    section.add "X-Amz-Target", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-Signature")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Signature", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Content-Sha256", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Date")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Date", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-Credential")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Credential", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Security-Token")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Security-Token", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Algorithm")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Algorithm", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-SignedHeaders", valid_604314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604316: Call_DisassociateIpGroups_604304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified IP access control group from the specified directory.
  ## 
  let valid = call_604316.validator(path, query, header, formData, body)
  let scheme = call_604316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604316.url(scheme.get, call_604316.host, call_604316.base,
                         call_604316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604316, url, valid)

proc call*(call_604317: Call_DisassociateIpGroups_604304; body: JsonNode): Recallable =
  ## disassociateIpGroups
  ## Disassociates the specified IP access control group from the specified directory.
  ##   body: JObject (required)
  var body_604318 = newJObject()
  if body != nil:
    body_604318 = body
  result = call_604317.call(nil, nil, nil, nil, body_604318)

var disassociateIpGroups* = Call_DisassociateIpGroups_604304(
    name: "disassociateIpGroups", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.DisassociateIpGroups",
    validator: validate_DisassociateIpGroups_604305, base: "/",
    url: url_DisassociateIpGroups_604306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportWorkspaceImage_604319 = ref object of OpenApiRestCall_603389
proc url_ImportWorkspaceImage_604321(protocol: Scheme; host: string; base: string;
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

proc validate_ImportWorkspaceImage_604320(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604322 = header.getOrDefault("X-Amz-Target")
  valid_604322 = validateParameter(valid_604322, JString, required = true, default = newJString(
      "WorkspacesService.ImportWorkspaceImage"))
  if valid_604322 != nil:
    section.add "X-Amz-Target", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Signature")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Signature", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Content-Sha256", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Date")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Date", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-Credential")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-Credential", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Security-Token")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Security-Token", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Algorithm")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Algorithm", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-SignedHeaders", valid_604329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604331: Call_ImportWorkspaceImage_604319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ## 
  let valid = call_604331.validator(path, query, header, formData, body)
  let scheme = call_604331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604331.url(scheme.get, call_604331.host, call_604331.base,
                         call_604331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604331, url, valid)

proc call*(call_604332: Call_ImportWorkspaceImage_604319; body: JsonNode): Recallable =
  ## importWorkspaceImage
  ## Imports the specified Windows 7 or Windows 10 Bring Your Own License (BYOL) image into Amazon WorkSpaces. The image must be an already licensed EC2 image that is in your AWS account, and you must own the image. 
  ##   body: JObject (required)
  var body_604333 = newJObject()
  if body != nil:
    body_604333 = body
  result = call_604332.call(nil, nil, nil, nil, body_604333)

var importWorkspaceImage* = Call_ImportWorkspaceImage_604319(
    name: "importWorkspaceImage", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ImportWorkspaceImage",
    validator: validate_ImportWorkspaceImage_604320, base: "/",
    url: url_ImportWorkspaceImage_604321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagementCidrRanges_604334 = ref object of OpenApiRestCall_603389
proc url_ListAvailableManagementCidrRanges_604336(protocol: Scheme; host: string;
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

proc validate_ListAvailableManagementCidrRanges_604335(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604337 = header.getOrDefault("X-Amz-Target")
  valid_604337 = validateParameter(valid_604337, JString, required = true, default = newJString(
      "WorkspacesService.ListAvailableManagementCidrRanges"))
  if valid_604337 != nil:
    section.add "X-Amz-Target", valid_604337
  var valid_604338 = header.getOrDefault("X-Amz-Signature")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "X-Amz-Signature", valid_604338
  var valid_604339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Content-Sha256", valid_604339
  var valid_604340 = header.getOrDefault("X-Amz-Date")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amz-Date", valid_604340
  var valid_604341 = header.getOrDefault("X-Amz-Credential")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "X-Amz-Credential", valid_604341
  var valid_604342 = header.getOrDefault("X-Amz-Security-Token")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Security-Token", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Algorithm")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Algorithm", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-SignedHeaders", valid_604344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604346: Call_ListAvailableManagementCidrRanges_604334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ## 
  let valid = call_604346.validator(path, query, header, formData, body)
  let scheme = call_604346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604346.url(scheme.get, call_604346.host, call_604346.base,
                         call_604346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604346, url, valid)

proc call*(call_604347: Call_ListAvailableManagementCidrRanges_604334;
          body: JsonNode): Recallable =
  ## listAvailableManagementCidrRanges
  ## <p>Retrieves a list of IP address ranges, specified as IPv4 CIDR blocks, that you can use for the network management interface when you enable Bring Your Own License (BYOL). </p> <p>The management network interface is connected to a secure Amazon WorkSpaces management network. It is used for interactive streaming of the WorkSpace desktop to Amazon WorkSpaces clients, and to allow Amazon WorkSpaces to manage the WorkSpace.</p>
  ##   body: JObject (required)
  var body_604348 = newJObject()
  if body != nil:
    body_604348 = body
  result = call_604347.call(nil, nil, nil, nil, body_604348)

var listAvailableManagementCidrRanges* = Call_ListAvailableManagementCidrRanges_604334(
    name: "listAvailableManagementCidrRanges", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ListAvailableManagementCidrRanges",
    validator: validate_ListAvailableManagementCidrRanges_604335, base: "/",
    url: url_ListAvailableManagementCidrRanges_604336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MigrateWorkspace_604349 = ref object of OpenApiRestCall_603389
proc url_MigrateWorkspace_604351(protocol: Scheme; host: string; base: string;
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

proc validate_MigrateWorkspace_604350(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604352 = header.getOrDefault("X-Amz-Target")
  valid_604352 = validateParameter(valid_604352, JString, required = true, default = newJString(
      "WorkspacesService.MigrateWorkspace"))
  if valid_604352 != nil:
    section.add "X-Amz-Target", valid_604352
  var valid_604353 = header.getOrDefault("X-Amz-Signature")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Signature", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Content-Sha256", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Date")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Date", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Credential")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Credential", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Security-Token")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Security-Token", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Algorithm")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Algorithm", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-SignedHeaders", valid_604359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604361: Call_MigrateWorkspace_604349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ## 
  let valid = call_604361.validator(path, query, header, formData, body)
  let scheme = call_604361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604361.url(scheme.get, call_604361.host, call_604361.base,
                         call_604361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604361, url, valid)

proc call*(call_604362: Call_MigrateWorkspace_604349; body: JsonNode): Recallable =
  ## migrateWorkspace
  ## <p>Migrates a WorkSpace from one operating system or bundle type to another, while retaining the data on the user volume.</p> <p>The migration process recreates the WorkSpace by using a new root volume from the target bundle image and the user volume from the last available snapshot of the original WorkSpace. During migration, the original <code>D:\Users\%USERNAME%</code> user profile folder is renamed to <code>D:\Users\%USERNAME%MMddyyTHHmmss%.NotMigrated</code>. A new <code>D:\Users\%USERNAME%\</code> folder is generated by the new OS. Certain files in the old user profile are moved to the new user profile.</p> <p>For available migration scenarios, details about what happens during migration, and best practices, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/migrate-workspaces.html">Migrate a WorkSpace</a>.</p>
  ##   body: JObject (required)
  var body_604363 = newJObject()
  if body != nil:
    body_604363 = body
  result = call_604362.call(nil, nil, nil, nil, body_604363)

var migrateWorkspace* = Call_MigrateWorkspace_604349(name: "migrateWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.MigrateWorkspace",
    validator: validate_MigrateWorkspace_604350, base: "/",
    url: url_MigrateWorkspace_604351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyAccount_604364 = ref object of OpenApiRestCall_603389
proc url_ModifyAccount_604366(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyAccount_604365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604367 = header.getOrDefault("X-Amz-Target")
  valid_604367 = validateParameter(valid_604367, JString, required = true, default = newJString(
      "WorkspacesService.ModifyAccount"))
  if valid_604367 != nil:
    section.add "X-Amz-Target", valid_604367
  var valid_604368 = header.getOrDefault("X-Amz-Signature")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Signature", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Content-Sha256", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Date")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Date", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Credential")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Credential", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Security-Token")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Security-Token", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-Algorithm")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-Algorithm", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-SignedHeaders", valid_604374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604376: Call_ModifyAccount_604364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ## 
  let valid = call_604376.validator(path, query, header, formData, body)
  let scheme = call_604376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604376.url(scheme.get, call_604376.host, call_604376.base,
                         call_604376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604376, url, valid)

proc call*(call_604377: Call_ModifyAccount_604364; body: JsonNode): Recallable =
  ## modifyAccount
  ## Modifies the configuration of Bring Your Own License (BYOL) for the specified account.
  ##   body: JObject (required)
  var body_604378 = newJObject()
  if body != nil:
    body_604378 = body
  result = call_604377.call(nil, nil, nil, nil, body_604378)

var modifyAccount* = Call_ModifyAccount_604364(name: "modifyAccount",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyAccount",
    validator: validate_ModifyAccount_604365, base: "/", url: url_ModifyAccount_604366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyClientProperties_604379 = ref object of OpenApiRestCall_603389
proc url_ModifyClientProperties_604381(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyClientProperties_604380(path: JsonNode; query: JsonNode;
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
  var valid_604382 = header.getOrDefault("X-Amz-Target")
  valid_604382 = validateParameter(valid_604382, JString, required = true, default = newJString(
      "WorkspacesService.ModifyClientProperties"))
  if valid_604382 != nil:
    section.add "X-Amz-Target", valid_604382
  var valid_604383 = header.getOrDefault("X-Amz-Signature")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "X-Amz-Signature", valid_604383
  var valid_604384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "X-Amz-Content-Sha256", valid_604384
  var valid_604385 = header.getOrDefault("X-Amz-Date")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "X-Amz-Date", valid_604385
  var valid_604386 = header.getOrDefault("X-Amz-Credential")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-Credential", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Security-Token")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Security-Token", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Algorithm")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Algorithm", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-SignedHeaders", valid_604389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604391: Call_ModifyClientProperties_604379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ## 
  let valid = call_604391.validator(path, query, header, formData, body)
  let scheme = call_604391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604391.url(scheme.get, call_604391.host, call_604391.base,
                         call_604391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604391, url, valid)

proc call*(call_604392: Call_ModifyClientProperties_604379; body: JsonNode): Recallable =
  ## modifyClientProperties
  ## Modifies the properties of the specified Amazon WorkSpaces clients.
  ##   body: JObject (required)
  var body_604393 = newJObject()
  if body != nil:
    body_604393 = body
  result = call_604392.call(nil, nil, nil, nil, body_604393)

var modifyClientProperties* = Call_ModifyClientProperties_604379(
    name: "modifyClientProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyClientProperties",
    validator: validate_ModifyClientProperties_604380, base: "/",
    url: url_ModifyClientProperties_604381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifySelfservicePermissions_604394 = ref object of OpenApiRestCall_603389
proc url_ModifySelfservicePermissions_604396(protocol: Scheme; host: string;
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

proc validate_ModifySelfservicePermissions_604395(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604397 = header.getOrDefault("X-Amz-Target")
  valid_604397 = validateParameter(valid_604397, JString, required = true, default = newJString(
      "WorkspacesService.ModifySelfservicePermissions"))
  if valid_604397 != nil:
    section.add "X-Amz-Target", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Signature")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Signature", valid_604398
  var valid_604399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-Content-Sha256", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Date")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Date", valid_604400
  var valid_604401 = header.getOrDefault("X-Amz-Credential")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Credential", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Security-Token")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Security-Token", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Algorithm")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Algorithm", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-SignedHeaders", valid_604404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604406: Call_ModifySelfservicePermissions_604394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ## 
  let valid = call_604406.validator(path, query, header, formData, body)
  let scheme = call_604406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604406.url(scheme.get, call_604406.host, call_604406.base,
                         call_604406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604406, url, valid)

proc call*(call_604407: Call_ModifySelfservicePermissions_604394; body: JsonNode): Recallable =
  ## modifySelfservicePermissions
  ## Modifies the self-service WorkSpace management capabilities for your users. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html">Enable Self-Service WorkSpace Management Capabilities for Your Users</a>.
  ##   body: JObject (required)
  var body_604408 = newJObject()
  if body != nil:
    body_604408 = body
  result = call_604407.call(nil, nil, nil, nil, body_604408)

var modifySelfservicePermissions* = Call_ModifySelfservicePermissions_604394(
    name: "modifySelfservicePermissions", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifySelfservicePermissions",
    validator: validate_ModifySelfservicePermissions_604395, base: "/",
    url: url_ModifySelfservicePermissions_604396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceAccessProperties_604409 = ref object of OpenApiRestCall_603389
proc url_ModifyWorkspaceAccessProperties_604411(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceAccessProperties_604410(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604412 = header.getOrDefault("X-Amz-Target")
  valid_604412 = validateParameter(valid_604412, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceAccessProperties"))
  if valid_604412 != nil:
    section.add "X-Amz-Target", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-Signature")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-Signature", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Content-Sha256", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-Date")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-Date", valid_604415
  var valid_604416 = header.getOrDefault("X-Amz-Credential")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-Credential", valid_604416
  var valid_604417 = header.getOrDefault("X-Amz-Security-Token")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Security-Token", valid_604417
  var valid_604418 = header.getOrDefault("X-Amz-Algorithm")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "X-Amz-Algorithm", valid_604418
  var valid_604419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "X-Amz-SignedHeaders", valid_604419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604421: Call_ModifyWorkspaceAccessProperties_604409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ## 
  let valid = call_604421.validator(path, query, header, formData, body)
  let scheme = call_604421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604421.url(scheme.get, call_604421.host, call_604421.base,
                         call_604421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604421, url, valid)

proc call*(call_604422: Call_ModifyWorkspaceAccessProperties_604409; body: JsonNode): Recallable =
  ## modifyWorkspaceAccessProperties
  ## Specifies which devices and operating systems users can use to access their WorkSpaces. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/update-directory-details.html#control-device-access"> Control Device Access</a>.
  ##   body: JObject (required)
  var body_604423 = newJObject()
  if body != nil:
    body_604423 = body
  result = call_604422.call(nil, nil, nil, nil, body_604423)

var modifyWorkspaceAccessProperties* = Call_ModifyWorkspaceAccessProperties_604409(
    name: "modifyWorkspaceAccessProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceAccessProperties",
    validator: validate_ModifyWorkspaceAccessProperties_604410, base: "/",
    url: url_ModifyWorkspaceAccessProperties_604411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceCreationProperties_604424 = ref object of OpenApiRestCall_603389
proc url_ModifyWorkspaceCreationProperties_604426(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceCreationProperties_604425(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604427 = header.getOrDefault("X-Amz-Target")
  valid_604427 = validateParameter(valid_604427, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceCreationProperties"))
  if valid_604427 != nil:
    section.add "X-Amz-Target", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Signature")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Signature", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Content-Sha256", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Date")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Date", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Credential")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Credential", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Security-Token")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Security-Token", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Algorithm")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Algorithm", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-SignedHeaders", valid_604434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604436: Call_ModifyWorkspaceCreationProperties_604424;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modify the default properties used to create WorkSpaces.
  ## 
  let valid = call_604436.validator(path, query, header, formData, body)
  let scheme = call_604436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604436.url(scheme.get, call_604436.host, call_604436.base,
                         call_604436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604436, url, valid)

proc call*(call_604437: Call_ModifyWorkspaceCreationProperties_604424;
          body: JsonNode): Recallable =
  ## modifyWorkspaceCreationProperties
  ## Modify the default properties used to create WorkSpaces.
  ##   body: JObject (required)
  var body_604438 = newJObject()
  if body != nil:
    body_604438 = body
  result = call_604437.call(nil, nil, nil, nil, body_604438)

var modifyWorkspaceCreationProperties* = Call_ModifyWorkspaceCreationProperties_604424(
    name: "modifyWorkspaceCreationProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com", route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceCreationProperties",
    validator: validate_ModifyWorkspaceCreationProperties_604425, base: "/",
    url: url_ModifyWorkspaceCreationProperties_604426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceProperties_604439 = ref object of OpenApiRestCall_603389
proc url_ModifyWorkspaceProperties_604441(protocol: Scheme; host: string;
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

proc validate_ModifyWorkspaceProperties_604440(path: JsonNode; query: JsonNode;
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
  var valid_604442 = header.getOrDefault("X-Amz-Target")
  valid_604442 = validateParameter(valid_604442, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceProperties"))
  if valid_604442 != nil:
    section.add "X-Amz-Target", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Signature")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Signature", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Content-Sha256", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Date")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Date", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-Credential")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Credential", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Security-Token")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Security-Token", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Algorithm")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Algorithm", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-SignedHeaders", valid_604449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604451: Call_ModifyWorkspaceProperties_604439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified WorkSpace properties.
  ## 
  let valid = call_604451.validator(path, query, header, formData, body)
  let scheme = call_604451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604451.url(scheme.get, call_604451.host, call_604451.base,
                         call_604451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604451, url, valid)

proc call*(call_604452: Call_ModifyWorkspaceProperties_604439; body: JsonNode): Recallable =
  ## modifyWorkspaceProperties
  ## Modifies the specified WorkSpace properties.
  ##   body: JObject (required)
  var body_604453 = newJObject()
  if body != nil:
    body_604453 = body
  result = call_604452.call(nil, nil, nil, nil, body_604453)

var modifyWorkspaceProperties* = Call_ModifyWorkspaceProperties_604439(
    name: "modifyWorkspaceProperties", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceProperties",
    validator: validate_ModifyWorkspaceProperties_604440, base: "/",
    url: url_ModifyWorkspaceProperties_604441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyWorkspaceState_604454 = ref object of OpenApiRestCall_603389
proc url_ModifyWorkspaceState_604456(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyWorkspaceState_604455(path: JsonNode; query: JsonNode;
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
  var valid_604457 = header.getOrDefault("X-Amz-Target")
  valid_604457 = validateParameter(valid_604457, JString, required = true, default = newJString(
      "WorkspacesService.ModifyWorkspaceState"))
  if valid_604457 != nil:
    section.add "X-Amz-Target", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Signature")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Signature", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Content-Sha256", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Date")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Date", valid_604460
  var valid_604461 = header.getOrDefault("X-Amz-Credential")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-Credential", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Security-Token")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Security-Token", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Algorithm")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Algorithm", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-SignedHeaders", valid_604464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604466: Call_ModifyWorkspaceState_604454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ## 
  let valid = call_604466.validator(path, query, header, formData, body)
  let scheme = call_604466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604466.url(scheme.get, call_604466.host, call_604466.base,
                         call_604466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604466, url, valid)

proc call*(call_604467: Call_ModifyWorkspaceState_604454; body: JsonNode): Recallable =
  ## modifyWorkspaceState
  ## <p>Sets the state of the specified WorkSpace.</p> <p>To maintain a WorkSpace without being interrupted, set the WorkSpace state to <code>ADMIN_MAINTENANCE</code>. WorkSpaces in this state do not respond to requests to reboot, stop, start, rebuild, or restore. An AutoStop WorkSpace in this state is not stopped. Users cannot log into a WorkSpace in the <code>ADMIN_MAINTENANCE</code> state.</p>
  ##   body: JObject (required)
  var body_604468 = newJObject()
  if body != nil:
    body_604468 = body
  result = call_604467.call(nil, nil, nil, nil, body_604468)

var modifyWorkspaceState* = Call_ModifyWorkspaceState_604454(
    name: "modifyWorkspaceState", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.ModifyWorkspaceState",
    validator: validate_ModifyWorkspaceState_604455, base: "/",
    url: url_ModifyWorkspaceState_604456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootWorkspaces_604469 = ref object of OpenApiRestCall_603389
proc url_RebootWorkspaces_604471(protocol: Scheme; host: string; base: string;
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

proc validate_RebootWorkspaces_604470(path: JsonNode; query: JsonNode;
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
  var valid_604472 = header.getOrDefault("X-Amz-Target")
  valid_604472 = validateParameter(valid_604472, JString, required = true, default = newJString(
      "WorkspacesService.RebootWorkspaces"))
  if valid_604472 != nil:
    section.add "X-Amz-Target", valid_604472
  var valid_604473 = header.getOrDefault("X-Amz-Signature")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "X-Amz-Signature", valid_604473
  var valid_604474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-Content-Sha256", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Date")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Date", valid_604475
  var valid_604476 = header.getOrDefault("X-Amz-Credential")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-Credential", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Security-Token")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Security-Token", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Algorithm")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Algorithm", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-SignedHeaders", valid_604479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604481: Call_RebootWorkspaces_604469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ## 
  let valid = call_604481.validator(path, query, header, formData, body)
  let scheme = call_604481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604481.url(scheme.get, call_604481.host, call_604481.base,
                         call_604481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604481, url, valid)

proc call*(call_604482: Call_RebootWorkspaces_604469; body: JsonNode): Recallable =
  ## rebootWorkspaces
  ## <p>Reboots the specified WorkSpaces.</p> <p>You cannot reboot a WorkSpace unless its state is <code>AVAILABLE</code> or <code>UNHEALTHY</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have rebooted.</p>
  ##   body: JObject (required)
  var body_604483 = newJObject()
  if body != nil:
    body_604483 = body
  result = call_604482.call(nil, nil, nil, nil, body_604483)

var rebootWorkspaces* = Call_RebootWorkspaces_604469(name: "rebootWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebootWorkspaces",
    validator: validate_RebootWorkspaces_604470, base: "/",
    url: url_RebootWorkspaces_604471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebuildWorkspaces_604484 = ref object of OpenApiRestCall_603389
proc url_RebuildWorkspaces_604486(protocol: Scheme; host: string; base: string;
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

proc validate_RebuildWorkspaces_604485(path: JsonNode; query: JsonNode;
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
  var valid_604487 = header.getOrDefault("X-Amz-Target")
  valid_604487 = validateParameter(valid_604487, JString, required = true, default = newJString(
      "WorkspacesService.RebuildWorkspaces"))
  if valid_604487 != nil:
    section.add "X-Amz-Target", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Signature")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Signature", valid_604488
  var valid_604489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-Content-Sha256", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Date")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Date", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-Credential")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-Credential", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-Security-Token")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Security-Token", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Algorithm")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Algorithm", valid_604493
  var valid_604494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-SignedHeaders", valid_604494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604496: Call_RebuildWorkspaces_604484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ## 
  let valid = call_604496.validator(path, query, header, formData, body)
  let scheme = call_604496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604496.url(scheme.get, call_604496.host, call_604496.base,
                         call_604496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604496, url, valid)

proc call*(call_604497: Call_RebuildWorkspaces_604484; body: JsonNode): Recallable =
  ## rebuildWorkspaces
  ## <p>Rebuilds the specified WorkSpace.</p> <p>You cannot rebuild a WorkSpace unless its state is <code>AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Rebuilding a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/reset-workspace.html">Rebuild a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely rebuilt.</p>
  ##   body: JObject (required)
  var body_604498 = newJObject()
  if body != nil:
    body_604498 = body
  result = call_604497.call(nil, nil, nil, nil, body_604498)

var rebuildWorkspaces* = Call_RebuildWorkspaces_604484(name: "rebuildWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RebuildWorkspaces",
    validator: validate_RebuildWorkspaces_604485, base: "/",
    url: url_RebuildWorkspaces_604486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWorkspaceDirectory_604499 = ref object of OpenApiRestCall_603389
proc url_RegisterWorkspaceDirectory_604501(protocol: Scheme; host: string;
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

proc validate_RegisterWorkspaceDirectory_604500(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604502 = header.getOrDefault("X-Amz-Target")
  valid_604502 = validateParameter(valid_604502, JString, required = true, default = newJString(
      "WorkspacesService.RegisterWorkspaceDirectory"))
  if valid_604502 != nil:
    section.add "X-Amz-Target", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Signature")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Signature", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Content-Sha256", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Date")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Date", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Credential")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Credential", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-Security-Token")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Security-Token", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Algorithm")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Algorithm", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-SignedHeaders", valid_604509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604511: Call_RegisterWorkspaceDirectory_604499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ## 
  let valid = call_604511.validator(path, query, header, formData, body)
  let scheme = call_604511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604511.url(scheme.get, call_604511.host, call_604511.base,
                         call_604511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604511, url, valid)

proc call*(call_604512: Call_RegisterWorkspaceDirectory_604499; body: JsonNode): Recallable =
  ## registerWorkspaceDirectory
  ## Registers the specified directory. This operation is asynchronous and returns before the WorkSpace directory is registered. If this is the first time you are registering a directory, you will need to create the workspaces_DefaultRole role before you can register a directory. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-access-control.html#create-default-role"> Creating the workspaces_DefaultRole Role</a>.
  ##   body: JObject (required)
  var body_604513 = newJObject()
  if body != nil:
    body_604513 = body
  result = call_604512.call(nil, nil, nil, nil, body_604513)

var registerWorkspaceDirectory* = Call_RegisterWorkspaceDirectory_604499(
    name: "registerWorkspaceDirectory", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RegisterWorkspaceDirectory",
    validator: validate_RegisterWorkspaceDirectory_604500, base: "/",
    url: url_RegisterWorkspaceDirectory_604501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreWorkspace_604514 = ref object of OpenApiRestCall_603389
proc url_RestoreWorkspace_604516(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreWorkspace_604515(path: JsonNode; query: JsonNode;
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
  var valid_604517 = header.getOrDefault("X-Amz-Target")
  valid_604517 = validateParameter(valid_604517, JString, required = true, default = newJString(
      "WorkspacesService.RestoreWorkspace"))
  if valid_604517 != nil:
    section.add "X-Amz-Target", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-Signature")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Signature", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Content-Sha256", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Date")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Date", valid_604520
  var valid_604521 = header.getOrDefault("X-Amz-Credential")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "X-Amz-Credential", valid_604521
  var valid_604522 = header.getOrDefault("X-Amz-Security-Token")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Security-Token", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-Algorithm")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Algorithm", valid_604523
  var valid_604524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-SignedHeaders", valid_604524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604526: Call_RestoreWorkspace_604514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ## 
  let valid = call_604526.validator(path, query, header, formData, body)
  let scheme = call_604526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604526.url(scheme.get, call_604526.host, call_604526.base,
                         call_604526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604526, url, valid)

proc call*(call_604527: Call_RestoreWorkspace_604514; body: JsonNode): Recallable =
  ## restoreWorkspace
  ## <p>Restores the specified WorkSpace to its last known healthy state.</p> <p>You cannot restore a WorkSpace unless its state is <code> AVAILABLE</code>, <code>ERROR</code>, or <code>UNHEALTHY</code>.</p> <p>Restoring a WorkSpace is a potentially destructive action that can result in the loss of data. For more information, see <a href="https://docs.aws.amazon.com/workspaces/latest/adminguide/restore-workspace.html">Restore a WorkSpace</a>.</p> <p>This operation is asynchronous and returns before the WorkSpace is completely restored.</p>
  ##   body: JObject (required)
  var body_604528 = newJObject()
  if body != nil:
    body_604528 = body
  result = call_604527.call(nil, nil, nil, nil, body_604528)

var restoreWorkspace* = Call_RestoreWorkspace_604514(name: "restoreWorkspace",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RestoreWorkspace",
    validator: validate_RestoreWorkspace_604515, base: "/",
    url: url_RestoreWorkspace_604516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeIpRules_604529 = ref object of OpenApiRestCall_603389
proc url_RevokeIpRules_604531(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeIpRules_604530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604532 = header.getOrDefault("X-Amz-Target")
  valid_604532 = validateParameter(valid_604532, JString, required = true, default = newJString(
      "WorkspacesService.RevokeIpRules"))
  if valid_604532 != nil:
    section.add "X-Amz-Target", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Signature")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Signature", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Content-Sha256", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Date")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Date", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Credential")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Credential", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Security-Token")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Security-Token", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Algorithm")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Algorithm", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-SignedHeaders", valid_604539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604541: Call_RevokeIpRules_604529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more rules from the specified IP access control group.
  ## 
  let valid = call_604541.validator(path, query, header, formData, body)
  let scheme = call_604541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604541.url(scheme.get, call_604541.host, call_604541.base,
                         call_604541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604541, url, valid)

proc call*(call_604542: Call_RevokeIpRules_604529; body: JsonNode): Recallable =
  ## revokeIpRules
  ## Removes one or more rules from the specified IP access control group.
  ##   body: JObject (required)
  var body_604543 = newJObject()
  if body != nil:
    body_604543 = body
  result = call_604542.call(nil, nil, nil, nil, body_604543)

var revokeIpRules* = Call_RevokeIpRules_604529(name: "revokeIpRules",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.RevokeIpRules",
    validator: validate_RevokeIpRules_604530, base: "/", url: url_RevokeIpRules_604531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkspaces_604544 = ref object of OpenApiRestCall_603389
proc url_StartWorkspaces_604546(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkspaces_604545(path: JsonNode; query: JsonNode;
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
  var valid_604547 = header.getOrDefault("X-Amz-Target")
  valid_604547 = validateParameter(valid_604547, JString, required = true, default = newJString(
      "WorkspacesService.StartWorkspaces"))
  if valid_604547 != nil:
    section.add "X-Amz-Target", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Signature")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Signature", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Content-Sha256", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Date")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Date", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Credential")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Credential", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Security-Token")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Security-Token", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Algorithm")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Algorithm", valid_604553
  var valid_604554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-SignedHeaders", valid_604554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604556: Call_StartWorkspaces_604544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ## 
  let valid = call_604556.validator(path, query, header, formData, body)
  let scheme = call_604556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604556.url(scheme.get, call_604556.host, call_604556.base,
                         call_604556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604556, url, valid)

proc call*(call_604557: Call_StartWorkspaces_604544; body: JsonNode): Recallable =
  ## startWorkspaces
  ## <p>Starts the specified WorkSpaces.</p> <p>You cannot start a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>STOPPED</code>.</p>
  ##   body: JObject (required)
  var body_604558 = newJObject()
  if body != nil:
    body_604558 = body
  result = call_604557.call(nil, nil, nil, nil, body_604558)

var startWorkspaces* = Call_StartWorkspaces_604544(name: "startWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StartWorkspaces",
    validator: validate_StartWorkspaces_604545, base: "/", url: url_StartWorkspaces_604546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopWorkspaces_604559 = ref object of OpenApiRestCall_603389
proc url_StopWorkspaces_604561(protocol: Scheme; host: string; base: string;
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

proc validate_StopWorkspaces_604560(path: JsonNode; query: JsonNode;
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
  var valid_604562 = header.getOrDefault("X-Amz-Target")
  valid_604562 = validateParameter(valid_604562, JString, required = true, default = newJString(
      "WorkspacesService.StopWorkspaces"))
  if valid_604562 != nil:
    section.add "X-Amz-Target", valid_604562
  var valid_604563 = header.getOrDefault("X-Amz-Signature")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Signature", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-Content-Sha256", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Date")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Date", valid_604565
  var valid_604566 = header.getOrDefault("X-Amz-Credential")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "X-Amz-Credential", valid_604566
  var valid_604567 = header.getOrDefault("X-Amz-Security-Token")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "X-Amz-Security-Token", valid_604567
  var valid_604568 = header.getOrDefault("X-Amz-Algorithm")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "X-Amz-Algorithm", valid_604568
  var valid_604569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604569 = validateParameter(valid_604569, JString, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "X-Amz-SignedHeaders", valid_604569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604571: Call_StopWorkspaces_604559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ## 
  let valid = call_604571.validator(path, query, header, formData, body)
  let scheme = call_604571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604571.url(scheme.get, call_604571.host, call_604571.base,
                         call_604571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604571, url, valid)

proc call*(call_604572: Call_StopWorkspaces_604559; body: JsonNode): Recallable =
  ## stopWorkspaces
  ## <p> Stops the specified WorkSpaces.</p> <p>You cannot stop a WorkSpace unless it has a running mode of <code>AutoStop</code> and a state of <code>AVAILABLE</code>, <code>IMPAIRED</code>, <code>UNHEALTHY</code>, or <code>ERROR</code>.</p>
  ##   body: JObject (required)
  var body_604573 = newJObject()
  if body != nil:
    body_604573 = body
  result = call_604572.call(nil, nil, nil, nil, body_604573)

var stopWorkspaces* = Call_StopWorkspaces_604559(name: "stopWorkspaces",
    meth: HttpMethod.HttpPost, host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.StopWorkspaces",
    validator: validate_StopWorkspaces_604560, base: "/", url: url_StopWorkspaces_604561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkspaces_604574 = ref object of OpenApiRestCall_603389
proc url_TerminateWorkspaces_604576(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateWorkspaces_604575(path: JsonNode; query: JsonNode;
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
  var valid_604577 = header.getOrDefault("X-Amz-Target")
  valid_604577 = validateParameter(valid_604577, JString, required = true, default = newJString(
      "WorkspacesService.TerminateWorkspaces"))
  if valid_604577 != nil:
    section.add "X-Amz-Target", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-Signature")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Signature", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Content-Sha256", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Date")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Date", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-Credential")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Credential", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Security-Token")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Security-Token", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-Algorithm")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Algorithm", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-SignedHeaders", valid_604584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604586: Call_TerminateWorkspaces_604574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ## 
  let valid = call_604586.validator(path, query, header, formData, body)
  let scheme = call_604586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604586.url(scheme.get, call_604586.host, call_604586.base,
                         call_604586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604586, url, valid)

proc call*(call_604587: Call_TerminateWorkspaces_604574; body: JsonNode): Recallable =
  ## terminateWorkspaces
  ## <p>Terminates the specified WorkSpaces.</p> <p>Terminating a WorkSpace is a permanent action and cannot be undone. The user's data is destroyed. If you need to archive any user data, contact Amazon Web Services before terminating the WorkSpace.</p> <p>You can terminate a WorkSpace that is in any state except <code>SUSPENDED</code>.</p> <p>This operation is asynchronous and returns before the WorkSpaces have been completely terminated.</p>
  ##   body: JObject (required)
  var body_604588 = newJObject()
  if body != nil:
    body_604588 = body
  result = call_604587.call(nil, nil, nil, nil, body_604588)

var terminateWorkspaces* = Call_TerminateWorkspaces_604574(
    name: "terminateWorkspaces", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.TerminateWorkspaces",
    validator: validate_TerminateWorkspaces_604575, base: "/",
    url: url_TerminateWorkspaces_604576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRulesOfIpGroup_604589 = ref object of OpenApiRestCall_603389
proc url_UpdateRulesOfIpGroup_604591(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRulesOfIpGroup_604590(path: JsonNode; query: JsonNode;
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
  var valid_604592 = header.getOrDefault("X-Amz-Target")
  valid_604592 = validateParameter(valid_604592, JString, required = true, default = newJString(
      "WorkspacesService.UpdateRulesOfIpGroup"))
  if valid_604592 != nil:
    section.add "X-Amz-Target", valid_604592
  var valid_604593 = header.getOrDefault("X-Amz-Signature")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-Signature", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Content-Sha256", valid_604594
  var valid_604595 = header.getOrDefault("X-Amz-Date")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "X-Amz-Date", valid_604595
  var valid_604596 = header.getOrDefault("X-Amz-Credential")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-Credential", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Security-Token")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Security-Token", valid_604597
  var valid_604598 = header.getOrDefault("X-Amz-Algorithm")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Algorithm", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-SignedHeaders", valid_604599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604601: Call_UpdateRulesOfIpGroup_604589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ## 
  let valid = call_604601.validator(path, query, header, formData, body)
  let scheme = call_604601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604601.url(scheme.get, call_604601.host, call_604601.base,
                         call_604601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604601, url, valid)

proc call*(call_604602: Call_UpdateRulesOfIpGroup_604589; body: JsonNode): Recallable =
  ## updateRulesOfIpGroup
  ## Replaces the current rules of the specified IP access control group with the specified rules.
  ##   body: JObject (required)
  var body_604603 = newJObject()
  if body != nil:
    body_604603 = body
  result = call_604602.call(nil, nil, nil, nil, body_604603)

var updateRulesOfIpGroup* = Call_UpdateRulesOfIpGroup_604589(
    name: "updateRulesOfIpGroup", meth: HttpMethod.HttpPost,
    host: "workspaces.amazonaws.com",
    route: "/#X-Amz-Target=WorkspacesService.UpdateRulesOfIpGroup",
    validator: validate_UpdateRulesOfIpGroup_604590, base: "/",
    url: url_UpdateRulesOfIpGroup_604591, schemes: {Scheme.Https, Scheme.Http})
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
