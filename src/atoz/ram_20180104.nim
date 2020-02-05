
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Access Manager
## version: 2018-01-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Use AWS Resource Access Manager to share AWS resources between AWS accounts. To share a resource, you create a resource share, associate the resource with the resource share, and specify the principals that can access the resources associated with the resource share. The following principals are supported: AWS accounts, organizational units (OU) from AWS Organizations, and organizations from AWS Organizations.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/ram/latest/userguide/">AWS Resource Access Manager User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ram/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ram.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ram.us-west-2.amazonaws.com",
                           "eu-west-2": "ram.eu-west-2.amazonaws.com", "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ram.eu-central-1.amazonaws.com",
                           "us-east-2": "ram.us-east-2.amazonaws.com",
                           "us-east-1": "ram.us-east-1.amazonaws.com", "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ram.ap-south-1.amazonaws.com",
                           "eu-north-1": "ram.eu-north-1.amazonaws.com", "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ram.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ram.eu-west-3.amazonaws.com",
                           "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ram.sa-east-1.amazonaws.com",
                           "eu-west-1": "ram.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ram.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
      "us-west-2": "ram.us-west-2.amazonaws.com",
      "eu-west-2": "ram.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ram.eu-central-1.amazonaws.com",
      "us-east-2": "ram.us-east-2.amazonaws.com",
      "us-east-1": "ram.us-east-1.amazonaws.com",
      "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ram.ap-south-1.amazonaws.com",
      "eu-north-1": "ram.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
      "us-west-1": "ram.us-west-1.amazonaws.com",
      "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ram.eu-west-3.amazonaws.com",
      "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ram.sa-east-1.amazonaws.com",
      "eu-west-1": "ram.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ram"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptResourceShareInvitation_612996 = ref object of OpenApiRestCall_612658
