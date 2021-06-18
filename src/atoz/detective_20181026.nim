
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "api.detective.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.detective.ap-southeast-1.amazonaws.com", "us-west-2": "api.detective.us-west-2.amazonaws.com", "eu-west-2": "api.detective.eu-west-2.amazonaws.com", "ap-northeast-3": "api.detective.ap-northeast-3.amazonaws.com", "eu-central-1": "api.detective.eu-central-1.amazonaws.com", "us-east-2": "api.detective.us-east-2.amazonaws.com", "us-east-1": "api.detective.us-east-1.amazonaws.com", "cn-northwest-1": "api.detective.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.detective.ap-south-1.amazonaws.com", "eu-north-1": "api.detective.eu-north-1.amazonaws.com", "ap-northeast-2": "api.detective.ap-northeast-2.amazonaws.com", "us-west-1": "api.detective.us-west-1.amazonaws.com", "us-gov-east-1": "api.detective.us-gov-east-1.amazonaws.com", "eu-west-3": "api.detective.eu-west-3.amazonaws.com", "cn-north-1": "api.detective.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.detective.sa-east-1.amazonaws.com", "eu-west-1": "api.detective.eu-west-1.amazonaws.com", "us-gov-west-1": "api.detective.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.detective.ap-southeast-2.amazonaws.com", "ca-central-1": "api.detective.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AcceptInvitation_402656288 = ref object of OpenApiRestCall_402656038
proc url_AcceptInvitation_402656290(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Security-Token", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Signature")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Signature", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Algorithm", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Date")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Date", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Credential")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Credential", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656378
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

