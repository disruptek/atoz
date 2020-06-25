
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AcceptInvitation_21625770 = ref object of OpenApiRestCall_21625426
proc url_AcceptInvitation_21625772(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_21625771(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625875
  var valid_21625876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625876 = validateParameter(valid_21625876, JString, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Algorithm", valid_21625876
  var valid_21625877 = header.getOrDefault("X-Amz-Signature")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "X-Amz-Signature", valid_21625877
  var valid_21625878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625878 = validateParameter(valid_21625878, JString, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625878
  var valid_21625879 = header.getOrDefault("X-Amz-Credential")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Credential", valid_21625879
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

proc call*(call_21625905: Call_AcceptInvitation_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ## 
  let valid = call_21625905.validator(path, query, header, formData, body, _)
  let scheme = call_21625905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625905.makeUrl(scheme.get, call_21625905.host, call_21625905.base,
                               call_21625905.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625905, uri, valid, _)

proc call*(call_21625968: Call_AcceptInvitation_21625770; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ##   body: JObject (required)
  var body_21625969 = newJObject()
  if body != nil:
    body_21625969 = body
  result = call_21625968.call(nil, nil, nil, nil, body_21625969)

var acceptInvitation* = Call_AcceptInvitation_21625770(name: "acceptInvitation",
    meth: HttpMethod.HttpPut, host: "api.detective.amazonaws.com",
    route: "/invitation", validator: validate_AcceptInvitation_21625771, base: "/",
    makeUrl: url_AcceptInvitation_21625772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraph_21626005 = ref object of OpenApiRestCall_21625426
proc url_CreateGraph_21626007(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraph_21626006(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626008 = header.getOrDefault("X-Amz-Date")
  valid_21626008 = validateParameter(valid_21626008, JString, required = false,
                                   default = nil)
  if valid_21626008 != nil:
    section.add "X-Amz-Date", valid_21626008
  var valid_21626009 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Security-Token", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Algorithm", valid_21626011
  var valid_21626012 = header.getOrDefault("X-Amz-Signature")
  valid_21626012 = validateParameter(valid_21626012, JString, required = false,
                                   default = nil)
  if valid_21626012 != nil:
    section.add "X-Amz-Signature", valid_21626012
  var valid_21626013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Credential")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Credential", valid_21626014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626015: Call_CreateGraph_21626005; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  ## 
  let valid = call_21626015.validator(path, query, header, formData, body, _)
  let scheme = call_21626015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626015.makeUrl(scheme.get, call_21626015.host, call_21626015.base,
                               call_21626015.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626015, uri, valid, _)

proc call*(call_21626016: Call_CreateGraph_21626005): Recallable =
  ## createGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  result = call_21626016.call(nil, nil, nil, nil, nil)

var createGraph* = Call_CreateGraph_21626005(name: "createGraph",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com", route: "/graph",
    validator: validate_CreateGraph_21626006, base: "/", makeUrl: url_CreateGraph_21626007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_21626017 = ref object of OpenApiRestCall_21625426
proc url_CreateMembers_21626019(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_21626018(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626020 = header.getOrDefault("X-Amz-Date")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Date", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Security-Token", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Algorithm", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Signature")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Signature", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Credential")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Credential", valid_21626026
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

proc call*(call_21626028: Call_CreateMembers_21626017; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ## 
  let valid = call_21626028.validator(path, query, header, formData, body, _)
  let scheme = call_21626028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626028.makeUrl(scheme.get, call_21626028.host, call_21626028.base,
                               call_21626028.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626028, uri, valid, _)

proc call*(call_21626029: Call_CreateMembers_21626017; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626030 = newJObject()
  if body != nil:
    body_21626030 = body
  result = call_21626029.call(nil, nil, nil, nil, body_21626030)

var createMembers* = Call_CreateMembers_21626017(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members", validator: validate_CreateMembers_21626018, base: "/",
    makeUrl: url_CreateMembers_21626019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraph_21626031 = ref object of OpenApiRestCall_21625426
proc url_DeleteGraph_21626033(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGraph_21626032(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
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

proc call*(call_21626042: Call_DeleteGraph_21626031; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ## 
  let valid = call_21626042.validator(path, query, header, formData, body, _)
  let scheme = call_21626042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626042.makeUrl(scheme.get, call_21626042.host, call_21626042.base,
                               call_21626042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626042, uri, valid, _)

proc call*(call_21626043: Call_DeleteGraph_21626031; body: JsonNode): Recallable =
  ## deleteGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ##   body: JObject (required)
  var body_21626044 = newJObject()
  if body != nil:
    body_21626044 = body
  result = call_21626043.call(nil, nil, nil, nil, body_21626044)

var deleteGraph* = Call_DeleteGraph_21626031(name: "deleteGraph",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/removal", validator: validate_DeleteGraph_21626032, base: "/",
    makeUrl: url_DeleteGraph_21626033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_21626045 = ref object of OpenApiRestCall_21625426
proc url_DeleteMembers_21626047(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_21626046(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626048 = header.getOrDefault("X-Amz-Date")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Date", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Security-Token", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_DeleteMembers_21626045; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_DeleteMembers_21626045; body: JsonNode): Recallable =
  ## deleteMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var deleteMembers* = Call_DeleteMembers_21626045(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/removal", validator: validate_DeleteMembers_21626046,
    base: "/", makeUrl: url_DeleteMembers_21626047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembership_21626059 = ref object of OpenApiRestCall_21625426
proc url_DisassociateMembership_21626061(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembership_21626060(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Algorithm", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Signature")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Signature", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Credential")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Credential", valid_21626068
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

proc call*(call_21626070: Call_DisassociateMembership_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_DisassociateMembership_21626059; body: JsonNode): Recallable =
  ## disassociateMembership
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ##   body: JObject (required)
  var body_21626072 = newJObject()
  if body != nil:
    body_21626072 = body
  result = call_21626071.call(nil, nil, nil, nil, body_21626072)

var disassociateMembership* = Call_DisassociateMembership_21626059(
    name: "disassociateMembership", meth: HttpMethod.HttpPost,
    host: "api.detective.amazonaws.com", route: "/membership/removal",
    validator: validate_DisassociateMembership_21626060, base: "/",
    makeUrl: url_DisassociateMembership_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_21626073 = ref object of OpenApiRestCall_21625426
proc url_GetMembers_21626075(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_21626074(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626076 = header.getOrDefault("X-Amz-Date")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Date", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Security-Token", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Algorithm", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Signature")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Signature", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Credential")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Credential", valid_21626082
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

proc call*(call_21626084: Call_GetMembers_21626073; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ## 
  let valid = call_21626084.validator(path, query, header, formData, body, _)
  let scheme = call_21626084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626084.makeUrl(scheme.get, call_21626084.host, call_21626084.base,
                               call_21626084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626084, uri, valid, _)

proc call*(call_21626085: Call_GetMembers_21626073; body: JsonNode): Recallable =
  ## getMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ##   body: JObject (required)
  var body_21626086 = newJObject()
  if body != nil:
    body_21626086 = body
  result = call_21626085.call(nil, nil, nil, nil, body_21626086)

var getMembers* = Call_GetMembers_21626073(name: "getMembers",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph/members/get",
                                        validator: validate_GetMembers_21626074,
                                        base: "/", makeUrl: url_GetMembers_21626075,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphs_21626087 = ref object of OpenApiRestCall_21625426
proc url_ListGraphs_21626089(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphs_21626088(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626090 = query.getOrDefault("NextToken")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "NextToken", valid_21626090
  var valid_21626091 = query.getOrDefault("MaxResults")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "MaxResults", valid_21626091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Algorithm", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Signature")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Signature", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Credential")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Credential", valid_21626098
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

proc call*(call_21626100: Call_ListGraphs_21626087; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ## 
  let valid = call_21626100.validator(path, query, header, formData, body, _)
  let scheme = call_21626100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626100.makeUrl(scheme.get, call_21626100.host, call_21626100.base,
                               call_21626100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626100, uri, valid, _)

proc call*(call_21626101: Call_ListGraphs_21626087; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listGraphs
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626103 = newJObject()
  var body_21626104 = newJObject()
  add(query_21626103, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626104 = body
  add(query_21626103, "MaxResults", newJString(MaxResults))
  result = call_21626101.call(nil, query_21626103, nil, nil, body_21626104)

var listGraphs* = Call_ListGraphs_21626087(name: "listGraphs",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graphs/list",
                                        validator: validate_ListGraphs_21626088,
                                        base: "/", makeUrl: url_ListGraphs_21626089,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_21626108 = ref object of OpenApiRestCall_21625426
proc url_ListInvitations_21626110(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_21626109(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626111 = query.getOrDefault("NextToken")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "NextToken", valid_21626111
  var valid_21626112 = query.getOrDefault("MaxResults")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "MaxResults", valid_21626112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626113 = header.getOrDefault("X-Amz-Date")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Date", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Security-Token", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Algorithm", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Signature")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Signature", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Credential")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Credential", valid_21626119
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

proc call*(call_21626121: Call_ListInvitations_21626108; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ## 
  let valid = call_21626121.validator(path, query, header, formData, body, _)
  let scheme = call_21626121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626121.makeUrl(scheme.get, call_21626121.host, call_21626121.base,
                               call_21626121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626121, uri, valid, _)

proc call*(call_21626122: Call_ListInvitations_21626108; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInvitations
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626123 = newJObject()
  var body_21626124 = newJObject()
  add(query_21626123, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626124 = body
  add(query_21626123, "MaxResults", newJString(MaxResults))
  result = call_21626122.call(nil, query_21626123, nil, nil, body_21626124)

var listInvitations* = Call_ListInvitations_21626108(name: "listInvitations",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitations/list", validator: validate_ListInvitations_21626109,
    base: "/", makeUrl: url_ListInvitations_21626110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_21626125 = ref object of OpenApiRestCall_21625426
proc url_ListMembers_21626127(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_21626126(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626128 = query.getOrDefault("NextToken")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "NextToken", valid_21626128
  var valid_21626129 = query.getOrDefault("MaxResults")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "MaxResults", valid_21626129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626130 = header.getOrDefault("X-Amz-Date")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Date", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Security-Token", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Algorithm", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Signature")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Signature", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Credential")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Credential", valid_21626136
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

proc call*(call_21626138: Call_ListMembers_21626125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ## 
  let valid = call_21626138.validator(path, query, header, formData, body, _)
  let scheme = call_21626138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626138.makeUrl(scheme.get, call_21626138.host, call_21626138.base,
                               call_21626138.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626138, uri, valid, _)

proc call*(call_21626139: Call_ListMembers_21626125; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626140 = newJObject()
  var body_21626141 = newJObject()
  add(query_21626140, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626141 = body
  add(query_21626140, "MaxResults", newJString(MaxResults))
  result = call_21626139.call(nil, query_21626140, nil, nil, body_21626141)

var listMembers* = Call_ListMembers_21626125(name: "listMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/list", validator: validate_ListMembers_21626126,
    base: "/", makeUrl: url_ListMembers_21626127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_21626142 = ref object of OpenApiRestCall_21625426
proc url_RejectInvitation_21626144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectInvitation_21626143(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626145 = header.getOrDefault("X-Amz-Date")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Date", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Security-Token", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Algorithm", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Signature")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Signature", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Credential")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Credential", valid_21626151
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

proc call*(call_21626153: Call_RejectInvitation_21626142; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ## 
  let valid = call_21626153.validator(path, query, header, formData, body, _)
  let scheme = call_21626153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626153.makeUrl(scheme.get, call_21626153.host, call_21626153.base,
                               call_21626153.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626153, uri, valid, _)

proc call*(call_21626154: Call_RejectInvitation_21626142; body: JsonNode): Recallable =
  ## rejectInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ##   body: JObject (required)
  var body_21626155 = newJObject()
  if body != nil:
    body_21626155 = body
  result = call_21626154.call(nil, nil, nil, nil, body_21626155)

var rejectInvitation* = Call_RejectInvitation_21626142(name: "rejectInvitation",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitation/removal", validator: validate_RejectInvitation_21626143,
    base: "/", makeUrl: url_RejectInvitation_21626144,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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