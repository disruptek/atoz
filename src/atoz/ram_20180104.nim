
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_AcceptResourceShareInvitation_605927 = ref object of OpenApiRestCall_605589
proc url_AcceptResourceShareInvitation_605929(protocol: Scheme; host: string;
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

proc validate_AcceptResourceShareInvitation_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Algorithm")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Algorithm", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-SignedHeaders", valid_606047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_AcceptResourceShareInvitation_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
  ## 
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_AcceptResourceShareInvitation_605927; body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_606143 = newJObject()
  if body != nil:
    body_606143 = body
  result = call_606142.call(nil, nil, nil, nil, body_606143)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_605927(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_605928, base: "/",
    url: url_AcceptResourceShareInvitation_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_606182 = ref object of OpenApiRestCall_605589
proc url_AssociateResourceShare_606184(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateResourceShare_606183(path: JsonNode; query: JsonNode;
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
  var valid_606185 = header.getOrDefault("X-Amz-Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Signature", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Content-Sha256", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Date")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Date", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Credential")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Credential", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Security-Token")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Security-Token", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Algorithm")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Algorithm", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_AssociateResourceShare_606182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_AssociateResourceShare_606182; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   body: JObject (required)
  var body_606195 = newJObject()
  if body != nil:
    body_606195 = body
  result = call_606194.call(nil, nil, nil, nil, body_606195)

var associateResourceShare* = Call_AssociateResourceShare_606182(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_606183, base: "/",
    url: url_AssociateResourceShare_606184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceSharePermission_606196 = ref object of OpenApiRestCall_605589
proc url_AssociateResourceSharePermission_606198(protocol: Scheme; host: string;
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

proc validate_AssociateResourceSharePermission_606197(path: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Signature")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Signature", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Content-Sha256", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Date")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Date", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Credential")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Credential", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Security-Token")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Security-Token", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Algorithm")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Algorithm", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-SignedHeaders", valid_606205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606207: Call_AssociateResourceSharePermission_606196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a permission with a resource share.
  ## 
  let valid = call_606207.validator(path, query, header, formData, body)
  let scheme = call_606207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606207.url(scheme.get, call_606207.host, call_606207.base,
                         call_606207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606207, url, valid)

proc call*(call_606208: Call_AssociateResourceSharePermission_606196;
          body: JsonNode): Recallable =
  ## associateResourceSharePermission
  ## Associates a permission with a resource share.
  ##   body: JObject (required)
  var body_606209 = newJObject()
  if body != nil:
    body_606209 = body
  result = call_606208.call(nil, nil, nil, nil, body_606209)