proc call*(call_402656393: Call_AcceptInvitation_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
                                                                                         ## 
  let valid = call_402656393.validator(path, query, header, formData, body, _)
  let scheme = call_402656393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656393.makeUrl(scheme.get, call_402656393.host, call_402656393.base,
                                   call_402656393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656393, uri, valid, _)

proc call*(call_402656442: Call_AcceptInvitation_402656288; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656443 = newJObject()
  if body != nil:
    body_402656443 = body
  result = call_402656442.call(nil, nil, nil, nil, body_402656443)

var acceptInvitation* = Call_AcceptInvitation_402656288(
    name: "acceptInvitation", meth: HttpMethod.HttpPut,
    host: "api.detective.amazonaws.com", route: "/invitation",
    validator: validate_AcceptInvitation_402656289, base: "/",
    makeUrl: url_AcceptInvitation_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraph_402656470 = ref object of OpenApiRestCall_402656038
proc url_CreateGraph_402656472(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraph_402656471(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656473 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656473 = validateParameter(valid_402656473, JString,
                                      required = false, default = nil)
  if valid_402656473 != nil:
    section.add "X-Amz-Security-Token", valid_402656473
  var valid_402656474 = header.getOrDefault("X-Amz-Signature")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-Signature", valid_402656474
  var valid_402656475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656475
  var valid_402656476 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Algorithm", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Date")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Date", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Credential")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Credential", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656480: Call_CreateGraph_402656470; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
                                                                                         ## 
  let valid = call_402656480.validator(path, query, header, formData, body, _)
  let scheme = call_402656480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656480.makeUrl(scheme.get, call_402656480.host, call_402656480.base,
                                   call_402656480.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656480, uri, valid, _)

proc call*(call_402656481: Call_CreateGraph_402656470): Recallable =
  ## createGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  result = call_402656481.call(nil, nil, nil, nil, nil)

var createGraph* = Call_CreateGraph_402656470(name: "createGraph",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph", validator: validate_CreateGraph_402656471, base: "/",
    makeUrl: url_CreateGraph_402656472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_402656482 = ref object of OpenApiRestCall_402656038
proc url_CreateMembers_402656484(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_402656483(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
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

proc call*(call_402656493: Call_CreateMembers_402656482; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656493.validator(path, query, header, formData, body, _)
  let scheme = call_402656493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656493.makeUrl(scheme.get, call_402656493.host, call_402656493.base,
                                   call_402656493.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656493, uri, valid, _)

proc call*(call_402656494: Call_CreateMembers_402656482; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656495 = newJObject()
  if body != nil:
    body_402656495 = body
  result = call_402656494.call(nil, nil, nil, nil, body_402656495)

var createMembers* = Call_CreateMembers_402656482(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members", validator: validate_CreateMembers_402656483,
    base: "/", makeUrl: url_CreateMembers_402656484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraph_402656496 = ref object of OpenApiRestCall_402656038
proc url_DeleteGraph_402656498(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGraph_402656497(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656499 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Security-Token", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Signature")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Signature", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Algorithm", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Date")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Date", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Credential")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Credential", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656505
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

proc call*(call_402656507: Call_DeleteGraph_402656496; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_DeleteGraph_402656496; body: JsonNode): Recallable =
  ## deleteGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ##   
                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656509 = newJObject()
  if body != nil:
    body_402656509 = body
  result = call_402656508.call(nil, nil, nil, nil, body_402656509)

var deleteGraph* = Call_DeleteGraph_402656496(name: "deleteGraph",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/removal", validator: validate_DeleteGraph_402656497,
    base: "/", makeUrl: url_DeleteGraph_402656498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_402656510 = ref object of OpenApiRestCall_402656038
proc url_DeleteMembers_402656512(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_402656511(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656513 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Security-Token", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Signature")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Signature", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Algorithm", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Date")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Date", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Credential")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Credential", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656519
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

proc call*(call_402656521: Call_DeleteMembers_402656510; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
                                                                                         ## 
  let valid = call_402656521.validator(path, query, header, formData, body, _)
  let scheme = call_402656521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656521.makeUrl(scheme.get, call_402656521.host, call_402656521.base,
                                   call_402656521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656521, uri, valid, _)

proc call*(call_402656522: Call_DeleteMembers_402656510; body: JsonNode): Recallable =
  ## deleteMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656523 = newJObject()
  if body != nil:
    body_402656523 = body
  result = call_402656522.call(nil, nil, nil, nil, body_402656523)

var deleteMembers* = Call_DeleteMembers_402656510(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/removal", validator: validate_DeleteMembers_402656511,
    base: "/", makeUrl: url_DeleteMembers_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembership_402656524 = ref object of OpenApiRestCall_402656038
proc url_DisassociateMembership_402656526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembership_402656525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656527 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Security-Token", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Signature")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Signature", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Algorithm", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Date")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Date", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Credential")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Credential", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656533
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

proc call*(call_402656535: Call_DisassociateMembership_402656524;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
                                                                                         ## 
  let valid = call_402656535.validator(path, query, header, formData, body, _)
  let scheme = call_402656535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656535.makeUrl(scheme.get, call_402656535.host, call_402656535.base,
                                   call_402656535.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656535, uri, valid, _)

proc call*(call_402656536: Call_DisassociateMembership_402656524; body: JsonNode): Recallable =
  ## disassociateMembership
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ##   
                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656537 = newJObject()
  if body != nil:
    body_402656537 = body
  result = call_402656536.call(nil, nil, nil, nil, body_402656537)

var disassociateMembership* = Call_DisassociateMembership_402656524(
    name: "disassociateMembership", meth: HttpMethod.HttpPost,
    host: "api.detective.amazonaws.com", route: "/membership/removal",
    validator: validate_DisassociateMembership_402656525, base: "/",
    makeUrl: url_DisassociateMembership_402656526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_402656538 = ref object of OpenApiRestCall_402656038
proc url_GetMembers_402656540(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_402656539(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656541 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Security-Token", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Signature")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Signature", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Algorithm", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Date")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Date", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Credential")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Credential", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656547
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

proc call*(call_402656549: Call_GetMembers_402656538; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
                                                                                         ## 
  let valid = call_402656549.validator(path, query, header, formData, body, _)
  let scheme = call_402656549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656549.makeUrl(scheme.get, call_402656549.host, call_402656549.base,
                                   call_402656549.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656549, uri, valid, _)

proc call*(call_402656550: Call_GetMembers_402656538; body: JsonNode): Recallable =
  ## getMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ##   
                                                                                                                                               ## body: JObject (required)
  var body_402656551 = newJObject()
  if body != nil:
    body_402656551 = body
  result = call_402656550.call(nil, nil, nil, nil, body_402656551)

var getMembers* = Call_GetMembers_402656538(name: "getMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/get", validator: validate_GetMembers_402656539,
    base: "/", makeUrl: url_GetMembers_402656540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphs_402656552 = ref object of OpenApiRestCall_402656038
proc url_ListGraphs_402656554(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphs_402656553(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656555 = query.getOrDefault("MaxResults")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "MaxResults", valid_402656555
  var valid_402656556 = query.getOrDefault("NextToken")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "NextToken", valid_402656556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656557 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Security-Token", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Signature")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Signature", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Algorithm", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Date")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Date", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Credential")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Credential", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656563
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

proc call*(call_402656565: Call_ListGraphs_402656552; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_ListGraphs_402656552; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGraphs
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402656567 = newJObject()
  var body_402656568 = newJObject()
  add(query_402656567, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656568 = body
  add(query_402656567, "NextToken", newJString(NextToken))
  result = call_402656566.call(nil, query_402656567, nil, nil, body_402656568)

var listGraphs* = Call_ListGraphs_402656552(name: "listGraphs",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graphs/list", validator: validate_ListGraphs_402656553, base: "/",
    makeUrl: url_ListGraphs_402656554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_402656569 = ref object of OpenApiRestCall_402656038
proc url_ListInvitations_402656571(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_402656570(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656572 = query.getOrDefault("MaxResults")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "MaxResults", valid_402656572
  var valid_402656573 = query.getOrDefault("NextToken")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "NextToken", valid_402656573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
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

proc call*(call_402656582: Call_ListInvitations_402656569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
                                                                                         ## 
  let valid = call_402656582.validator(path, query, header, formData, body, _)
  let scheme = call_402656582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656582.makeUrl(scheme.get, call_402656582.host, call_402656582.base,
                                   call_402656582.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656582, uri, valid, _)

proc call*(call_402656583: Call_ListInvitations_402656569; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listInvitations
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token
  var query_402656584 = newJObject()
  var body_402656585 = newJObject()
  add(query_402656584, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656585 = body
  add(query_402656584, "NextToken", newJString(NextToken))
  result = call_402656583.call(nil, query_402656584, nil, nil, body_402656585)

var listInvitations* = Call_ListInvitations_402656569(name: "listInvitations",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitations/list", validator: validate_ListInvitations_402656570,
    base: "/", makeUrl: url_ListInvitations_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_402656586 = ref object of OpenApiRestCall_402656038
proc url_ListMembers_402656588(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_402656587(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656589 = query.getOrDefault("MaxResults")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "MaxResults", valid_402656589
  var valid_402656590 = query.getOrDefault("NextToken")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "NextToken", valid_402656590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
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

proc call*(call_402656599: Call_ListMembers_402656586; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
                                                                                         ## 
  let valid = call_402656599.validator(path, query, header, formData, body, _)
  let scheme = call_402656599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656599.makeUrl(scheme.get, call_402656599.host, call_402656599.base,
                                   call_402656599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656599, uri, valid, _)

proc call*(call_402656600: Call_ListMembers_402656586; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ##   
                                                                                                                                                                                                   ## MaxResults: string
                                                                                                                                                                                                   ##             
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                      ## token
  var query_402656601 = newJObject()
  var body_402656602 = newJObject()
  add(query_402656601, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656602 = body
  add(query_402656601, "NextToken", newJString(NextToken))
  result = call_402656600.call(nil, query_402656601, nil, nil, body_402656602)

var listMembers* = Call_ListMembers_402656586(name: "listMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/list", validator: validate_ListMembers_402656587,
    base: "/", makeUrl: url_ListMembers_402656588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_402656603 = ref object of OpenApiRestCall_402656038
proc url_RejectInvitation_402656605(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectInvitation_402656604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656606 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Security-Token", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Signature")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Signature", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Algorithm", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Date")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Date", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Credential")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Credential", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656612
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

proc call*(call_402656614: Call_RejectInvitation_402656603;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
                                                                                         ## 
  let valid = call_402656614.validator(path, query, header, formData, body, _)
  let scheme = call_402656614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656614.makeUrl(scheme.get, call_402656614.host, call_402656614.base,
                                   call_402656614.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656614, uri, valid, _)

proc call*(call_402656615: Call_RejectInvitation_402656603; body: JsonNode): Recallable =
  ## rejectInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ##   
                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656616 = newJObject()
  if body != nil:
    body_402656616 = body
  result = call_402656615.call(nil, nil, nil, nil, body_402656616)

var rejectInvitation* = Call_RejectInvitation_402656603(
    name: "rejectInvitation", meth: HttpMethod.HttpPost,
    host: "api.detective.amazonaws.com", route: "/invitation/removal",
    validator: validate_RejectInvitation_402656604, base: "/",
    makeUrl: url_RejectInvitation_402656605,
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