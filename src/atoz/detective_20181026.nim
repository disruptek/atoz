
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_605918 = ref object of OpenApiRestCall_605580
proc url_AcceptInvitation_605920(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_605919(path: JsonNode; query: JsonNode;
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
  var valid_606032 = header.getOrDefault("X-Amz-Signature")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "X-Amz-Signature", valid_606032
  var valid_606033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "X-Amz-Content-Sha256", valid_606033
  var valid_606034 = header.getOrDefault("X-Amz-Date")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "X-Amz-Date", valid_606034
  var valid_606035 = header.getOrDefault("X-Amz-Credential")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "X-Amz-Credential", valid_606035
  var valid_606036 = header.getOrDefault("X-Amz-Security-Token")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-Security-Token", valid_606036
  var valid_606037 = header.getOrDefault("X-Amz-Algorithm")
  valid_606037 = validateParameter(valid_606037, JString, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "X-Amz-Algorithm", valid_606037
  var valid_606038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-SignedHeaders", valid_606038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606062: Call_AcceptInvitation_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ## 
  let valid = call_606062.validator(path, query, header, formData, body)
  let scheme = call_606062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606062.url(scheme.get, call_606062.host, call_606062.base,
                         call_606062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606062, url, valid)

proc call*(call_606133: Call_AcceptInvitation_605918; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Accepts an invitation for the member account to contribute data to a behavior graph. This operation can only be called by an invited member account. </p> <p>The request provides the ARN of behavior graph.</p> <p>The member account status in the graph must be <code>INVITED</code>.</p>
  ##   body: JObject (required)
  var body_606134 = newJObject()
  if body != nil:
    body_606134 = body
  result = call_606133.call(nil, nil, nil, nil, body_606134)

var acceptInvitation* = Call_AcceptInvitation_605918(name: "acceptInvitation",
    meth: HttpMethod.HttpPut, host: "api.detective.amazonaws.com",
    route: "/invitation", validator: validate_AcceptInvitation_605919, base: "/",
    url: url_AcceptInvitation_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraph_606173 = ref object of OpenApiRestCall_605580
proc url_CreateGraph_606175(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGraph_606174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606176 = header.getOrDefault("X-Amz-Signature")
  valid_606176 = validateParameter(valid_606176, JString, required = false,
                                 default = nil)
  if valid_606176 != nil:
    section.add "X-Amz-Signature", valid_606176
  var valid_606177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606177 = validateParameter(valid_606177, JString, required = false,
                                 default = nil)
  if valid_606177 != nil:
    section.add "X-Amz-Content-Sha256", valid_606177
  var valid_606178 = header.getOrDefault("X-Amz-Date")
  valid_606178 = validateParameter(valid_606178, JString, required = false,
                                 default = nil)
  if valid_606178 != nil:
    section.add "X-Amz-Date", valid_606178
  var valid_606179 = header.getOrDefault("X-Amz-Credential")
  valid_606179 = validateParameter(valid_606179, JString, required = false,
                                 default = nil)
  if valid_606179 != nil:
    section.add "X-Amz-Credential", valid_606179
  var valid_606180 = header.getOrDefault("X-Amz-Security-Token")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "X-Amz-Security-Token", valid_606180
  var valid_606181 = header.getOrDefault("X-Amz-Algorithm")
  valid_606181 = validateParameter(valid_606181, JString, required = false,
                                 default = nil)
  if valid_606181 != nil:
    section.add "X-Amz-Algorithm", valid_606181
  var valid_606182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606182 = validateParameter(valid_606182, JString, required = false,
                                 default = nil)
  if valid_606182 != nil:
    section.add "X-Amz-SignedHeaders", valid_606182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606183: Call_CreateGraph_606173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  ## 
  let valid = call_606183.validator(path, query, header, formData, body)
  let scheme = call_606183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606183.url(scheme.get, call_606183.host, call_606183.base,
                         call_606183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606183, url, valid)

proc call*(call_606184: Call_CreateGraph_606173): Recallable =
  ## createGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Creates a new behavior graph for the calling account, and sets that account as the master account. This operation is called by the account that is enabling Detective.</p> <p>The operation also enables Detective for the calling account in the currently selected Region. It returns the ARN of the new behavior graph.</p> <p> <code>CreateGraph</code> triggers a process to create the corresponding data tables for the new behavior graph.</p> <p>An account can only be the master account for one behavior graph within a Region. If the same account calls <code>CreateGraph</code> with the same master account, it always returns the same behavior graph ARN. It does not create a new behavior graph.</p>
  result = call_606184.call(nil, nil, nil, nil, nil)

var createGraph* = Call_CreateGraph_606173(name: "createGraph",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph",
                                        validator: validate_CreateGraph_606174,
                                        base: "/", url: url_CreateGraph_606175,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_606185 = ref object of OpenApiRestCall_605580
proc url_CreateMembers_606187(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_606186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606188 = header.getOrDefault("X-Amz-Signature")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Signature", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Content-Sha256", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Date")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Date", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Credential")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Credential", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Security-Token")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Security-Token", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Algorithm")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Algorithm", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-SignedHeaders", valid_606194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606196: Call_CreateMembers_606185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ## 
  let valid = call_606196.validator(path, query, header, formData, body)
  let scheme = call_606196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606196.url(scheme.get, call_606196.host, call_606196.base,
                         call_606196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606196, url, valid)

proc call*(call_606197: Call_CreateMembers_606185; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Sends a request to invite the specified AWS accounts to be member accounts in the behavior graph. This operation can only be called by the master account for a behavior graph. </p> <p> <code>CreateMembers</code> verifies the accounts and then sends invitations to the verified accounts.</p> <p>The request provides the behavior graph ARN and the list of accounts to invite.</p> <p>The response separates the requested accounts into two lists:</p> <ul> <li> <p>The accounts that <code>CreateMembers</code> was able to start the verification for. This list includes member accounts that are being verified, that have passed verification and are being sent an invitation, and that have failed verification.</p> </li> <li> <p>The accounts that <code>CreateMembers</code> was unable to process. This list includes accounts that were already invited to be member accounts in the behavior graph.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606198 = newJObject()
  if body != nil:
    body_606198 = body
  result = call_606197.call(nil, nil, nil, nil, body_606198)

var createMembers* = Call_CreateMembers_606185(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members", validator: validate_CreateMembers_606186, base: "/",
    url: url_CreateMembers_606187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraph_606199 = ref object of OpenApiRestCall_605580
proc url_DeleteGraph_606201(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGraph_606200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606202 = header.getOrDefault("X-Amz-Signature")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Signature", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Content-Sha256", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Date")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Date", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Credential")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Credential", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Security-Token")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Security-Token", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Algorithm")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Algorithm", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-SignedHeaders", valid_606208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606210: Call_DeleteGraph_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ## 
  let valid = call_606210.validator(path, query, header, formData, body)
  let scheme = call_606210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606210.url(scheme.get, call_606210.host, call_606210.base,
                         call_606210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606210, url, valid)

proc call*(call_606211: Call_DeleteGraph_606199; body: JsonNode): Recallable =
  ## deleteGraph
  ## <p>Amazon Detective is currently in preview.</p> <p>Disables the specified behavior graph and queues it to be deleted. This operation removes the graph from each member account's list of behavior graphs.</p> <p> <code>DeleteGraph</code> can only be called by the master account for a behavior graph.</p>
  ##   body: JObject (required)
  var body_606212 = newJObject()
  if body != nil:
    body_606212 = body
  result = call_606211.call(nil, nil, nil, nil, body_606212)

var deleteGraph* = Call_DeleteGraph_606199(name: "deleteGraph",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph/removal",
                                        validator: validate_DeleteGraph_606200,
                                        base: "/", url: url_DeleteGraph_606201,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_606213 = ref object of OpenApiRestCall_605580
proc url_DeleteMembers_606215(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_606214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-SignedHeaders", valid_606222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_DeleteMembers_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_DeleteMembers_606213; body: JsonNode): Recallable =
  ## deleteMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Deletes one or more member accounts from the master account behavior graph. This operation can only be called by a Detective master account. That account cannot use <code>DeleteMembers</code> to delete their own account from the behavior graph. To disable a behavior graph, the master account uses the <code>DeleteGraph</code> API method.</p>
  ##   body: JObject (required)
  var body_606226 = newJObject()
  if body != nil:
    body_606226 = body
  result = call_606225.call(nil, nil, nil, nil, body_606226)

var deleteMembers* = Call_DeleteMembers_606213(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/graph/members/removal", validator: validate_DeleteMembers_606214,
    base: "/", url: url_DeleteMembers_606215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembership_606227 = ref object of OpenApiRestCall_605580
proc url_DisassociateMembership_606229(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembership_606228(path: JsonNode; query: JsonNode;
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
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DisassociateMembership_606227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DisassociateMembership_606227; body: JsonNode): Recallable =
  ## disassociateMembership
  ## <p>Amazon Detective is currently in preview.</p> <p>Removes the member account from the specified behavior graph. This operation can only be called by a member account that has the <code>ENABLED</code> status.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var disassociateMembership* = Call_DisassociateMembership_606227(
    name: "disassociateMembership", meth: HttpMethod.HttpPost,
    host: "api.detective.amazonaws.com", route: "/membership/removal",
    validator: validate_DisassociateMembership_606228, base: "/",
    url: url_DisassociateMembership_606229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_606241 = ref object of OpenApiRestCall_605580
proc url_GetMembers_606243(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_606242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606244 = header.getOrDefault("X-Amz-Signature")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Signature", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Content-Sha256", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Date")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Date", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Credential")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Credential", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Security-Token")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Security-Token", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Algorithm")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Algorithm", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-SignedHeaders", valid_606250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606252: Call_GetMembers_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ## 
  let valid = call_606252.validator(path, query, header, formData, body)
  let scheme = call_606252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606252.url(scheme.get, call_606252.host, call_606252.base,
                         call_606252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606252, url, valid)

proc call*(call_606253: Call_GetMembers_606241; body: JsonNode): Recallable =
  ## getMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the membership details for specified member accounts for a behavior graph.</p>
  ##   body: JObject (required)
  var body_606254 = newJObject()
  if body != nil:
    body_606254 = body
  result = call_606253.call(nil, nil, nil, nil, body_606254)

var getMembers* = Call_GetMembers_606241(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.detective.amazonaws.com",
                                      route: "/graph/members/get",
                                      validator: validate_GetMembers_606242,
                                      base: "/", url: url_GetMembers_606243,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphs_606255 = ref object of OpenApiRestCall_605580
proc url_ListGraphs_606257(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGraphs_606256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606258 = query.getOrDefault("MaxResults")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "MaxResults", valid_606258
  var valid_606259 = query.getOrDefault("NextToken")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "NextToken", valid_606259
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
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_ListGraphs_606255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_ListGraphs_606255; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGraphs
  ## <p>Amazon Detective is currently in preview.</p> <p>Returns the list of behavior graphs that the calling account is a master of. This operation can only be called by a master account.</p> <p>Because an account can currently only be the master of one behavior graph within a Region, the results always contain a single graph.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606270 = newJObject()
  var body_606271 = newJObject()
  add(query_606270, "MaxResults", newJString(MaxResults))
  add(query_606270, "NextToken", newJString(NextToken))
  if body != nil:
    body_606271 = body
  result = call_606269.call(nil, query_606270, nil, nil, body_606271)

var listGraphs* = Call_ListGraphs_606255(name: "listGraphs",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.detective.amazonaws.com",
                                      route: "/graphs/list",
                                      validator: validate_ListGraphs_606256,
                                      base: "/", url: url_ListGraphs_606257,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_606273 = ref object of OpenApiRestCall_605580
proc url_ListInvitations_606275(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_606274(path: JsonNode; query: JsonNode;
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
  var valid_606276 = query.getOrDefault("MaxResults")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "MaxResults", valid_606276
  var valid_606277 = query.getOrDefault("NextToken")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "NextToken", valid_606277
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
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606286: Call_ListInvitations_606273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ## 
  let valid = call_606286.validator(path, query, header, formData, body)
  let scheme = call_606286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606286.url(scheme.get, call_606286.host, call_606286.base,
                         call_606286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606286, url, valid)

proc call*(call_606287: Call_ListInvitations_606273; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listInvitations
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of open and accepted behavior graph invitations for the member account. This operation can only be called by a member account.</p> <p>Open invitations are invitations that the member account has not responded to.</p> <p>The results do not include behavior graphs for which the member account declined the invitation. The results also do not include behavior graphs that the member account resigned from or was removed from.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606288 = newJObject()
  var body_606289 = newJObject()
  add(query_606288, "MaxResults", newJString(MaxResults))
  add(query_606288, "NextToken", newJString(NextToken))
  if body != nil:
    body_606289 = body
  result = call_606287.call(nil, query_606288, nil, nil, body_606289)

var listInvitations* = Call_ListInvitations_606273(name: "listInvitations",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitations/list", validator: validate_ListInvitations_606274,
    base: "/", url: url_ListInvitations_606275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_606290 = ref object of OpenApiRestCall_605580
proc url_ListMembers_606292(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_606291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606293 = query.getOrDefault("MaxResults")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "MaxResults", valid_606293
  var valid_606294 = query.getOrDefault("NextToken")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "NextToken", valid_606294
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
  var valid_606295 = header.getOrDefault("X-Amz-Signature")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Signature", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Content-Sha256", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Date")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Date", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Credential")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Credential", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Security-Token")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Security-Token", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Algorithm")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Algorithm", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-SignedHeaders", valid_606301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606303: Call_ListMembers_606290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ## 
  let valid = call_606303.validator(path, query, header, formData, body)
  let scheme = call_606303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606303.url(scheme.get, call_606303.host, call_606303.base,
                         call_606303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606303, url, valid)

proc call*(call_606304: Call_ListMembers_606290; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMembers
  ## <p>Amazon Detective is currently in preview.</p> <p>Retrieves the list of member accounts for a behavior graph. Does not return member accounts that were removed from the behavior graph.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606305 = newJObject()
  var body_606306 = newJObject()
  add(query_606305, "MaxResults", newJString(MaxResults))
  add(query_606305, "NextToken", newJString(NextToken))
  if body != nil:
    body_606306 = body
  result = call_606304.call(nil, query_606305, nil, nil, body_606306)

var listMembers* = Call_ListMembers_606290(name: "listMembers",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.detective.amazonaws.com",
                                        route: "/graph/members/list",
                                        validator: validate_ListMembers_606291,
                                        base: "/", url: url_ListMembers_606292,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectInvitation_606307 = ref object of OpenApiRestCall_605580
proc url_RejectInvitation_606309(protocol: Scheme; host: string; base: string;
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

proc validate_RejectInvitation_606308(path: JsonNode; query: JsonNode;
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
  var valid_606310 = header.getOrDefault("X-Amz-Signature")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Signature", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Content-Sha256", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Date")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Date", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Credential")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Credential", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Security-Token")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Security-Token", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Algorithm")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Algorithm", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-SignedHeaders", valid_606316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606318: Call_RejectInvitation_606307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ## 
  let valid = call_606318.validator(path, query, header, formData, body)
  let scheme = call_606318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606318.url(scheme.get, call_606318.host, call_606318.base,
                         call_606318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606318, url, valid)

proc call*(call_606319: Call_RejectInvitation_606307; body: JsonNode): Recallable =
  ## rejectInvitation
  ## <p>Amazon Detective is currently in preview.</p> <p>Rejects an invitation to contribute the account data to a behavior graph. This operation must be called by a member account that has the <code>INVITED</code> status.</p>
  ##   body: JObject (required)
  var body_606320 = newJObject()
  if body != nil:
    body_606320 = body
  result = call_606319.call(nil, nil, nil, nil, body_606320)

var rejectInvitation* = Call_RejectInvitation_606307(name: "rejectInvitation",
    meth: HttpMethod.HttpPost, host: "api.detective.amazonaws.com",
    route: "/invitation/removal", validator: validate_RejectInvitation_606308,
    base: "/", url: url_RejectInvitation_606309,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