proc url_AcceptResourceShareInvitation_612998(protocol: Scheme; host: string;
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

proc validate_AcceptResourceShareInvitation_612997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Accepts an invitation to a resource share from another AWS account.
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
  var valid_613110 = header.getOrDefault("X-Amz-Signature")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Signature", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Content-Sha256", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Date")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Date", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Credential")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Credential", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Security-Token")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Security-Token", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Algorithm")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Algorithm", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-SignedHeaders", valid_613116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_AcceptResourceShareInvitation_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_AcceptResourceShareInvitation_612996; body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_613212 = newJObject()
  if body != nil:
    body_613212 = body
  result = call_613211.call(nil, nil, nil, nil, body_613212)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_612996(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_612997, base: "/",
    url: url_AcceptResourceShareInvitation_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_613251 = ref object of OpenApiRestCall_612658
proc url_AssociateResourceShare_613253(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateResourceShare_613252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified resource share with the specified principals and resources.
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
  var valid_613254 = header.getOrDefault("X-Amz-Signature")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Signature", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Content-Sha256", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Date")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Date", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Credential")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Credential", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Security-Token")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Security-Token", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Algorithm")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Algorithm", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-SignedHeaders", valid_613260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613262: Call_AssociateResourceShare_613251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_613262.validator(path, query, header, formData, body)
  let scheme = call_613262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613262.url(scheme.get, call_613262.host, call_613262.base,
                         call_613262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613262, url, valid)

proc call*(call_613263: Call_AssociateResourceShare_613251; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_613264 = newJObject()
  if body != nil:
    body_613264 = body
  result = call_613263.call(nil, nil, nil, nil, body_613264)

var associateResourceShare* = Call_AssociateResourceShare_613251(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_613252, base: "/",
    url: url_AssociateResourceShare_613253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceSharePermission_613265 = ref object of OpenApiRestCall_612658
proc url_AssociateResourceSharePermission_613267(protocol: Scheme; host: string;
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

proc validate_AssociateResourceSharePermission_613266(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a permission with a resource share.
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
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_AssociateResourceSharePermission_613265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a permission with a resource share.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_AssociateResourceSharePermission_613265;
          body: JsonNode): Recallable =
  ## associateResourceSharePermission
  ## Associates a permission with a resource share.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var associateResourceSharePermission* = Call_AssociateResourceSharePermission_613265(
    name: "associateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourcesharepermission",
    validator: validate_AssociateResourceSharePermission_613266, base: "/",
    url: url_AssociateResourceSharePermission_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_613279 = ref object of OpenApiRestCall_612658
proc url_CreateResourceShare_613281(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceShare_613280(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a resource share.
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
  var valid_613282 = header.getOrDefault("X-Amz-Signature")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Signature", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Content-Sha256", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Date")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Date", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Credential")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Credential", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Security-Token")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Security-Token", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Algorithm")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Algorithm", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-SignedHeaders", valid_613288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613290: Call_CreateResourceShare_613279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_613290.validator(path, query, header, formData, body)
  let scheme = call_613290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613290.url(scheme.get, call_613290.host, call_613290.base,
                         call_613290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613290, url, valid)

proc call*(call_613291: Call_CreateResourceShare_613279; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_613292 = newJObject()
  if body != nil:
    body_613292 = body
  result = call_613291.call(nil, nil, nil, nil, body_613292)

var createResourceShare* = Call_CreateResourceShare_613279(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_613280, base: "/",
    url: url_CreateResourceShare_613281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_613293 = ref object of OpenApiRestCall_612658
proc url_DeleteResourceShare_613295(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceShare_613294(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the specified resource share.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  ##   resourceShareArn: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  section = newJObject()
  var valid_613296 = query.getOrDefault("clientToken")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "clientToken", valid_613296
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_613297 = query.getOrDefault("resourceShareArn")
  valid_613297 = validateParameter(valid_613297, JString, required = true,
                                 default = nil)
  if valid_613297 != nil:
    section.add "resourceShareArn", valid_613297
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
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613305: Call_DeleteResourceShare_613293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_613305.validator(path, query, header, formData, body)
  let scheme = call_613305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613305.url(scheme.get, call_613305.host, call_613305.base,
                         call_613305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613305, url, valid)

proc call*(call_613306: Call_DeleteResourceShare_613293; resourceShareArn: string;
          clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  var query_613307 = newJObject()
  add(query_613307, "clientToken", newJString(clientToken))
  add(query_613307, "resourceShareArn", newJString(resourceShareArn))
  result = call_613306.call(nil, query_613307, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_613293(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_613294, base: "/",
    url: url_DeleteResourceShare_613295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_613309 = ref object of OpenApiRestCall_612658
proc url_DisassociateResourceShare_613311(protocol: Scheme; host: string;
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

proc validate_DisassociateResourceShare_613310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified principals or resources from the specified resource share.
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
  var valid_613312 = header.getOrDefault("X-Amz-Signature")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Signature", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Content-Sha256", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Date")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Date", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Credential")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Credential", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Security-Token")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Security-Token", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Algorithm")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Algorithm", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-SignedHeaders", valid_613318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613320: Call_DisassociateResourceShare_613309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_613320.validator(path, query, header, formData, body)
  let scheme = call_613320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613320.url(scheme.get, call_613320.host, call_613320.base,
                         call_613320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613320, url, valid)

proc call*(call_613321: Call_DisassociateResourceShare_613309; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_613322 = newJObject()
  if body != nil:
    body_613322 = body
  result = call_613321.call(nil, nil, nil, nil, body_613322)

var disassociateResourceShare* = Call_DisassociateResourceShare_613309(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_613310, base: "/",
    url: url_DisassociateResourceShare_613311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceSharePermission_613323 = ref object of OpenApiRestCall_612658
proc url_DisassociateResourceSharePermission_613325(protocol: Scheme; host: string;
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

proc validate_DisassociateResourceSharePermission_613324(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates an AWS RAM permission from a resource share.
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
  var valid_613326 = header.getOrDefault("X-Amz-Signature")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Signature", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Content-Sha256", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Date")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Date", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Credential")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Credential", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Security-Token")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Security-Token", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Algorithm")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Algorithm", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-SignedHeaders", valid_613332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613334: Call_DisassociateResourceSharePermission_613323;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates an AWS RAM permission from a resource share.
  ## 
  let valid = call_613334.validator(path, query, header, formData, body)
  let scheme = call_613334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613334.url(scheme.get, call_613334.host, call_613334.base,
                         call_613334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613334, url, valid)

proc call*(call_613335: Call_DisassociateResourceSharePermission_613323;
          body: JsonNode): Recallable =
  ## disassociateResourceSharePermission
  ## Disassociates an AWS RAM permission from a resource share.
  ##   body: JObject (required)
  var body_613336 = newJObject()
  if body != nil:
    body_613336 = body
  result = call_613335.call(nil, nil, nil, nil, body_613336)

var disassociateResourceSharePermission* = Call_DisassociateResourceSharePermission_613323(
    name: "disassociateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourcesharepermission",
    validator: validate_DisassociateResourceSharePermission_613324, base: "/",
    url: url_DisassociateResourceSharePermission_613325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_613337 = ref object of OpenApiRestCall_612658
proc url_EnableSharingWithAwsOrganization_613339(protocol: Scheme; host: string;
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

proc validate_EnableSharingWithAwsOrganization_613338(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
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
  var valid_613340 = header.getOrDefault("X-Amz-Signature")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Signature", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Content-Sha256", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Date")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Date", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Credential")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Credential", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Security-Token")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Security-Token", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Algorithm")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Algorithm", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-SignedHeaders", valid_613346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613347: Call_EnableSharingWithAwsOrganization_613337;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  ## 
  let valid = call_613347.validator(path, query, header, formData, body)
  let scheme = call_613347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613347.url(scheme.get, call_613347.host, call_613347.base,
                         call_613347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613347, url, valid)

proc call*(call_613348: Call_EnableSharingWithAwsOrganization_613337): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_613348.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_613337(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_613338, base: "/",
    url: url_EnableSharingWithAwsOrganization_613339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermission_613349 = ref object of OpenApiRestCall_612658
proc url_GetPermission_613351(protocol: Scheme; host: string; base: string;
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

proc validate_GetPermission_613350(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the contents of an AWS RAM permission in JSON format.
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
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_GetPermission_613349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of an AWS RAM permission in JSON format.
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_GetPermission_613349; body: JsonNode): Recallable =
  ## getPermission
  ## Gets the contents of an AWS RAM permission in JSON format.
  ##   body: JObject (required)
  var body_613362 = newJObject()
  if body != nil:
    body_613362 = body
  result = call_613361.call(nil, nil, nil, nil, body_613362)

var getPermission* = Call_GetPermission_613349(name: "getPermission",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/getpermission",
    validator: validate_GetPermission_613350, base: "/", url: url_GetPermission_613351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_613363 = ref object of OpenApiRestCall_612658
proc url_GetResourcePolicies_613365(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicies_613364(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613366 = query.getOrDefault("nextToken")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "nextToken", valid_613366
  var valid_613367 = query.getOrDefault("maxResults")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "maxResults", valid_613367
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
  var valid_613368 = header.getOrDefault("X-Amz-Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Signature", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Content-Sha256", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Date")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Date", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Credential")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Credential", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Security-Token")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Security-Token", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Algorithm")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Algorithm", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-SignedHeaders", valid_613374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613376: Call_GetResourcePolicies_613363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  let valid = call_613376.validator(path, query, header, formData, body)
  let scheme = call_613376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613376.url(scheme.get, call_613376.host, call_613376.base,
                         call_613376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613376, url, valid)

proc call*(call_613377: Call_GetResourcePolicies_613363; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613378 = newJObject()
  var body_613379 = newJObject()
  add(query_613378, "nextToken", newJString(nextToken))
  if body != nil:
    body_613379 = body
  add(query_613378, "maxResults", newJString(maxResults))
  result = call_613377.call(nil, query_613378, nil, nil, body_613379)

var getResourcePolicies* = Call_GetResourcePolicies_613363(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_613364, base: "/",
    url: url_GetResourcePolicies_613365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_613380 = ref object of OpenApiRestCall_612658
proc url_GetResourceShareAssociations_613382(protocol: Scheme; host: string;
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

proc validate_GetResourceShareAssociations_613381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613383 = query.getOrDefault("nextToken")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "nextToken", valid_613383
  var valid_613384 = query.getOrDefault("maxResults")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "maxResults", valid_613384
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
  var valid_613385 = header.getOrDefault("X-Amz-Signature")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Signature", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Content-Sha256", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Date")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Date", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Credential")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Credential", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Security-Token")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Security-Token", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Algorithm")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Algorithm", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-SignedHeaders", valid_613391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613393: Call_GetResourceShareAssociations_613380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  let valid = call_613393.validator(path, query, header, formData, body)
  let scheme = call_613393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613393.url(scheme.get, call_613393.host, call_613393.base,
                         call_613393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613393, url, valid)

proc call*(call_613394: Call_GetResourceShareAssociations_613380; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613395 = newJObject()
  var body_613396 = newJObject()
  add(query_613395, "nextToken", newJString(nextToken))
  if body != nil:
    body_613396 = body
  add(query_613395, "maxResults", newJString(maxResults))
  result = call_613394.call(nil, query_613395, nil, nil, body_613396)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_613380(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_613381, base: "/",
    url: url_GetResourceShareAssociations_613382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_613397 = ref object of OpenApiRestCall_612658
proc url_GetResourceShareInvitations_613399(protocol: Scheme; host: string;
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

proc validate_GetResourceShareInvitations_613398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613400 = query.getOrDefault("nextToken")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "nextToken", valid_613400
  var valid_613401 = query.getOrDefault("maxResults")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "maxResults", valid_613401
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
  var valid_613402 = header.getOrDefault("X-Amz-Signature")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Signature", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Content-Sha256", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Date")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Date", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Credential")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Credential", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Security-Token")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Security-Token", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Algorithm")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Algorithm", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-SignedHeaders", valid_613408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613410: Call_GetResourceShareInvitations_613397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  let valid = call_613410.validator(path, query, header, formData, body)
  let scheme = call_613410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613410.url(scheme.get, call_613410.host, call_613410.base,
                         call_613410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613410, url, valid)

proc call*(call_613411: Call_GetResourceShareInvitations_613397; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613412 = newJObject()
  var body_613413 = newJObject()
  add(query_613412, "nextToken", newJString(nextToken))
  if body != nil:
    body_613413 = body
  add(query_613412, "maxResults", newJString(maxResults))
  result = call_613411.call(nil, query_613412, nil, nil, body_613413)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_613397(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_613398, base: "/",
    url: url_GetResourceShareInvitations_613399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_613414 = ref object of OpenApiRestCall_612658
proc url_GetResourceShares_613416(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceShares_613415(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613417 = query.getOrDefault("nextToken")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "nextToken", valid_613417
  var valid_613418 = query.getOrDefault("maxResults")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "maxResults", valid_613418
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

proc call*(call_613427: Call_GetResourceShares_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_GetResourceShares_613414; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613429 = newJObject()
  var body_613430 = newJObject()
  add(query_613429, "nextToken", newJString(nextToken))
  if body != nil:
    body_613430 = body
  add(query_613429, "maxResults", newJString(maxResults))
  result = call_613428.call(nil, query_613429, nil, nil, body_613430)

var getResourceShares* = Call_GetResourceShares_613414(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_613415,
    base: "/", url: url_GetResourceShares_613416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_613431 = ref object of OpenApiRestCall_612658
proc url_ListPendingInvitationResources_613433(protocol: Scheme; host: string;
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

proc validate_ListPendingInvitationResources_613432(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613434 = query.getOrDefault("nextToken")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "nextToken", valid_613434
  var valid_613435 = query.getOrDefault("maxResults")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "maxResults", valid_613435
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
  var valid_613436 = header.getOrDefault("X-Amz-Signature")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Signature", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Content-Sha256", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Date")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Date", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Credential")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Credential", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Security-Token")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Security-Token", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Algorithm")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Algorithm", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-SignedHeaders", valid_613442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613444: Call_ListPendingInvitationResources_613431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  let valid = call_613444.validator(path, query, header, formData, body)
  let scheme = call_613444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613444.url(scheme.get, call_613444.host, call_613444.base,
                         call_613444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613444, url, valid)

proc call*(call_613445: Call_ListPendingInvitationResources_613431; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613446 = newJObject()
  var body_613447 = newJObject()
  add(query_613446, "nextToken", newJString(nextToken))
  if body != nil:
    body_613447 = body
  add(query_613446, "maxResults", newJString(maxResults))
  result = call_613445.call(nil, query_613446, nil, nil, body_613447)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_613431(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_613432, base: "/",
    url: url_ListPendingInvitationResources_613433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_613448 = ref object of OpenApiRestCall_612658
proc url_ListPermissions_613450(protocol: Scheme; host: string; base: string;
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

proc validate_ListPermissions_613449(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the AWS RAM permissions.
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
  var valid_613451 = header.getOrDefault("X-Amz-Signature")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Signature", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Content-Sha256", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Date")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Date", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Credential")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Credential", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Security-Token")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Security-Token", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Algorithm")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Algorithm", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-SignedHeaders", valid_613457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613459: Call_ListPermissions_613448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS RAM permissions.
  ## 
  let valid = call_613459.validator(path, query, header, formData, body)
  let scheme = call_613459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613459.url(scheme.get, call_613459.host, call_613459.base,
                         call_613459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613459, url, valid)

proc call*(call_613460: Call_ListPermissions_613448; body: JsonNode): Recallable =
  ## listPermissions
  ## Lists the AWS RAM permissions.
  ##   body: JObject (required)
  var body_613461 = newJObject()
  if body != nil:
    body_613461 = body
  result = call_613460.call(nil, nil, nil, nil, body_613461)

var listPermissions* = Call_ListPermissions_613448(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listpermissions",
    validator: validate_ListPermissions_613449, base: "/", url: url_ListPermissions_613450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_613462 = ref object of OpenApiRestCall_612658
proc url_ListPrincipals_613464(protocol: Scheme; host: string; base: string;
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

proc validate_ListPrincipals_613463(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613465 = query.getOrDefault("nextToken")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "nextToken", valid_613465
  var valid_613466 = query.getOrDefault("maxResults")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "maxResults", valid_613466
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
  var valid_613467 = header.getOrDefault("X-Amz-Signature")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Signature", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Content-Sha256", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Date")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Date", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Credential")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Credential", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Security-Token")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Security-Token", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Algorithm")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Algorithm", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-SignedHeaders", valid_613473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613475: Call_ListPrincipals_613462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ## 
  let valid = call_613475.validator(path, query, header, formData, body)
  let scheme = call_613475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613475.url(scheme.get, call_613475.host, call_613475.base,
                         call_613475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613475, url, valid)

proc call*(call_613476: Call_ListPrincipals_613462; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613477 = newJObject()
  var body_613478 = newJObject()
  add(query_613477, "nextToken", newJString(nextToken))
  if body != nil:
    body_613478 = body
  add(query_613477, "maxResults", newJString(maxResults))
  result = call_613476.call(nil, query_613477, nil, nil, body_613478)

var listPrincipals* = Call_ListPrincipals_613462(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_613463, base: "/", url: url_ListPrincipals_613464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceSharePermissions_613479 = ref object of OpenApiRestCall_612658
proc url_ListResourceSharePermissions_613481(protocol: Scheme; host: string;
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

proc validate_ListResourceSharePermissions_613480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the AWS RAM permissions that are associated with a resource share.
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
  var valid_613482 = header.getOrDefault("X-Amz-Signature")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Signature", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Content-Sha256", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Date")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Date", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Credential")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Credential", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Security-Token")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Security-Token", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Algorithm")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Algorithm", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-SignedHeaders", valid_613488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613490: Call_ListResourceSharePermissions_613479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ## 
  let valid = call_613490.validator(path, query, header, formData, body)
  let scheme = call_613490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613490.url(scheme.get, call_613490.host, call_613490.base,
                         call_613490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613490, url, valid)

proc call*(call_613491: Call_ListResourceSharePermissions_613479; body: JsonNode): Recallable =
  ## listResourceSharePermissions
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ##   body: JObject (required)
  var body_613492 = newJObject()
  if body != nil:
    body_613492 = body
  result = call_613491.call(nil, nil, nil, nil, body_613492)

var listResourceSharePermissions* = Call_ListResourceSharePermissions_613479(
    name: "listResourceSharePermissions", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listresourcesharepermissions",
    validator: validate_ListResourceSharePermissions_613480, base: "/",
    url: url_ListResourceSharePermissions_613481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_613493 = ref object of OpenApiRestCall_612658
proc url_ListResources_613495(protocol: Scheme; host: string; base: string;
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

proc validate_ListResources_613494(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613496 = query.getOrDefault("nextToken")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "nextToken", valid_613496
  var valid_613497 = query.getOrDefault("maxResults")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "maxResults", valid_613497
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

proc call*(call_613506: Call_ListResources_613493; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  let valid = call_613506.validator(path, query, header, formData, body)
  let scheme = call_613506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613506.url(scheme.get, call_613506.host, call_613506.base,
                         call_613506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613506, url, valid)

proc call*(call_613507: Call_ListResources_613493; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613508 = newJObject()
  var body_613509 = newJObject()
  add(query_613508, "nextToken", newJString(nextToken))
  if body != nil:
    body_613509 = body
  add(query_613508, "maxResults", newJString(maxResults))
  result = call_613507.call(nil, query_613508, nil, nil, body_613509)

var listResources* = Call_ListResources_613493(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_613494, base: "/", url: url_ListResources_613495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PromoteResourceShareCreatedFromPolicy_613510 = ref object of OpenApiRestCall_612658
proc url_PromoteResourceShareCreatedFromPolicy_613512(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PromoteResourceShareCreatedFromPolicy_613511(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
  ##                   : The ARN of the resource share to promote.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_613513 = query.getOrDefault("resourceShareArn")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = nil)
  if valid_613513 != nil:
    section.add "resourceShareArn", valid_613513
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
  if body != nil:
    result.add "body", body

proc call*(call_613521: Call_PromoteResourceShareCreatedFromPolicy_613510;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ## 
  let valid = call_613521.validator(path, query, header, formData, body)
  let scheme = call_613521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613521.url(scheme.get, call_613521.host, call_613521.base,
                         call_613521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613521, url, valid)

proc call*(call_613522: Call_PromoteResourceShareCreatedFromPolicy_613510;
          resourceShareArn: string): Recallable =
  ## promoteResourceShareCreatedFromPolicy
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ##   resourceShareArn: string (required)
  ##                   : The ARN of the resource share to promote.
  var query_613523 = newJObject()
  add(query_613523, "resourceShareArn", newJString(resourceShareArn))
  result = call_613522.call(nil, query_613523, nil, nil, nil)

var promoteResourceShareCreatedFromPolicy* = Call_PromoteResourceShareCreatedFromPolicy_613510(
    name: "promoteResourceShareCreatedFromPolicy", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com",
    route: "/promoteresourcesharecreatedfrompolicy#resourceShareArn",
    validator: validate_PromoteResourceShareCreatedFromPolicy_613511, base: "/",
    url: url_PromoteResourceShareCreatedFromPolicy_613512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_613524 = ref object of OpenApiRestCall_612658
proc url_RejectResourceShareInvitation_613526(protocol: Scheme; host: string;
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

proc validate_RejectResourceShareInvitation_613525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rejects an invitation to a resource share from another AWS account.
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
  var valid_613527 = header.getOrDefault("X-Amz-Signature")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Signature", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Content-Sha256", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Date")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Date", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Credential")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Credential", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Security-Token")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Security-Token", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Algorithm")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Algorithm", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-SignedHeaders", valid_613533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613535: Call_RejectResourceShareInvitation_613524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_613535.validator(path, query, header, formData, body)
  let scheme = call_613535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613535.url(scheme.get, call_613535.host, call_613535.base,
                         call_613535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613535, url, valid)

proc call*(call_613536: Call_RejectResourceShareInvitation_613524; body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_613537 = newJObject()
  if body != nil:
    body_613537 = body
  result = call_613536.call(nil, nil, nil, nil, body_613537)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_613524(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_613525, base: "/",
    url: url_RejectResourceShareInvitation_613526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613538 = ref object of OpenApiRestCall_612658
proc url_TagResource_613540(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613539(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tags to the specified resource share that you own.
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
  var valid_613541 = header.getOrDefault("X-Amz-Signature")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Signature", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Content-Sha256", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Date")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Date", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Credential")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Credential", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Security-Token")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Security-Token", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Algorithm")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Algorithm", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-SignedHeaders", valid_613547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_TagResource_613538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_TagResource_613538; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: JObject (required)
  var body_613551 = newJObject()
  if body != nil:
    body_613551 = body
  result = call_613550.call(nil, nil, nil, nil, body_613551)

var tagResource* = Call_TagResource_613538(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ram.amazonaws.com",
                                        route: "/tagresource",
                                        validator: validate_TagResource_613539,
                                        base: "/", url: url_TagResource_613540,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613552 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613554(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613553(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from the specified resource share that you own.
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
  var valid_613555 = header.getOrDefault("X-Amz-Signature")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Signature", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Content-Sha256", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Date")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Date", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Credential")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Credential", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Security-Token")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Security-Token", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Algorithm")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Algorithm", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-SignedHeaders", valid_613561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613563: Call_UntagResource_613552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
  ## 
  let valid = call_613563.validator(path, query, header, formData, body)
  let scheme = call_613563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613563.url(scheme.get, call_613563.host, call_613563.base,
                         call_613563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613563, url, valid)

proc call*(call_613564: Call_UntagResource_613552; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   body: JObject (required)
  var body_613565 = newJObject()
  if body != nil:
    body_613565 = body
  result = call_613564.call(nil, nil, nil, nil, body_613565)

var untagResource* = Call_UntagResource_613552(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_613553, base: "/", url: url_UntagResource_613554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_613566 = ref object of OpenApiRestCall_612658
proc url_UpdateResourceShare_613568(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceShare_613567(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the specified resource share that you own.
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_UpdateResourceShare_613566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified resource share that you own.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_UpdateResourceShare_613566; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var updateResourceShare* = Call_UpdateResourceShare_613566(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_613567, base: "/",
    url: url_UpdateResourceShare_613568, schemes: {Scheme.Https, Scheme.Http})
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