var associateResourceSharePermission* = Call_AssociateResourceSharePermission_606196(
    name: "associateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourcesharepermission",
    validator: validate_AssociateResourceSharePermission_606197, base: "/",
    url: url_AssociateResourceSharePermission_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_606210 = ref object of OpenApiRestCall_605589
proc url_CreateResourceShare_606212(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceShare_606211(path: JsonNode; query: JsonNode;
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
  var valid_606213 = header.getOrDefault("X-Amz-Signature")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Signature", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Content-Sha256", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Date")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Date", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Credential")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Credential", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Security-Token")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Security-Token", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Algorithm")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Algorithm", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-SignedHeaders", valid_606219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606221: Call_CreateResourceShare_606210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource share.
  ## 
  let valid = call_606221.validator(path, query, header, formData, body)
  let scheme = call_606221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606221.url(scheme.get, call_606221.host, call_606221.base,
                         call_606221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606221, url, valid)

proc call*(call_606222: Call_CreateResourceShare_606210; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_606223 = newJObject()
  if body != nil:
    body_606223 = body
  result = call_606222.call(nil, nil, nil, nil, body_606223)

var createResourceShare* = Call_CreateResourceShare_606210(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_606211, base: "/",
    url: url_CreateResourceShare_606212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_606224 = ref object of OpenApiRestCall_605589
proc url_DeleteResourceShare_606226(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourceShare_606225(path: JsonNode; query: JsonNode;
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
  var valid_606227 = query.getOrDefault("clientToken")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "clientToken", valid_606227
  assert query != nil,
        "query argument is necessary due to required `resourceShareArn` field"
  var valid_606228 = query.getOrDefault("resourceShareArn")
  valid_606228 = validateParameter(valid_606228, JString, required = true,
                                 default = nil)
  if valid_606228 != nil:
    section.add "resourceShareArn", valid_606228
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
  var valid_606229 = header.getOrDefault("X-Amz-Signature")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Signature", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Content-Sha256", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Date")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Date", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Credential")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Credential", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Security-Token")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Security-Token", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Algorithm")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Algorithm", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-SignedHeaders", valid_606235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606236: Call_DeleteResourceShare_606224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified resource share.
  ## 
  let valid = call_606236.validator(path, query, header, formData, body)
  let scheme = call_606236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606236.url(scheme.get, call_606236.host, call_606236.base,
                         call_606236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606236, url, valid)

proc call*(call_606237: Call_DeleteResourceShare_606224; resourceShareArn: string;
          clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   clientToken: string
  ##              : A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  ##   resourceShareArn: string (required)
  ##                   : The Amazon Resource Name (ARN) of the resource share.
  var query_606238 = newJObject()
  add(query_606238, "clientToken", newJString(clientToken))
  add(query_606238, "resourceShareArn", newJString(resourceShareArn))
  result = call_606237.call(nil, query_606238, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_606224(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_606225, base: "/",
    url: url_DeleteResourceShare_606226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_606240 = ref object of OpenApiRestCall_605589
proc url_DisassociateResourceShare_606242(protocol: Scheme; host: string;
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

proc validate_DisassociateResourceShare_606241(path: JsonNode; query: JsonNode;
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
  var valid_606243 = header.getOrDefault("X-Amz-Signature")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Signature", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Content-Sha256", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Date")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Date", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Credential")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Credential", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Security-Token")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Security-Token", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Algorithm")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Algorithm", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-SignedHeaders", valid_606249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606251: Call_DisassociateResourceShare_606240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
  ## 
  let valid = call_606251.validator(path, query, header, formData, body)
  let scheme = call_606251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606251.url(scheme.get, call_606251.host, call_606251.base,
                         call_606251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606251, url, valid)

proc call*(call_606252: Call_DisassociateResourceShare_606240; body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   body: JObject (required)
  var body_606253 = newJObject()
  if body != nil:
    body_606253 = body
  result = call_606252.call(nil, nil, nil, nil, body_606253)

var disassociateResourceShare* = Call_DisassociateResourceShare_606240(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_606241, base: "/",
    url: url_DisassociateResourceShare_606242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceSharePermission_606254 = ref object of OpenApiRestCall_605589
proc url_DisassociateResourceSharePermission_606256(protocol: Scheme; host: string;
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

proc validate_DisassociateResourceSharePermission_606255(path: JsonNode;
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
  var valid_606257 = header.getOrDefault("X-Amz-Signature")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Signature", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Content-Sha256", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Date")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Date", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Credential")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Credential", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Security-Token")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Security-Token", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Algorithm")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Algorithm", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-SignedHeaders", valid_606263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606265: Call_DisassociateResourceSharePermission_606254;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates an AWS RAM permission from a resource share.
  ## 
  let valid = call_606265.validator(path, query, header, formData, body)
  let scheme = call_606265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606265.url(scheme.get, call_606265.host, call_606265.base,
                         call_606265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606265, url, valid)

proc call*(call_606266: Call_DisassociateResourceSharePermission_606254;
          body: JsonNode): Recallable =
  ## disassociateResourceSharePermission
  ## Disassociates an AWS RAM permission from a resource share.
  ##   body: JObject (required)
  var body_606267 = newJObject()
  if body != nil:
    body_606267 = body
  result = call_606266.call(nil, nil, nil, nil, body_606267)

var disassociateResourceSharePermission* = Call_DisassociateResourceSharePermission_606254(
    name: "disassociateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourcesharepermission",
    validator: validate_DisassociateResourceSharePermission_606255, base: "/",
    url: url_DisassociateResourceSharePermission_606256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_606268 = ref object of OpenApiRestCall_605589
proc url_EnableSharingWithAwsOrganization_606270(protocol: Scheme; host: string;
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

proc validate_EnableSharingWithAwsOrganization_606269(path: JsonNode;
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
  var valid_606271 = header.getOrDefault("X-Amz-Signature")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Signature", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Content-Sha256", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Date")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Date", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Credential")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Credential", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Security-Token")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Security-Token", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Algorithm")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Algorithm", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-SignedHeaders", valid_606277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606278: Call_EnableSharingWithAwsOrganization_606268;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  ## 
  let valid = call_606278.validator(path, query, header, formData, body)
  let scheme = call_606278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606278.url(scheme.get, call_606278.host, call_606278.base,
                         call_606278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606278, url, valid)

proc call*(call_606279: Call_EnableSharingWithAwsOrganization_606268): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_606279.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_606268(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_606269, base: "/",
    url: url_EnableSharingWithAwsOrganization_606270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermission_606280 = ref object of OpenApiRestCall_605589
proc url_GetPermission_606282(protocol: Scheme; host: string; base: string;
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

proc validate_GetPermission_606281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_GetPermission_606280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of an AWS RAM permission in JSON format.
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_GetPermission_606280; body: JsonNode): Recallable =
  ## getPermission
  ## Gets the contents of an AWS RAM permission in JSON format.
  ##   body: JObject (required)
  var body_606293 = newJObject()
  if body != nil:
    body_606293 = body
  result = call_606292.call(nil, nil, nil, nil, body_606293)

var getPermission* = Call_GetPermission_606280(name: "getPermission",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/getpermission",
    validator: validate_GetPermission_606281, base: "/", url: url_GetPermission_606282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_606294 = ref object of OpenApiRestCall_605589
proc url_GetResourcePolicies_606296(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicies_606295(path: JsonNode; query: JsonNode;
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
  var valid_606297 = query.getOrDefault("nextToken")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "nextToken", valid_606297
  var valid_606298 = query.getOrDefault("maxResults")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "maxResults", valid_606298
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
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606307: Call_GetResourcePolicies_606294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
  ## 
  let valid = call_606307.validator(path, query, header, formData, body)
  let scheme = call_606307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606307.url(scheme.get, call_606307.host, call_606307.base,
                         call_606307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606307, url, valid)

proc call*(call_606308: Call_GetResourcePolicies_606294; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606309 = newJObject()
  var body_606310 = newJObject()
  add(query_606309, "nextToken", newJString(nextToken))
  if body != nil:
    body_606310 = body
  add(query_606309, "maxResults", newJString(maxResults))
  result = call_606308.call(nil, query_606309, nil, nil, body_606310)

var getResourcePolicies* = Call_GetResourcePolicies_606294(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_606295, base: "/",
    url: url_GetResourcePolicies_606296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_606311 = ref object of OpenApiRestCall_605589
proc url_GetResourceShareAssociations_606313(protocol: Scheme; host: string;
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

proc validate_GetResourceShareAssociations_606312(path: JsonNode; query: JsonNode;
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
  var valid_606314 = query.getOrDefault("nextToken")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "nextToken", valid_606314
  var valid_606315 = query.getOrDefault("maxResults")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "maxResults", valid_606315
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
  var valid_606316 = header.getOrDefault("X-Amz-Signature")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Signature", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Content-Sha256", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Date")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Date", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Credential")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Credential", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Security-Token")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Security-Token", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Algorithm")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Algorithm", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-SignedHeaders", valid_606322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606324: Call_GetResourceShareAssociations_606311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
  ## 
  let valid = call_606324.validator(path, query, header, formData, body)
  let scheme = call_606324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606324.url(scheme.get, call_606324.host, call_606324.base,
                         call_606324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606324, url, valid)

proc call*(call_606325: Call_GetResourceShareAssociations_606311; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606326 = newJObject()
  var body_606327 = newJObject()
  add(query_606326, "nextToken", newJString(nextToken))
  if body != nil:
    body_606327 = body
  add(query_606326, "maxResults", newJString(maxResults))
  result = call_606325.call(nil, query_606326, nil, nil, body_606327)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_606311(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_606312, base: "/",
    url: url_GetResourceShareAssociations_606313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_606328 = ref object of OpenApiRestCall_605589
proc url_GetResourceShareInvitations_606330(protocol: Scheme; host: string;
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

proc validate_GetResourceShareInvitations_606329(path: JsonNode; query: JsonNode;
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
  var valid_606331 = query.getOrDefault("nextToken")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "nextToken", valid_606331
  var valid_606332 = query.getOrDefault("maxResults")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "maxResults", valid_606332
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
  var valid_606333 = header.getOrDefault("X-Amz-Signature")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Signature", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Content-Sha256", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Date")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Date", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Credential")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Credential", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Security-Token")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Security-Token", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Algorithm")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Algorithm", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-SignedHeaders", valid_606339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606341: Call_GetResourceShareInvitations_606328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the invitations for resource sharing that you've received.
  ## 
  let valid = call_606341.validator(path, query, header, formData, body)
  let scheme = call_606341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606341.url(scheme.get, call_606341.host, call_606341.base,
                         call_606341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606341, url, valid)

proc call*(call_606342: Call_GetResourceShareInvitations_606328; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606343 = newJObject()
  var body_606344 = newJObject()
  add(query_606343, "nextToken", newJString(nextToken))
  if body != nil:
    body_606344 = body
  add(query_606343, "maxResults", newJString(maxResults))
  result = call_606342.call(nil, query_606343, nil, nil, body_606344)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_606328(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_606329, base: "/",
    url: url_GetResourceShareInvitations_606330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_606345 = ref object of OpenApiRestCall_605589
proc url_GetResourceShares_606347(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourceShares_606346(path: JsonNode; query: JsonNode;
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
  var valid_606348 = query.getOrDefault("nextToken")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "nextToken", valid_606348
  var valid_606349 = query.getOrDefault("maxResults")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "maxResults", valid_606349
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_GetResourceShares_606345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_GetResourceShares_606345; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606360 = newJObject()
  var body_606361 = newJObject()
  add(query_606360, "nextToken", newJString(nextToken))
  if body != nil:
    body_606361 = body
  add(query_606360, "maxResults", newJString(maxResults))
  result = call_606359.call(nil, query_606360, nil, nil, body_606361)

var getResourceShares* = Call_GetResourceShares_606345(name: "getResourceShares",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getresourceshares", validator: validate_GetResourceShares_606346,
    base: "/", url: url_GetResourceShares_606347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_606362 = ref object of OpenApiRestCall_605589
proc url_ListPendingInvitationResources_606364(protocol: Scheme; host: string;
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

proc validate_ListPendingInvitationResources_606363(path: JsonNode;
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
  var valid_606365 = query.getOrDefault("nextToken")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "nextToken", valid_606365
  var valid_606366 = query.getOrDefault("maxResults")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "maxResults", valid_606366
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
  var valid_606367 = header.getOrDefault("X-Amz-Signature")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Signature", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Content-Sha256", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Date")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Date", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Credential")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Credential", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Security-Token")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Security-Token", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Algorithm")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Algorithm", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-SignedHeaders", valid_606373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606375: Call_ListPendingInvitationResources_606362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ## 
  let valid = call_606375.validator(path, query, header, formData, body)
  let scheme = call_606375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606375.url(scheme.get, call_606375.host, call_606375.base,
                         call_606375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606375, url, valid)

proc call*(call_606376: Call_ListPendingInvitationResources_606362; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606377 = newJObject()
  var body_606378 = newJObject()
  add(query_606377, "nextToken", newJString(nextToken))
  if body != nil:
    body_606378 = body
  add(query_606377, "maxResults", newJString(maxResults))
  result = call_606376.call(nil, query_606377, nil, nil, body_606378)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_606362(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_606363, base: "/",
    url: url_ListPendingInvitationResources_606364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_606379 = ref object of OpenApiRestCall_605589
proc url_ListPermissions_606381(protocol: Scheme; host: string; base: string;
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

proc validate_ListPermissions_606380(path: JsonNode; query: JsonNode;
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
  var valid_606382 = header.getOrDefault("X-Amz-Signature")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Signature", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Content-Sha256", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Date")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Date", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Credential")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Credential", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Security-Token")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Security-Token", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Algorithm")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Algorithm", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-SignedHeaders", valid_606388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606390: Call_ListPermissions_606379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS RAM permissions.
  ## 
  let valid = call_606390.validator(path, query, header, formData, body)
  let scheme = call_606390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606390.url(scheme.get, call_606390.host, call_606390.base,
                         call_606390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606390, url, valid)

proc call*(call_606391: Call_ListPermissions_606379; body: JsonNode): Recallable =
  ## listPermissions
  ## Lists the AWS RAM permissions.
  ##   body: JObject (required)
  var body_606392 = newJObject()
  if body != nil:
    body_606392 = body
  result = call_606391.call(nil, nil, nil, nil, body_606392)

var listPermissions* = Call_ListPermissions_606379(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listpermissions",
    validator: validate_ListPermissions_606380, base: "/", url: url_ListPermissions_606381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_606393 = ref object of OpenApiRestCall_605589
proc url_ListPrincipals_606395(protocol: Scheme; host: string; base: string;
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

proc validate_ListPrincipals_606394(path: JsonNode; query: JsonNode;
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
  var valid_606396 = query.getOrDefault("nextToken")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "nextToken", valid_606396
  var valid_606397 = query.getOrDefault("maxResults")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "maxResults", valid_606397
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
  var valid_606398 = header.getOrDefault("X-Amz-Signature")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Signature", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Content-Sha256", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Date")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Date", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Credential")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Credential", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Security-Token")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Security-Token", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Algorithm")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Algorithm", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-SignedHeaders", valid_606404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606406: Call_ListPrincipals_606393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ## 
  let valid = call_606406.validator(path, query, header, formData, body)
  let scheme = call_606406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606406.url(scheme.get, call_606406.host, call_606406.base,
                         call_606406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606406, url, valid)

proc call*(call_606407: Call_ListPrincipals_606393; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or that have shared resources with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606408 = newJObject()
  var body_606409 = newJObject()
  add(query_606408, "nextToken", newJString(nextToken))
  if body != nil:
    body_606409 = body
  add(query_606408, "maxResults", newJString(maxResults))
  result = call_606407.call(nil, query_606408, nil, nil, body_606409)

var listPrincipals* = Call_ListPrincipals_606393(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listprincipals",
    validator: validate_ListPrincipals_606394, base: "/", url: url_ListPrincipals_606395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceSharePermissions_606410 = ref object of OpenApiRestCall_605589
proc url_ListResourceSharePermissions_606412(protocol: Scheme; host: string;
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

proc validate_ListResourceSharePermissions_606411(path: JsonNode; query: JsonNode;
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
  var valid_606413 = header.getOrDefault("X-Amz-Signature")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Signature", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Content-Sha256", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Date")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Date", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Credential")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Credential", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Security-Token")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Security-Token", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Algorithm")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Algorithm", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-SignedHeaders", valid_606419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606421: Call_ListResourceSharePermissions_606410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ## 
  let valid = call_606421.validator(path, query, header, formData, body)
  let scheme = call_606421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606421.url(scheme.get, call_606421.host, call_606421.base,
                         call_606421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606421, url, valid)

proc call*(call_606422: Call_ListResourceSharePermissions_606410; body: JsonNode): Recallable =
  ## listResourceSharePermissions
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ##   body: JObject (required)
  var body_606423 = newJObject()
  if body != nil:
    body_606423 = body
  result = call_606422.call(nil, nil, nil, nil, body_606423)

var listResourceSharePermissions* = Call_ListResourceSharePermissions_606410(
    name: "listResourceSharePermissions", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listresourcesharepermissions",
    validator: validate_ListResourceSharePermissions_606411, base: "/",
    url: url_ListResourceSharePermissions_606412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_606424 = ref object of OpenApiRestCall_605589
proc url_ListResources_606426(protocol: Scheme; host: string; base: string;
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

proc validate_ListResources_606425(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606427 = query.getOrDefault("nextToken")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "nextToken", valid_606427
  var valid_606428 = query.getOrDefault("maxResults")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "maxResults", valid_606428
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
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Security-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Security-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Algorithm")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Algorithm", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-SignedHeaders", valid_606435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606437: Call_ListResources_606424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ## 
  let valid = call_606437.validator(path, query, header, formData, body)
  let scheme = call_606437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606437.url(scheme.get, call_606437.host, call_606437.base,
                         call_606437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606437, url, valid)

proc call*(call_606438: Call_ListResources_606424; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606439 = newJObject()
  var body_606440 = newJObject()
  add(query_606439, "nextToken", newJString(nextToken))
  if body != nil:
    body_606440 = body
  add(query_606439, "maxResults", newJString(maxResults))
  result = call_606438.call(nil, query_606439, nil, nil, body_606440)

var listResources* = Call_ListResources_606424(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/listresources",
    validator: validate_ListResources_606425, base: "/", url: url_ListResources_606426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PromoteResourceShareCreatedFromPolicy_606441 = ref object of OpenApiRestCall_605589
proc url_PromoteResourceShareCreatedFromPolicy_606443(protocol: Scheme;
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

proc validate_PromoteResourceShareCreatedFromPolicy_606442(path: JsonNode;
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
  var valid_606444 = query.getOrDefault("resourceShareArn")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "resourceShareArn", valid_606444
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
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_PromoteResourceShareCreatedFromPolicy_606441;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_PromoteResourceShareCreatedFromPolicy_606441;
          resourceShareArn: string): Recallable =
  ## promoteResourceShareCreatedFromPolicy
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ##   resourceShareArn: string (required)
  ##                   : The ARN of the resource share to promote.
  var query_606454 = newJObject()
  add(query_606454, "resourceShareArn", newJString(resourceShareArn))
  result = call_606453.call(nil, query_606454, nil, nil, nil)

var promoteResourceShareCreatedFromPolicy* = Call_PromoteResourceShareCreatedFromPolicy_606441(
    name: "promoteResourceShareCreatedFromPolicy", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com",
    route: "/promoteresourcesharecreatedfrompolicy#resourceShareArn",
    validator: validate_PromoteResourceShareCreatedFromPolicy_606442, base: "/",
    url: url_PromoteResourceShareCreatedFromPolicy_606443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_606455 = ref object of OpenApiRestCall_605589
proc url_RejectResourceShareInvitation_606457(protocol: Scheme; host: string;
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

proc validate_RejectResourceShareInvitation_606456(path: JsonNode; query: JsonNode;
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
  var valid_606458 = header.getOrDefault("X-Amz-Signature")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Signature", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Content-Sha256", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Date")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Date", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Credential")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Credential", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Security-Token")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Security-Token", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Algorithm")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Algorithm", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-SignedHeaders", valid_606464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606466: Call_RejectResourceShareInvitation_606455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
  ## 
  let valid = call_606466.validator(path, query, header, formData, body)
  let scheme = call_606466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606466.url(scheme.get, call_606466.host, call_606466.base,
                         call_606466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606466, url, valid)

proc call*(call_606467: Call_RejectResourceShareInvitation_606455; body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject (required)
  var body_606468 = newJObject()
  if body != nil:
    body_606468 = body
  result = call_606467.call(nil, nil, nil, nil, body_606468)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_606455(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_606456, base: "/",
    url: url_RejectResourceShareInvitation_606457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606469 = ref object of OpenApiRestCall_605589
proc url_TagResource_606471(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606472 = header.getOrDefault("X-Amz-Signature")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Signature", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Content-Sha256", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Date")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Date", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Credential")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Credential", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Security-Token")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Security-Token", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Algorithm")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Algorithm", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-SignedHeaders", valid_606478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606480: Call_TagResource_606469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_TagResource_606469; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: JObject (required)
  var body_606482 = newJObject()
  if body != nil:
    body_606482 = body
  result = call_606481.call(nil, nil, nil, nil, body_606482)

var tagResource* = Call_TagResource_606469(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ram.amazonaws.com",
                                        route: "/tagresource",
                                        validator: validate_TagResource_606470,
                                        base: "/", url: url_TagResource_606471,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606483 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606485(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606484(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606486 = header.getOrDefault("X-Amz-Signature")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Signature", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Content-Sha256", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Date")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Date", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Credential")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Credential", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Security-Token")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Security-Token", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Algorithm")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Algorithm", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-SignedHeaders", valid_606492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_UntagResource_606483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_UntagResource_606483; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   body: JObject (required)
  var body_606496 = newJObject()
  if body != nil:
    body_606496 = body
  result = call_606495.call(nil, nil, nil, nil, body_606496)

var untagResource* = Call_UntagResource_606483(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/untagresource",
    validator: validate_UntagResource_606484, base: "/", url: url_UntagResource_606485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_606497 = ref object of OpenApiRestCall_605589
proc url_UpdateResourceShare_606499(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResourceShare_606498(path: JsonNode; query: JsonNode;
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
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_UpdateResourceShare_606497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified resource share that you own.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_UpdateResourceShare_606497; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var updateResourceShare* = Call_UpdateResourceShare_606497(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_606498, base: "/",
    url: url_UpdateResourceShare_606499, schemes: {Scheme.Https, Scheme.Http})
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
