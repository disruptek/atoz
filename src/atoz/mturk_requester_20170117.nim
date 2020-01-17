
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Mechanical Turk
## version: 2017-01-17
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Mechanical Turk API Reference</fullname>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mturk-requester/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mturk-requester.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mturk-requester.ap-southeast-1.amazonaws.com", "us-west-2": "mturk-requester.us-west-2.amazonaws.com", "eu-west-2": "mturk-requester.eu-west-2.amazonaws.com", "ap-northeast-3": "mturk-requester.ap-northeast-3.amazonaws.com", "eu-central-1": "mturk-requester.eu-central-1.amazonaws.com", "us-east-2": "mturk-requester.us-east-2.amazonaws.com", "us-east-1": "mturk-requester.us-east-1.amazonaws.com", "cn-northwest-1": "mturk-requester.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mturk-requester.ap-south-1.amazonaws.com", "eu-north-1": "mturk-requester.eu-north-1.amazonaws.com", "ap-northeast-2": "mturk-requester.ap-northeast-2.amazonaws.com", "us-west-1": "mturk-requester.us-west-1.amazonaws.com", "us-gov-east-1": "mturk-requester.us-gov-east-1.amazonaws.com", "eu-west-3": "mturk-requester.eu-west-3.amazonaws.com", "cn-north-1": "mturk-requester.cn-north-1.amazonaws.com.cn", "sa-east-1": "mturk-requester.sa-east-1.amazonaws.com", "eu-west-1": "mturk-requester.eu-west-1.amazonaws.com", "us-gov-west-1": "mturk-requester.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mturk-requester.ap-southeast-2.amazonaws.com", "ca-central-1": "mturk-requester.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mturk-requester.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mturk-requester.ap-southeast-1.amazonaws.com",
      "us-west-2": "mturk-requester.us-west-2.amazonaws.com",
      "eu-west-2": "mturk-requester.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mturk-requester.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mturk-requester.eu-central-1.amazonaws.com",
      "us-east-2": "mturk-requester.us-east-2.amazonaws.com",
      "us-east-1": "mturk-requester.us-east-1.amazonaws.com",
      "cn-northwest-1": "mturk-requester.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mturk-requester.ap-south-1.amazonaws.com",
      "eu-north-1": "mturk-requester.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mturk-requester.ap-northeast-2.amazonaws.com",
      "us-west-1": "mturk-requester.us-west-1.amazonaws.com",
      "us-gov-east-1": "mturk-requester.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mturk-requester.eu-west-3.amazonaws.com",
      "cn-north-1": "mturk-requester.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mturk-requester.sa-east-1.amazonaws.com",
      "eu-west-1": "mturk-requester.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mturk-requester.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mturk-requester.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mturk-requester.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mturk-requester"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptQualificationRequest_605927 = ref object of OpenApiRestCall_605589
