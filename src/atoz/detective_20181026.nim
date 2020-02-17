
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Detective
## version: 2018-10-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <important> <p>Amazon Detective is currently in preview. The Detective API can only be used by accounts that are admitted into the preview.</p> </important> <p>Detective uses machine learning and purpose-built visualizations to help you analyze and investigate security issues across your Amazon Web Services (AWS) workloads. Detective automatically extracts time-based events such as login attempts, API calls, and network traffic from AWS CloudTrail and Amazon Virtual Private Cloud (Amazon VPC) flow logs. It also extracts findings detected by Amazon GuardDuty.</p> <p>The Detective API primarily supports the creation and management of behavior graphs. A behavior graph contains the extracted data from a set of member accounts, and is created and managed by a master account.</p> <p>Every behavior graph is specific to a Region. You can only use the API to manage graphs that belong to the Region that is associated with the currently selected endpoint.</p> <p>A Detective master account can use the Detective API to do the following:</p> <ul> <li> <p>Enable and disable Detective. Enabling Detective creates a new behavior graph.</p> </li> <li> <p>View the list of member accounts in a behavior graph.</p> </li> <li> <p>Add member accounts to a behavior graph.</p> </li> <li> <p>Remove member accounts from a behavior graph.</p> </li> </ul> <p>A member account can use the Detective API to do the following:</p> <ul> <li> <p>View the list of behavior graphs that they are invited to.</p> </li> <li> <p>Accept an invitation to contribute to a behavior graph.</p> </li> <li> <p>Decline an invitation to contribute to a behavior graph.</p> </li> <li> <p>Remove their account from a behavior graph.</p> </li> </ul> <p>All API actions are logged as CloudTrail events. See <a href="https://docs.aws.amazon.com/detective/latest/adminguide/logging-using-cloudtrail.html">Logging Detective API Calls with CloudTrail</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/detective/
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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.detective.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.detective.ap-southeast-1.amazonaws.com", "us-west-2": "api.detective.us-west-2.amazonaws.com", "eu-west-2": "api.detective.eu-west-2.amazonaws.com", "ap-northeast-3": "api.detective.ap-northeast-3.amazonaws.com", "eu-central-1": "api.detective.eu-central-1.amazonaws.com", "us-east-2": "api.detective.us-east-2.amazonaws.com", "us-east-1": "api.detective.us-east-1.amazonaws.com", "cn-northwest-1": "api.detective.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.detective.ap-south-1.amazonaws.com", "eu-north-1": "api.detective.eu-north-1.amazonaws.com", "ap-northeast-2": "api.detective.ap-northeast-2.amazonaws.com", "us-west-1": "api.detective.us-west-1.amazonaws.com", "us-gov-east-1": "api.detective.us-gov-east-1.amazonaws.com", "eu-west-3": "api.detective.eu-west-3.amazonaws.com", "cn-north-1": "api.detective.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.detective.sa-east-1.amazonaws.com", "eu-west-1": "api.detective.eu-west-1.amazonaws.com", "us-gov-west-1": "api.detective.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.detective.ap-southeast-2.amazonaws.com", "ca-central-1": "api.detective.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.detective.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.detective.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.detective.us-west-2.amazonaws.com",
      "eu-west-2": "api.detective.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.detective.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.detective.eu-central-1.amazonaws.com",
      "us-east-2": "api.detective.us-east-2.amazonaws.com",
      "us-east-1": "api.detective.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.detective.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.detective.ap-south-1.amazonaws.com",
      "eu-north-1": "api.detective.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.detective.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.detective.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.detective.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.detective.eu-west-3.amazonaws.com",
      "cn-north-1": "api.detective.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.detective.sa-east-1.amazonaws.com",
      "eu-west-1": "api.detective.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.detective.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.detective.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.detective.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "detective"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_610987 = ref object of OpenApiRestCall_610649