proc url_AcceptQualificationRequest_605929(protocol: Scheme; host: string;
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

proc validate_AcceptQualificationRequest_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AcceptQualificationRequest"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AcceptQualificationRequest_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AcceptQualificationRequest_605927; body: JsonNode): Recallable =
  ## acceptQualificationRequest
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var acceptQualificationRequest* = Call_AcceptQualificationRequest_605927(
    name: "acceptQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AcceptQualificationRequest",
    validator: validate_AcceptQualificationRequest_605928, base: "/",
    url: url_AcceptQualificationRequest_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApproveAssignment_606196 = ref object of OpenApiRestCall_605589
proc url_ApproveAssignment_606198(protocol: Scheme; host: string; base: string;
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

proc validate_ApproveAssignment_606197(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ApproveAssignment"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_ApproveAssignment_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_ApproveAssignment_606196; body: JsonNode): Recallable =
  ## approveAssignment
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var approveAssignment* = Call_ApproveAssignment_606196(name: "approveAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ApproveAssignment",
    validator: validate_ApproveAssignment_606197, base: "/",
    url: url_ApproveAssignment_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateQualificationWithWorker_606211 = ref object of OpenApiRestCall_605589
proc url_AssociateQualificationWithWorker_606213(protocol: Scheme; host: string;
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

proc validate_AssociateQualificationWithWorker_606212(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AssociateQualificationWithWorker"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_AssociateQualificationWithWorker_606211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_AssociateQualificationWithWorker_606211;
          body: JsonNode): Recallable =
  ## associateQualificationWithWorker
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var associateQualificationWithWorker* = Call_AssociateQualificationWithWorker_606211(
    name: "associateQualificationWithWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AssociateQualificationWithWorker",
    validator: validate_AssociateQualificationWithWorker_606212, base: "/",
    url: url_AssociateQualificationWithWorker_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAdditionalAssignmentsForHIT_606226 = ref object of OpenApiRestCall_605589
proc url_CreateAdditionalAssignmentsForHIT_606228(protocol: Scheme; host: string;
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

proc validate_CreateAdditionalAssignmentsForHIT_606227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
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

proc call*(call_606238: Call_CreateAdditionalAssignmentsForHIT_606226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateAdditionalAssignmentsForHIT_606226;
          body: JsonNode): Recallable =
  ## createAdditionalAssignmentsForHIT
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createAdditionalAssignmentsForHIT* = Call_CreateAdditionalAssignmentsForHIT_606226(
    name: "createAdditionalAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT",
    validator: validate_CreateAdditionalAssignmentsForHIT_606227, base: "/",
    url: url_CreateAdditionalAssignmentsForHIT_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHIT_606241 = ref object of OpenApiRestCall_605589
proc url_CreateHIT_606243(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateHIT_606242(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHIT"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_CreateHIT_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_CreateHIT_606241; body: JsonNode): Recallable =
  ## createHIT
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var createHIT* = Call_CreateHIT_606241(name: "createHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHIT",
                                    validator: validate_CreateHIT_606242,
                                    base: "/", url: url_CreateHIT_606243,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITType_606256 = ref object of OpenApiRestCall_605589
proc url_CreateHITType_606258(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHITType_606257(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITType"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
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

proc call*(call_606268: Call_CreateHITType_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_CreateHITType_606256; body: JsonNode): Recallable =
  ## createHITType
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var createHITType* = Call_CreateHITType_606256(name: "createHITType",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITType",
    validator: validate_CreateHITType_606257, base: "/", url: url_CreateHITType_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITWithHITType_606271 = ref object of OpenApiRestCall_605589
proc url_CreateHITWithHITType_606273(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHITWithHITType_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITWithHITType"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_CreateHITWithHITType_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_CreateHITWithHITType_606271; body: JsonNode): Recallable =
  ## createHITWithHITType
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var createHITWithHITType* = Call_CreateHITWithHITType_606271(
    name: "createHITWithHITType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITWithHITType",
    validator: validate_CreateHITWithHITType_606272, base: "/",
    url: url_CreateHITWithHITType_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQualificationType_606286 = ref object of OpenApiRestCall_605589
proc url_CreateQualificationType_606288(protocol: Scheme; host: string; base: string;
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

proc validate_CreateQualificationType_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateQualificationType"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_CreateQualificationType_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_CreateQualificationType_606286; body: JsonNode): Recallable =
  ## createQualificationType
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var createQualificationType* = Call_CreateQualificationType_606286(
    name: "createQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateQualificationType",
    validator: validate_CreateQualificationType_606287, base: "/",
    url: url_CreateQualificationType_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkerBlock_606301 = ref object of OpenApiRestCall_605589
proc url_CreateWorkerBlock_606303(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkerBlock_606302(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateWorkerBlock"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_CreateWorkerBlock_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateWorkerBlock_606301; body: JsonNode): Recallable =
  ## createWorkerBlock
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createWorkerBlock* = Call_CreateWorkerBlock_606301(name: "createWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateWorkerBlock",
    validator: validate_CreateWorkerBlock_606302, base: "/",
    url: url_CreateWorkerBlock_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHIT_606316 = ref object of OpenApiRestCall_605589
proc url_DeleteHIT_606318(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteHIT_606317(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteHIT"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DeleteHIT_606316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DeleteHIT_606316; body: JsonNode): Recallable =
  ## deleteHIT
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var deleteHIT* = Call_DeleteHIT_606316(name: "deleteHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteHIT",
                                    validator: validate_DeleteHIT_606317,
                                    base: "/", url: url_DeleteHIT_606318,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQualificationType_606331 = ref object of OpenApiRestCall_605589
proc url_DeleteQualificationType_606333(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteQualificationType_606332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteQualificationType"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DeleteQualificationType_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DeleteQualificationType_606331; body: JsonNode): Recallable =
  ## deleteQualificationType
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var deleteQualificationType* = Call_DeleteQualificationType_606331(
    name: "deleteQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteQualificationType",
    validator: validate_DeleteQualificationType_606332, base: "/",
    url: url_DeleteQualificationType_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkerBlock_606346 = ref object of OpenApiRestCall_605589
proc url_DeleteWorkerBlock_606348(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkerBlock_606347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteWorkerBlock"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
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

proc call*(call_606358: Call_DeleteWorkerBlock_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_DeleteWorkerBlock_606346; body: JsonNode): Recallable =
  ## deleteWorkerBlock
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var deleteWorkerBlock* = Call_DeleteWorkerBlock_606346(name: "deleteWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteWorkerBlock",
    validator: validate_DeleteWorkerBlock_606347, base: "/",
    url: url_DeleteWorkerBlock_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateQualificationFromWorker_606361 = ref object of OpenApiRestCall_605589
proc url_DisassociateQualificationFromWorker_606363(protocol: Scheme; host: string;
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

proc validate_DisassociateQualificationFromWorker_606362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_DisassociateQualificationFromWorker_606361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_DisassociateQualificationFromWorker_606361;
          body: JsonNode): Recallable =
  ## disassociateQualificationFromWorker
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var disassociateQualificationFromWorker* = Call_DisassociateQualificationFromWorker_606361(
    name: "disassociateQualificationFromWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker",
    validator: validate_DisassociateQualificationFromWorker_606362, base: "/",
    url: url_DisassociateQualificationFromWorker_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountBalance_606376 = ref object of OpenApiRestCall_605589
proc url_GetAccountBalance_606378(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountBalance_606377(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAccountBalance"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_GetAccountBalance_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_GetAccountBalance_606376; body: JsonNode): Recallable =
  ## getAccountBalance
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var getAccountBalance* = Call_GetAccountBalance_606376(name: "getAccountBalance",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAccountBalance",
    validator: validate_GetAccountBalance_606377, base: "/",
    url: url_GetAccountBalance_606378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssignment_606391 = ref object of OpenApiRestCall_605589
proc url_GetAssignment_606393(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssignment_606392(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAssignment"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_GetAssignment_606391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_GetAssignment_606391; body: JsonNode): Recallable =
  ## getAssignment
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var getAssignment* = Call_GetAssignment_606391(name: "getAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAssignment",
    validator: validate_GetAssignment_606392, base: "/", url: url_GetAssignment_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFileUploadURL_606406 = ref object of OpenApiRestCall_605589
proc url_GetFileUploadURL_606408(protocol: Scheme; host: string; base: string;
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

proc validate_GetFileUploadURL_606407(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
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
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetFileUploadURL"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_GetFileUploadURL_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_GetFileUploadURL_606406; body: JsonNode): Recallable =
  ## getFileUploadURL
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var getFileUploadURL* = Call_GetFileUploadURL_606406(name: "getFileUploadURL",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetFileUploadURL",
    validator: validate_GetFileUploadURL_606407, base: "/",
    url: url_GetFileUploadURL_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHIT_606421 = ref object of OpenApiRestCall_605589
proc url_GetHIT_606423(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetHIT_606422(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
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
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetHIT"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_GetHIT_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_GetHIT_606421; body: JsonNode): Recallable =
  ## getHIT
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var getHIT* = Call_GetHIT_606421(name: "getHIT", meth: HttpMethod.HttpPost,
                              host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetHIT",
                              validator: validate_GetHIT_606422, base: "/",
                              url: url_GetHIT_606423,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationScore_606436 = ref object of OpenApiRestCall_605589
proc url_GetQualificationScore_606438(protocol: Scheme; host: string; base: string;
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

proc validate_GetQualificationScore_606437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationScore"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_GetQualificationScore_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_GetQualificationScore_606436; body: JsonNode): Recallable =
  ## getQualificationScore
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var getQualificationScore* = Call_GetQualificationScore_606436(
    name: "getQualificationScore", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationScore",
    validator: validate_GetQualificationScore_606437, base: "/",
    url: url_GetQualificationScore_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationType_606451 = ref object of OpenApiRestCall_605589
proc url_GetQualificationType_606453(protocol: Scheme; host: string; base: string;
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

proc validate_GetQualificationType_606452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationType"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_GetQualificationType_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_GetQualificationType_606451; body: JsonNode): Recallable =
  ## getQualificationType
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var getQualificationType* = Call_GetQualificationType_606451(
    name: "getQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationType",
    validator: validate_GetQualificationType_606452, base: "/",
    url: url_GetQualificationType_606453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssignmentsForHIT_606466 = ref object of OpenApiRestCall_605589
proc url_ListAssignmentsForHIT_606468(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssignmentsForHIT_606467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
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
  var valid_606469 = query.getOrDefault("MaxResults")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "MaxResults", valid_606469
  var valid_606470 = query.getOrDefault("NextToken")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "NextToken", valid_606470
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
  var valid_606471 = header.getOrDefault("X-Amz-Target")
  valid_606471 = validateParameter(valid_606471, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListAssignmentsForHIT"))
  if valid_606471 != nil:
    section.add "X-Amz-Target", valid_606471
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

proc call*(call_606480: Call_ListAssignmentsForHIT_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_ListAssignmentsForHIT_606466; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssignmentsForHIT
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606482 = newJObject()
  var body_606483 = newJObject()
  add(query_606482, "MaxResults", newJString(MaxResults))
  add(query_606482, "NextToken", newJString(NextToken))
  if body != nil:
    body_606483 = body
  result = call_606481.call(nil, query_606482, nil, nil, body_606483)

var listAssignmentsForHIT* = Call_ListAssignmentsForHIT_606466(
    name: "listAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListAssignmentsForHIT",
    validator: validate_ListAssignmentsForHIT_606467, base: "/",
    url: url_ListAssignmentsForHIT_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBonusPayments_606485 = ref object of OpenApiRestCall_605589
proc url_ListBonusPayments_606487(protocol: Scheme; host: string; base: string;
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

proc validate_ListBonusPayments_606486(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
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
  var valid_606488 = query.getOrDefault("MaxResults")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "MaxResults", valid_606488
  var valid_606489 = query.getOrDefault("NextToken")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "NextToken", valid_606489
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
  var valid_606490 = header.getOrDefault("X-Amz-Target")
  valid_606490 = validateParameter(valid_606490, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListBonusPayments"))
  if valid_606490 != nil:
    section.add "X-Amz-Target", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Signature")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Signature", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Content-Sha256", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Date")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Date", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Credential")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Credential", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Security-Token")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Security-Token", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Algorithm")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Algorithm", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-SignedHeaders", valid_606497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606499: Call_ListBonusPayments_606485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ## 
  let valid = call_606499.validator(path, query, header, formData, body)
  let scheme = call_606499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606499.url(scheme.get, call_606499.host, call_606499.base,
                         call_606499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606499, url, valid)

proc call*(call_606500: Call_ListBonusPayments_606485; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listBonusPayments
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606501 = newJObject()
  var body_606502 = newJObject()
  add(query_606501, "MaxResults", newJString(MaxResults))
  add(query_606501, "NextToken", newJString(NextToken))
  if body != nil:
    body_606502 = body
  result = call_606500.call(nil, query_606501, nil, nil, body_606502)

var listBonusPayments* = Call_ListBonusPayments_606485(name: "listBonusPayments",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListBonusPayments",
    validator: validate_ListBonusPayments_606486, base: "/",
    url: url_ListBonusPayments_606487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITs_606503 = ref object of OpenApiRestCall_605589
proc url_ListHITs_606505(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListHITs_606504(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
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
  var valid_606506 = query.getOrDefault("MaxResults")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "MaxResults", valid_606506
  var valid_606507 = query.getOrDefault("NextToken")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "NextToken", valid_606507
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
  var valid_606508 = header.getOrDefault("X-Amz-Target")
  valid_606508 = validateParameter(valid_606508, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITs"))
  if valid_606508 != nil:
    section.add "X-Amz-Target", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Signature")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Signature", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Content-Sha256", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Date")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Date", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Credential")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Credential", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Security-Token")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Security-Token", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Algorithm")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Algorithm", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-SignedHeaders", valid_606515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606517: Call_ListHITs_606503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ## 
  let valid = call_606517.validator(path, query, header, formData, body)
  let scheme = call_606517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606517.url(scheme.get, call_606517.host, call_606517.base,
                         call_606517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606517, url, valid)

proc call*(call_606518: Call_ListHITs_606503; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHITs
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606519 = newJObject()
  var body_606520 = newJObject()
  add(query_606519, "MaxResults", newJString(MaxResults))
  add(query_606519, "NextToken", newJString(NextToken))
  if body != nil:
    body_606520 = body
  result = call_606518.call(nil, query_606519, nil, nil, body_606520)

var listHITs* = Call_ListHITs_606503(name: "listHITs", meth: HttpMethod.HttpPost,
                                  host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITs",
                                  validator: validate_ListHITs_606504, base: "/",
                                  url: url_ListHITs_606505,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITsForQualificationType_606521 = ref object of OpenApiRestCall_605589
proc url_ListHITsForQualificationType_606523(protocol: Scheme; host: string;
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

proc validate_ListHITsForQualificationType_606522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
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
  var valid_606524 = query.getOrDefault("MaxResults")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "MaxResults", valid_606524
  var valid_606525 = query.getOrDefault("NextToken")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "NextToken", valid_606525
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
  var valid_606526 = header.getOrDefault("X-Amz-Target")
  valid_606526 = validateParameter(valid_606526, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITsForQualificationType"))
  if valid_606526 != nil:
    section.add "X-Amz-Target", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Signature")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Signature", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Content-Sha256", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Date")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Date", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Credential")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Credential", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_ListHITsForQualificationType_606521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_ListHITsForQualificationType_606521; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHITsForQualificationType
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606537 = newJObject()
  var body_606538 = newJObject()
  add(query_606537, "MaxResults", newJString(MaxResults))
  add(query_606537, "NextToken", newJString(NextToken))
  if body != nil:
    body_606538 = body
  result = call_606536.call(nil, query_606537, nil, nil, body_606538)

var listHITsForQualificationType* = Call_ListHITsForQualificationType_606521(
    name: "listHITsForQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITsForQualificationType",
    validator: validate_ListHITsForQualificationType_606522, base: "/",
    url: url_ListHITsForQualificationType_606523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationRequests_606539 = ref object of OpenApiRestCall_605589
proc url_ListQualificationRequests_606541(protocol: Scheme; host: string;
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

proc validate_ListQualificationRequests_606540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
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
  var valid_606542 = query.getOrDefault("MaxResults")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "MaxResults", valid_606542
  var valid_606543 = query.getOrDefault("NextToken")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "NextToken", valid_606543
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationRequests"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_ListQualificationRequests_606539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_ListQualificationRequests_606539; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listQualificationRequests
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606555 = newJObject()
  var body_606556 = newJObject()
  add(query_606555, "MaxResults", newJString(MaxResults))
  add(query_606555, "NextToken", newJString(NextToken))
  if body != nil:
    body_606556 = body
  result = call_606554.call(nil, query_606555, nil, nil, body_606556)

var listQualificationRequests* = Call_ListQualificationRequests_606539(
    name: "listQualificationRequests", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationRequests",
    validator: validate_ListQualificationRequests_606540, base: "/",
    url: url_ListQualificationRequests_606541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationTypes_606557 = ref object of OpenApiRestCall_605589
proc url_ListQualificationTypes_606559(protocol: Scheme; host: string; base: string;
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

proc validate_ListQualificationTypes_606558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
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
  var valid_606560 = query.getOrDefault("MaxResults")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "MaxResults", valid_606560
  var valid_606561 = query.getOrDefault("NextToken")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "NextToken", valid_606561
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
  var valid_606562 = header.getOrDefault("X-Amz-Target")
  valid_606562 = validateParameter(valid_606562, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationTypes"))
  if valid_606562 != nil:
    section.add "X-Amz-Target", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Signature")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Signature", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Content-Sha256", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Date")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Date", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Credential")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Credential", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606571: Call_ListQualificationTypes_606557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ## 
  let valid = call_606571.validator(path, query, header, formData, body)
  let scheme = call_606571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606571.url(scheme.get, call_606571.host, call_606571.base,
                         call_606571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606571, url, valid)

proc call*(call_606572: Call_ListQualificationTypes_606557; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listQualificationTypes
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606573 = newJObject()
  var body_606574 = newJObject()
  add(query_606573, "MaxResults", newJString(MaxResults))
  add(query_606573, "NextToken", newJString(NextToken))
  if body != nil:
    body_606574 = body
  result = call_606572.call(nil, query_606573, nil, nil, body_606574)

var listQualificationTypes* = Call_ListQualificationTypes_606557(
    name: "listQualificationTypes", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationTypes",
    validator: validate_ListQualificationTypes_606558, base: "/",
    url: url_ListQualificationTypes_606559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewPolicyResultsForHIT_606575 = ref object of OpenApiRestCall_605589
proc url_ListReviewPolicyResultsForHIT_606577(protocol: Scheme; host: string;
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

proc validate_ListReviewPolicyResultsForHIT_606576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
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
  var valid_606578 = query.getOrDefault("MaxResults")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "MaxResults", valid_606578
  var valid_606579 = query.getOrDefault("NextToken")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "NextToken", valid_606579
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
  var valid_606580 = header.getOrDefault("X-Amz-Target")
  valid_606580 = validateParameter(valid_606580, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT"))
  if valid_606580 != nil:
    section.add "X-Amz-Target", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_ListReviewPolicyResultsForHIT_606575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_ListReviewPolicyResultsForHIT_606575; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listReviewPolicyResultsForHIT
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606591 = newJObject()
  var body_606592 = newJObject()
  add(query_606591, "MaxResults", newJString(MaxResults))
  add(query_606591, "NextToken", newJString(NextToken))
  if body != nil:
    body_606592 = body
  result = call_606590.call(nil, query_606591, nil, nil, body_606592)

var listReviewPolicyResultsForHIT* = Call_ListReviewPolicyResultsForHIT_606575(
    name: "listReviewPolicyResultsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT",
    validator: validate_ListReviewPolicyResultsForHIT_606576, base: "/",
    url: url_ListReviewPolicyResultsForHIT_606577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewableHITs_606593 = ref object of OpenApiRestCall_605589
proc url_ListReviewableHITs_606595(protocol: Scheme; host: string; base: string;
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

proc validate_ListReviewableHITs_606594(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
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
  var valid_606596 = query.getOrDefault("MaxResults")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "MaxResults", valid_606596
  var valid_606597 = query.getOrDefault("NextToken")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "NextToken", valid_606597
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
  var valid_606598 = header.getOrDefault("X-Amz-Target")
  valid_606598 = validateParameter(valid_606598, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewableHITs"))
  if valid_606598 != nil:
    section.add "X-Amz-Target", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Signature")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Signature", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Content-Sha256", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Date")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Date", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Credential")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Credential", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Security-Token")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Security-Token", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Algorithm")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Algorithm", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-SignedHeaders", valid_606605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606607: Call_ListReviewableHITs_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ## 
  let valid = call_606607.validator(path, query, header, formData, body)
  let scheme = call_606607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606607.url(scheme.get, call_606607.host, call_606607.base,
                         call_606607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606607, url, valid)

proc call*(call_606608: Call_ListReviewableHITs_606593; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listReviewableHITs
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606609 = newJObject()
  var body_606610 = newJObject()
  add(query_606609, "MaxResults", newJString(MaxResults))
  add(query_606609, "NextToken", newJString(NextToken))
  if body != nil:
    body_606610 = body
  result = call_606608.call(nil, query_606609, nil, nil, body_606610)

var listReviewableHITs* = Call_ListReviewableHITs_606593(
    name: "listReviewableHITs", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewableHITs",
    validator: validate_ListReviewableHITs_606594, base: "/",
    url: url_ListReviewableHITs_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkerBlocks_606611 = ref object of OpenApiRestCall_605589
proc url_ListWorkerBlocks_606613(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkerBlocks_606612(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
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
  var valid_606614 = query.getOrDefault("MaxResults")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "MaxResults", valid_606614
  var valid_606615 = query.getOrDefault("NextToken")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "NextToken", valid_606615
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
  var valid_606616 = header.getOrDefault("X-Amz-Target")
  valid_606616 = validateParameter(valid_606616, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkerBlocks"))
  if valid_606616 != nil:
    section.add "X-Amz-Target", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Signature")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Signature", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Content-Sha256", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Date")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Date", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Credential")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Credential", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Security-Token")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Security-Token", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Algorithm")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Algorithm", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-SignedHeaders", valid_606623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_ListWorkerBlocks_606611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ## 
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_ListWorkerBlocks_606611; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkerBlocks
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606627 = newJObject()
  var body_606628 = newJObject()
  add(query_606627, "MaxResults", newJString(MaxResults))
  add(query_606627, "NextToken", newJString(NextToken))
  if body != nil:
    body_606628 = body
  result = call_606626.call(nil, query_606627, nil, nil, body_606628)

var listWorkerBlocks* = Call_ListWorkerBlocks_606611(name: "listWorkerBlocks",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkerBlocks",
    validator: validate_ListWorkerBlocks_606612, base: "/",
    url: url_ListWorkerBlocks_606613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkersWithQualificationType_606629 = ref object of OpenApiRestCall_605589
proc url_ListWorkersWithQualificationType_606631(protocol: Scheme; host: string;
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

proc validate_ListWorkersWithQualificationType_606630(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
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
  var valid_606632 = query.getOrDefault("MaxResults")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "MaxResults", valid_606632
  var valid_606633 = query.getOrDefault("NextToken")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "NextToken", valid_606633
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
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkersWithQualificationType"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_ListWorkersWithQualificationType_606629;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_ListWorkersWithQualificationType_606629;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkersWithQualificationType
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606645 = newJObject()
  var body_606646 = newJObject()
  add(query_606645, "MaxResults", newJString(MaxResults))
  add(query_606645, "NextToken", newJString(NextToken))
  if body != nil:
    body_606646 = body
  result = call_606644.call(nil, query_606645, nil, nil, body_606646)

var listWorkersWithQualificationType* = Call_ListWorkersWithQualificationType_606629(
    name: "listWorkersWithQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkersWithQualificationType",
    validator: validate_ListWorkersWithQualificationType_606630, base: "/",
    url: url_ListWorkersWithQualificationType_606631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWorkers_606647 = ref object of OpenApiRestCall_605589
proc url_NotifyWorkers_606649(protocol: Scheme; host: string; base: string;
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

proc validate_NotifyWorkers_606648(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
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
  var valid_606650 = header.getOrDefault("X-Amz-Target")
  valid_606650 = validateParameter(valid_606650, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.NotifyWorkers"))
  if valid_606650 != nil:
    section.add "X-Amz-Target", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Signature")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Signature", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Content-Sha256", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Date")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Date", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Credential")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Credential", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Security-Token")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Security-Token", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Algorithm")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Algorithm", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-SignedHeaders", valid_606657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606659: Call_NotifyWorkers_606647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ## 
  let valid = call_606659.validator(path, query, header, formData, body)
  let scheme = call_606659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606659.url(scheme.get, call_606659.host, call_606659.base,
                         call_606659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606659, url, valid)

proc call*(call_606660: Call_NotifyWorkers_606647; body: JsonNode): Recallable =
  ## notifyWorkers
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ##   body: JObject (required)
  var body_606661 = newJObject()
  if body != nil:
    body_606661 = body
  result = call_606660.call(nil, nil, nil, nil, body_606661)

var notifyWorkers* = Call_NotifyWorkers_606647(name: "notifyWorkers",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.NotifyWorkers",
    validator: validate_NotifyWorkers_606648, base: "/", url: url_NotifyWorkers_606649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectAssignment_606662 = ref object of OpenApiRestCall_605589
proc url_RejectAssignment_606664(protocol: Scheme; host: string; base: string;
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

proc validate_RejectAssignment_606663(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
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
  var valid_606665 = header.getOrDefault("X-Amz-Target")
  valid_606665 = validateParameter(valid_606665, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectAssignment"))
  if valid_606665 != nil:
    section.add "X-Amz-Target", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Signature")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Signature", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Content-Sha256", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Date")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Date", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Credential")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Credential", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Security-Token")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Security-Token", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Algorithm")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Algorithm", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-SignedHeaders", valid_606672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606674: Call_RejectAssignment_606662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ## 
  let valid = call_606674.validator(path, query, header, formData, body)
  let scheme = call_606674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606674.url(scheme.get, call_606674.host, call_606674.base,
                         call_606674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606674, url, valid)

proc call*(call_606675: Call_RejectAssignment_606662; body: JsonNode): Recallable =
  ## rejectAssignment
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ##   body: JObject (required)
  var body_606676 = newJObject()
  if body != nil:
    body_606676 = body
  result = call_606675.call(nil, nil, nil, nil, body_606676)

var rejectAssignment* = Call_RejectAssignment_606662(name: "rejectAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectAssignment",
    validator: validate_RejectAssignment_606663, base: "/",
    url: url_RejectAssignment_606664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectQualificationRequest_606677 = ref object of OpenApiRestCall_605589
proc url_RejectQualificationRequest_606679(protocol: Scheme; host: string;
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

proc validate_RejectQualificationRequest_606678(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
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
  var valid_606680 = header.getOrDefault("X-Amz-Target")
  valid_606680 = validateParameter(valid_606680, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectQualificationRequest"))
  if valid_606680 != nil:
    section.add "X-Amz-Target", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Signature")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Signature", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Content-Sha256", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Date")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Date", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Credential")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Credential", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Security-Token")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Security-Token", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Algorithm")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Algorithm", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-SignedHeaders", valid_606687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606689: Call_RejectQualificationRequest_606677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ## 
  let valid = call_606689.validator(path, query, header, formData, body)
  let scheme = call_606689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606689.url(scheme.get, call_606689.host, call_606689.base,
                         call_606689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606689, url, valid)

proc call*(call_606690: Call_RejectQualificationRequest_606677; body: JsonNode): Recallable =
  ## rejectQualificationRequest
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ##   body: JObject (required)
  var body_606691 = newJObject()
  if body != nil:
    body_606691 = body
  result = call_606690.call(nil, nil, nil, nil, body_606691)

var rejectQualificationRequest* = Call_RejectQualificationRequest_606677(
    name: "rejectQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectQualificationRequest",
    validator: validate_RejectQualificationRequest_606678, base: "/",
    url: url_RejectQualificationRequest_606679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendBonus_606692 = ref object of OpenApiRestCall_605589
proc url_SendBonus_606694(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_SendBonus_606693(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
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
  var valid_606695 = header.getOrDefault("X-Amz-Target")
  valid_606695 = validateParameter(valid_606695, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendBonus"))
  if valid_606695 != nil:
    section.add "X-Amz-Target", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Signature")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Signature", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Content-Sha256", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Date")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Date", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Credential")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Credential", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Security-Token")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Security-Token", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Algorithm")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Algorithm", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-SignedHeaders", valid_606702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606704: Call_SendBonus_606692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ## 
  let valid = call_606704.validator(path, query, header, formData, body)
  let scheme = call_606704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606704.url(scheme.get, call_606704.host, call_606704.base,
                         call_606704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606704, url, valid)

proc call*(call_606705: Call_SendBonus_606692; body: JsonNode): Recallable =
  ## sendBonus
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ##   body: JObject (required)
  var body_606706 = newJObject()
  if body != nil:
    body_606706 = body
  result = call_606705.call(nil, nil, nil, nil, body_606706)

var sendBonus* = Call_SendBonus_606692(name: "sendBonus", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendBonus",
                                    validator: validate_SendBonus_606693,
                                    base: "/", url: url_SendBonus_606694,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTestEventNotification_606707 = ref object of OpenApiRestCall_605589
proc url_SendTestEventNotification_606709(protocol: Scheme; host: string;
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

proc validate_SendTestEventNotification_606708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
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
  var valid_606710 = header.getOrDefault("X-Amz-Target")
  valid_606710 = validateParameter(valid_606710, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendTestEventNotification"))
  if valid_606710 != nil:
    section.add "X-Amz-Target", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Signature")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Signature", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Content-Sha256", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Date")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Date", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Credential")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Credential", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Security-Token")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Security-Token", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Algorithm")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Algorithm", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-SignedHeaders", valid_606717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606719: Call_SendTestEventNotification_606707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ## 
  let valid = call_606719.validator(path, query, header, formData, body)
  let scheme = call_606719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606719.url(scheme.get, call_606719.host, call_606719.base,
                         call_606719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606719, url, valid)

proc call*(call_606720: Call_SendTestEventNotification_606707; body: JsonNode): Recallable =
  ## sendTestEventNotification
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ##   body: JObject (required)
  var body_606721 = newJObject()
  if body != nil:
    body_606721 = body
  result = call_606720.call(nil, nil, nil, nil, body_606721)

var sendTestEventNotification* = Call_SendTestEventNotification_606707(
    name: "sendTestEventNotification", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendTestEventNotification",
    validator: validate_SendTestEventNotification_606708, base: "/",
    url: url_SendTestEventNotification_606709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExpirationForHIT_606722 = ref object of OpenApiRestCall_605589
proc url_UpdateExpirationForHIT_606724(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateExpirationForHIT_606723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
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
  var valid_606725 = header.getOrDefault("X-Amz-Target")
  valid_606725 = validateParameter(valid_606725, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateExpirationForHIT"))
  if valid_606725 != nil:
    section.add "X-Amz-Target", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Signature")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Signature", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Content-Sha256", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Date")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Date", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Credential")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Credential", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Security-Token")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Security-Token", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Algorithm")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Algorithm", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-SignedHeaders", valid_606732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606734: Call_UpdateExpirationForHIT_606722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ## 
  let valid = call_606734.validator(path, query, header, formData, body)
  let scheme = call_606734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606734.url(scheme.get, call_606734.host, call_606734.base,
                         call_606734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606734, url, valid)

proc call*(call_606735: Call_UpdateExpirationForHIT_606722; body: JsonNode): Recallable =
  ## updateExpirationForHIT
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ##   body: JObject (required)
  var body_606736 = newJObject()
  if body != nil:
    body_606736 = body
  result = call_606735.call(nil, nil, nil, nil, body_606736)

var updateExpirationForHIT* = Call_UpdateExpirationForHIT_606722(
    name: "updateExpirationForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateExpirationForHIT",
    validator: validate_UpdateExpirationForHIT_606723, base: "/",
    url: url_UpdateExpirationForHIT_606724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITReviewStatus_606737 = ref object of OpenApiRestCall_605589
proc url_UpdateHITReviewStatus_606739(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateHITReviewStatus_606738(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
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
  var valid_606740 = header.getOrDefault("X-Amz-Target")
  valid_606740 = validateParameter(valid_606740, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITReviewStatus"))
  if valid_606740 != nil:
    section.add "X-Amz-Target", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Signature")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Signature", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Content-Sha256", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Date")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Date", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Credential")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Credential", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Security-Token")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Security-Token", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Algorithm")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Algorithm", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-SignedHeaders", valid_606747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606749: Call_UpdateHITReviewStatus_606737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ## 
  let valid = call_606749.validator(path, query, header, formData, body)
  let scheme = call_606749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606749.url(scheme.get, call_606749.host, call_606749.base,
                         call_606749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606749, url, valid)

proc call*(call_606750: Call_UpdateHITReviewStatus_606737; body: JsonNode): Recallable =
  ## updateHITReviewStatus
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ##   body: JObject (required)
  var body_606751 = newJObject()
  if body != nil:
    body_606751 = body
  result = call_606750.call(nil, nil, nil, nil, body_606751)

var updateHITReviewStatus* = Call_UpdateHITReviewStatus_606737(
    name: "updateHITReviewStatus", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITReviewStatus",
    validator: validate_UpdateHITReviewStatus_606738, base: "/",
    url: url_UpdateHITReviewStatus_606739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITTypeOfHIT_606752 = ref object of OpenApiRestCall_605589
proc url_UpdateHITTypeOfHIT_606754(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateHITTypeOfHIT_606753(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
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
  var valid_606755 = header.getOrDefault("X-Amz-Target")
  valid_606755 = validateParameter(valid_606755, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT"))
  if valid_606755 != nil:
    section.add "X-Amz-Target", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Signature")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Signature", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Content-Sha256", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Date")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Date", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Credential")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Credential", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Security-Token")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Security-Token", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Algorithm")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Algorithm", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-SignedHeaders", valid_606762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606764: Call_UpdateHITTypeOfHIT_606752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ## 
  let valid = call_606764.validator(path, query, header, formData, body)
  let scheme = call_606764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606764.url(scheme.get, call_606764.host, call_606764.base,
                         call_606764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606764, url, valid)

proc call*(call_606765: Call_UpdateHITTypeOfHIT_606752; body: JsonNode): Recallable =
  ## updateHITTypeOfHIT
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ##   body: JObject (required)
  var body_606766 = newJObject()
  if body != nil:
    body_606766 = body
  result = call_606765.call(nil, nil, nil, nil, body_606766)

var updateHITTypeOfHIT* = Call_UpdateHITTypeOfHIT_606752(
    name: "updateHITTypeOfHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT",
    validator: validate_UpdateHITTypeOfHIT_606753, base: "/",
    url: url_UpdateHITTypeOfHIT_606754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationSettings_606767 = ref object of OpenApiRestCall_605589
proc url_UpdateNotificationSettings_606769(protocol: Scheme; host: string;
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

proc validate_UpdateNotificationSettings_606768(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
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
  var valid_606770 = header.getOrDefault("X-Amz-Target")
  valid_606770 = validateParameter(valid_606770, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateNotificationSettings"))
  if valid_606770 != nil:
    section.add "X-Amz-Target", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Signature")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Signature", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Content-Sha256", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Date")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Date", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Credential")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Credential", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Security-Token")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Security-Token", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Algorithm")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Algorithm", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-SignedHeaders", valid_606777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606779: Call_UpdateNotificationSettings_606767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ## 
  let valid = call_606779.validator(path, query, header, formData, body)
  let scheme = call_606779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606779.url(scheme.get, call_606779.host, call_606779.base,
                         call_606779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606779, url, valid)

proc call*(call_606780: Call_UpdateNotificationSettings_606767; body: JsonNode): Recallable =
  ## updateNotificationSettings
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ##   body: JObject (required)
  var body_606781 = newJObject()
  if body != nil:
    body_606781 = body
  result = call_606780.call(nil, nil, nil, nil, body_606781)

var updateNotificationSettings* = Call_UpdateNotificationSettings_606767(
    name: "updateNotificationSettings", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateNotificationSettings",
    validator: validate_UpdateNotificationSettings_606768, base: "/",
    url: url_UpdateNotificationSettings_606769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQualificationType_606782 = ref object of OpenApiRestCall_605589
proc url_UpdateQualificationType_606784(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateQualificationType_606783(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
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
  var valid_606785 = header.getOrDefault("X-Amz-Target")
  valid_606785 = validateParameter(valid_606785, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateQualificationType"))
  if valid_606785 != nil:
    section.add "X-Amz-Target", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Signature")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Signature", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Content-Sha256", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Date")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Date", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Credential")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Credential", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Security-Token")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Security-Token", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Algorithm")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Algorithm", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-SignedHeaders", valid_606792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606794: Call_UpdateQualificationType_606782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ## 
  let valid = call_606794.validator(path, query, header, formData, body)
  let scheme = call_606794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606794.url(scheme.get, call_606794.host, call_606794.base,
                         call_606794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606794, url, valid)

proc call*(call_606795: Call_UpdateQualificationType_606782; body: JsonNode): Recallable =
  ## updateQualificationType
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ##   body: JObject (required)
  var body_606796 = newJObject()
  if body != nil:
    body_606796 = body
  result = call_606795.call(nil, nil, nil, nil, body_606796)

var updateQualificationType* = Call_UpdateQualificationType_606782(
    name: "updateQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateQualificationType",
    validator: validate_UpdateQualificationType_606783, base: "/",
    url: url_UpdateQualificationType_606784, schemes: {Scheme.Https, Scheme.Http})
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