proc url_AcceptInvitation_610989(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_610988(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
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
  var valid_611101 = header.getOrDefault("X-Amz-Signature")
  valid_611101 = validateParameter(valid_611101, JString, required = false,
                                 default = nil)
  if valid_611101 != nil:
    section.add "X-Amz-Signature", valid_611101
  var valid_611102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "X-Amz-Content-Sha256", valid_611102
  var valid_611103 = header.getOrDefault("X-Amz-Date")
  valid_611103 = validateParameter(valid_611103, JString, required = false,
                                 default = nil)
  if valid_611103 != nil:
    section.add "X-Amz-Date", valid_611103
  var valid_611104 = header.getOrDefault("X-Amz-Credential")
  valid_611104 = validateParameter(valid_611104, JString, required = false,
                                 default = nil)
  if valid_611104 != nil:
    section.add "X-Amz-Credential", valid_611104
  var valid_611105 = header.getOrDefault("X-Amz-Security-Token")
  valid_611105 = validateParameter(valid_611105, JString, required = false,
                                 default = nil)
  if valid_611105 != nil:
    section.add "X-Amz-Security-Token", valid_611105
  var valid_611106 = header.getOrDefault("X-Amz-Algorithm")
  valid_611106 = validateParameter(valid_611106, JString, required = false,
                                 default = nil)
  if valid_611106 != nil:
    section.add "X-Amz-Algorithm", valid_611106
  var valid_611107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611107 = validateParameter(valid_611107, JString, required = false,
                                 default = nil)
  if valid_611107 != nil:
    section.add "X-Amz-SignedHeaders", valid_611107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611131: Call_AcceptInvitation_610987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ## 
  let valid = call_611131.validator(path, query, header, formData, body)
  let scheme = call_611131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611131.url(scheme.get, call_611131.host, call_611131.base,
                         call_611131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611131, url, valid)

proc call*(call_611202: Call_AcceptInvitation_610987; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ##   body: JObject (required)
  var body_611203 = newJObject()
  if body != nil:
    body_611203 = body
  result = call_611202.call(nil, nil, nil, nil, body_611203)

var acceptInvitation* = Call_AcceptInvitation_610987(name: "acceptInvitation",
    meth: HttpMethod.HttpPut, host: "api.detective.amazonaws.com",
    route: "/invitation", validator: validate_AcceptInvitation_610988, base: "/",
    url: url_AcceptInvitation_610989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraph_611242 = ref object of OpenApiRestCall_610649
proc url_CreateGraph_611244(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraph_611243(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
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
  var valid_611245 = header.getOrDefault("X-Amz-Signature")
  valid_611245 = validateParameter(valid_611245, JString, required = false,
                                 default = nil)
  if valid_611245 != nil:
    section.add "X-Amz-Signature", valid_611245
  var valid_611246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611246 = validateParameter(valid_611246, JString, required = false,
                                 default = nil)
  if valid_611246 != nil:
    section.add "X-Amz-Content-Sha256", valid_611246
  var valid_611247 = header.getOrDefault("X-Amz-Date")
  valid_611247 = validateParameter(valid_611247, JString, required = false,
                                 default = nil)
  if valid_611247 != nil:
    section.add "X-Amz-Date", valid_611247
  var valid_611248 = header.getOrDefault("X-Amz-Credential")
  valid_611248 = validateParameter(valid_611248, JString, required = false,
                                 default = nil)
  if valid_611248 != nil:
    section.add "X-Amz-Credential", valid_611248
  var valid_611249 = header.getOrDefault("X-Amz-Security-Token")
  valid_611249 = validateParameter(valid_611249, JString, required = false,
                                 default = nil)
  if valid_611249 != nil:
    section.add "X-Amz-Security-Token", valid_611249
  var valid_611250 = header.getOrDefault("X-Amz-Algorithm")
  valid_611250 = validateParameter(valid_611250, JString, required = false,
                                 default = nil)
  if valid_611250 != nil:
    section.add "X-Amz-Algorithm", valid_611250
  var valid_611251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611251 = validateParameter(valid_611251, JString, required = false,
                                 default = nil)
  if valid_611251 != nil:
    section.add "X-Amz-SignedHeaders", valid_611251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611252: Call_CreateGraph_611242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  ## 
  let valid = call_611252.validator(path, query, header, formData, body)
  let scheme = call_611252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611252.url(scheme.get, call_611252.host, call_611252.base,
                         call_611252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611252, url, valid)

proc call*(call_611253: Call_CreateGraph_611242): Recallable =
  ## createGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  result = call_611253.call(nil, nil, nil, nil, nil)

var createGraph* = Call_CreateGraph_611242(name: "createGraph",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph",
                                        validator: validate_CreateGraph_611243,
                                        base: "/", url: url_CreateGraph_611244,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_611254 = ref object of OpenApiRestCall_610649
proc url_CreateMembers_611256(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_611255(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
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
  var valid_611257 = header.getOrDefault("X-Amz-Signature")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Signature", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Content-Sha256", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Date")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Date", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Credential")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Credential", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Security-Token")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Security-Token", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Algorithm")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Algorithm", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-SignedHeaders", valid_611263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611265: Call_CreateMembers_611254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ## 
  let valid = call_611265.validator(path, query, header, formData, body)
  let scheme = call_611265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611265.url(scheme.get, call_611265.host, call_611265.base,
                         call_611265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611265, url, valid)

proc call*(call_611266: Call_CreateMembers_611254; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ##   body: JObject (required)
  var body_611267 = newJObject()
  if body != nil:
    body_611267 = body
  result = call_611266.call(nil, nil, nil, nil, body_611267)

var createMembers* = Call_CreateMembers_611254(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members", validator: validate_CreateMembers_611255, base: "/",
    url: url_CreateMembers_611256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraph_611268 = ref object of OpenApiRestCall_610649
proc url_DeleteGraph_611270(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGraph_611269(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
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
  var valid_611271 = header.getOrDefault("X-Amz-Signature")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Signature", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Content-Sha256", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Date")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Date", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Credential")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Credential", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Security-Token")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Security-Token", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Algorithm")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Algorithm", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-SignedHeaders", valid_611277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611279: Call_DeleteGraph_611268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ## 
  let valid = call_611279.validator(path, query, header, formData, body)
  let scheme = call_611279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611279.url(scheme.get, call_611279.host, call_611279.base,
                         call_611279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611279, url, valid)

proc call*(call_611280: Call_DeleteGraph_611268; body: JsonNode): Recallable =
  ## deleteGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ##   body: JObject (required)
  var body_611281 = newJObject()
  if body != nil:
    body_611281 = body
  result = call_611280.call(nil, nil, nil, nil, body_611281)

var deleteGraph* = Call_DeleteGraph_611268(name: "deleteGraph",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph/removal",
                                        validator: validate_DeleteGraph_611269,
                                        base: "/", url: url_DeleteGraph_611270,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_611282 = ref object of OpenApiRestCall_610649
proc url_DeleteMembers_611284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_611283(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
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
  var valid_611285 = header.getOrDefault("X-Amz-Signature")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Signature", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Content-Sha256", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Date")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Date", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Credential")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Credential", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Security-Token")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Security-Token", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Algorithm")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Algorithm", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-SignedHeaders", valid_611291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611293: Call_DeleteMembers_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ## 
  let valid = call_611293.validator(path, query, header, formData, body)
  let scheme = call_611293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611293.url(scheme.get, call_611293.host, call_611293.base,
                         call_611293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611293, url, valid)

proc call*(call_611294: Call_DeleteMembers_611282; body: JsonNode): Recallable =
  ## deleteMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ##   body: JObject (required)
  var body_611295 = newJObject()
  if body != nil:
    body_611295 = body
  result = call_611294.call(nil, nil, nil, nil, body_611295)

var deleteMembers* = Call_DeleteMembers_611282(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/removal", validator: validate_DeleteMembers_611283,
    base: "/", url: url_DeleteMembers_611284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembership_611296 = ref object of OpenApiRestCall_610649
proc url_DisassociateMembership_611298(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembership_611297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
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
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_DisassociateMembership_611296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_DisassociateMembership_611296; body: JsonNode): Recallable =
  ## disassociateMembership
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var disassociateMembership* = Call_DisassociateMembership_611296(
    name: "disassociateMembership", meth: HttpMethod.HttpPost,
    host: "api.detective.amazonaws.com", route: "/membership/removal",
    validator: validate_DisassociateMembership_611297, base: "/",
    url: url_DisassociateMembership_611298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_611310 = ref object of OpenApiRestCall_610649
proc url_GetMembers_611312(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_611311(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
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
  var valid_611313 = header.getOrDefault("X-Amz-Signature")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Signature", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Content-Sha256", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Date")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Date", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Credential")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Credential", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Security-Token")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Security-Token", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Algorithm")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Algorithm", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-SignedHeaders", valid_611319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611321: Call_GetMembers_611310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ## 
  let valid = call_611321.validator(path, query, header, formData, body)
  let scheme = call_611321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611321.url(scheme.get, call_611321.host, call_611321.base,
                         call_611321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611321, url, valid)

proc call*(call_611322: Call_GetMembers_611310; body: JsonNode): Recallable =
  ## getMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ##   body: JObject (required)
  var body_611323 = newJObject()
  if body != nil:
    body_611323 = body
  result = call_611322.call(nil, nil, nil, nil, body_611323)

var getMembers* = Call_GetMembers_611310(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.detective.amazonaws.com",
                                      route: "/graph/members/get",
                                      validator: validate_GetMembers_611311,
                                      base: "/", url: url_GetMembers_611312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphs_611324 = ref object of OpenApiRestCall_610649
proc url_ListGraphs_611326(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphs_611325(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611327 = query.getOrDefault("MaxResults")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "MaxResults", valid_611327
  var valid_611328 = query.getOrDefault("NextToken")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "NextToken", valid_611328
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
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_ListGraphs_611324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_ListGraphs_611324; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGraphs
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611339 = newJObject()
  var body_611340 = newJObject()
  add(query_611339, "MaxResults", newJString(MaxResults))
  add(query_611339, "NextToken", newJString(NextToken))
  if body != nil:
    body_611340 = body
  result = call_611338.call(nil, query_611339, nil, nil, body_611340)

var listGraphs* = Call_ListGraphs_611324(name: "listGraphs",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.detective.amazonaws.com",
                                      route: "/graphs/list",
                                      validator: validate_ListGraphs_611325,
                                      base: "/", url: url_ListGraphs_611326,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_611342 = ref object of OpenApiRestCall_610649
proc url_ListInvitations_611344(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_611343(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611345 = query.getOrDefault("MaxResults")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "MaxResults", valid_611345
  var valid_611346 = query.getOrDefault("NextToken")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "NextToken", valid_611346
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
  var valid_611347 = header.getOrDefault("X-Amz-Signature")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Signature", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Content-Sha256", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Date")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Date", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Credential")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Credential", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Security-Token")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Security-Token", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Algorithm")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Algorithm", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-SignedHeaders", valid_611353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611355: Call_ListInvitations_611342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ## 
  let valid = call_611355.validator(path, query, header, formData, body)
  let scheme = call_611355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611355.url(scheme.get, call_611355.host, call_611355.base,
                         call_611355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611355, url, valid)

proc call*(call_611356: Call_ListInvitations_611342; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listInvitations
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611357 = newJObject()
  var body_611358 = newJObject()
  add(query_611357, "MaxResults", newJString(MaxResults))
  add(query_611357, "NextToken", newJString(NextToken))
  if body != nil:
    body_611358 = body
  result = call_611356.call(nil, query_611357, nil, nil, body_611358)

var listInvitations* = Call_ListInvitations_611342(name: "listInvitations",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitations/list", validator: validate_ListInvitations_611343,
    base: "/", url: url_ListInvitations_611344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_611359 = ref object of OpenApiRestCall_610649
proc url_ListMembers_611361(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_611360(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611362 = query.getOrDefault("MaxResults")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "MaxResults", valid_611362
  var valid_611363 = query.getOrDefault("NextToken")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "NextToken", valid_611363
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
  var valid_611364 = header.getOrDefault("X-Amz-Signature")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Signature", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Content-Sha256", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Date")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Date", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Credential")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Credential", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Security-Token")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Security-Token", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Algorithm")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Algorithm", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-SignedHeaders", valid_611370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611372: Call_ListMembers_611359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ## 
  let valid = call_611372.validator(path, query, header, formData, body)
  let scheme = call_611372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611372.url(scheme.get, call_611372.host, call_611372.base,
                         call_611372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611372, url, valid)

proc call*(call_611373: Call_ListMembers_611359; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611374 = newJObject()
  var body_611375 = newJObject()
  add(query_611374, "MaxResults", newJString(MaxResults))
  add(query_611374, "NextToken", newJString(NextToken))
  if body != nil:
    body_611375 = body
  result = call_611373.call(nil, query_611374, nil, nil, body_611375)

var listMembers* = Call_ListMembers_611359(name: "listMembers",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph/members/list",
                                        validator: validate_ListMembers_611360,
                                        base: "/", url: url_ListMembers_611361,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_611376 = ref object of OpenApiRestCall_610649
proc url_RejectInvitation_611378(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectInvitation_611377(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
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
  var valid_611379 = header.getOrDefault("X-Amz-Signature")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Signature", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Content-Sha256", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Date")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Date", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Credential")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Credential", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Security-Token")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Security-Token", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Algorithm")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Algorithm", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-SignedHeaders", valid_611385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611387: Call_RejectInvitation_611376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ## 
  let valid = call_611387.validator(path, query, header, formData, body)
  let scheme = call_611387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611387.url(scheme.get, call_611387.host, call_611387.base,
                         call_611387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611387, url, valid)

proc call*(call_611388: Call_RejectInvitation_611376; body: JsonNode): Recallable =
  ## rejectInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ##   body: JObject (required)
  var body_611389 = newJObject()
  if body != nil:
    body_611389 = body
  result = call_611388.call(nil, nil, nil, nil, body_611389)

var rejectInvitation* = Call_RejectInvitation_611376(name: "rejectInvitation",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitation/removal", validator: validate_RejectInvitation_611377,
    base: "/", url: url_RejectInvitation_611378,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
