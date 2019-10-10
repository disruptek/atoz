
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptQualificationRequest_602803 = ref object of OpenApiRestCall_602466
proc url_AcceptQualificationRequest_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptQualificationRequest_602804(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AcceptQualificationRequest"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AcceptQualificationRequest_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AcceptQualificationRequest_602803; body: JsonNode): Recallable =
  ## acceptQualificationRequest
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var acceptQualificationRequest* = Call_AcceptQualificationRequest_602803(
    name: "acceptQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AcceptQualificationRequest",
    validator: validate_AcceptQualificationRequest_602804, base: "/",
    url: url_AcceptQualificationRequest_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApproveAssignment_603072 = ref object of OpenApiRestCall_602466
proc url_ApproveAssignment_603074(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApproveAssignment_603073(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ApproveAssignment"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_ApproveAssignment_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_ApproveAssignment_603072; body: JsonNode): Recallable =
  ## approveAssignment
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var approveAssignment* = Call_ApproveAssignment_603072(name: "approveAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ApproveAssignment",
    validator: validate_ApproveAssignment_603073, base: "/",
    url: url_ApproveAssignment_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateQualificationWithWorker_603087 = ref object of OpenApiRestCall_602466
proc url_AssociateQualificationWithWorker_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateQualificationWithWorker_603088(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AssociateQualificationWithWorker"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_AssociateQualificationWithWorker_603087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_AssociateQualificationWithWorker_603087;
          body: JsonNode): Recallable =
  ## associateQualificationWithWorker
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var associateQualificationWithWorker* = Call_AssociateQualificationWithWorker_603087(
    name: "associateQualificationWithWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AssociateQualificationWithWorker",
    validator: validate_AssociateQualificationWithWorker_603088, base: "/",
    url: url_AssociateQualificationWithWorker_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAdditionalAssignmentsForHIT_603102 = ref object of OpenApiRestCall_602466
proc url_CreateAdditionalAssignmentsForHIT_603104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAdditionalAssignmentsForHIT_603103(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateAdditionalAssignmentsForHIT_603102;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateAdditionalAssignmentsForHIT_603102;
          body: JsonNode): Recallable =
  ## createAdditionalAssignmentsForHIT
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createAdditionalAssignmentsForHIT* = Call_CreateAdditionalAssignmentsForHIT_603102(
    name: "createAdditionalAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT",
    validator: validate_CreateAdditionalAssignmentsForHIT_603103, base: "/",
    url: url_CreateAdditionalAssignmentsForHIT_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHIT_603117 = ref object of OpenApiRestCall_602466
proc url_CreateHIT_603119(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHIT_603118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHIT"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateHIT_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateHIT_603117; body: JsonNode): Recallable =
  ## createHIT
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createHIT* = Call_CreateHIT_603117(name: "createHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHIT",
                                    validator: validate_CreateHIT_603118,
                                    base: "/", url: url_CreateHIT_603119,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITType_603132 = ref object of OpenApiRestCall_602466
proc url_CreateHITType_603134(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHITType_603133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITType"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateHITType_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateHITType_603132; body: JsonNode): Recallable =
  ## createHITType
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createHITType* = Call_CreateHITType_603132(name: "createHITType",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITType",
    validator: validate_CreateHITType_603133, base: "/", url: url_CreateHITType_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITWithHITType_603147 = ref object of OpenApiRestCall_602466
proc url_CreateHITWithHITType_603149(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHITWithHITType_603148(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITWithHITType"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateHITWithHITType_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateHITWithHITType_603147; body: JsonNode): Recallable =
  ## createHITWithHITType
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createHITWithHITType* = Call_CreateHITWithHITType_603147(
    name: "createHITWithHITType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITWithHITType",
    validator: validate_CreateHITWithHITType_603148, base: "/",
    url: url_CreateHITWithHITType_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQualificationType_603162 = ref object of OpenApiRestCall_602466
proc url_CreateQualificationType_603164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateQualificationType_603163(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateQualificationType"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateQualificationType_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateQualificationType_603162; body: JsonNode): Recallable =
  ## createQualificationType
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createQualificationType* = Call_CreateQualificationType_603162(
    name: "createQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateQualificationType",
    validator: validate_CreateQualificationType_603163, base: "/",
    url: url_CreateQualificationType_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkerBlock_603177 = ref object of OpenApiRestCall_602466
proc url_CreateWorkerBlock_603179(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkerBlock_603178(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateWorkerBlock"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateWorkerBlock_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateWorkerBlock_603177; body: JsonNode): Recallable =
  ## createWorkerBlock
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createWorkerBlock* = Call_CreateWorkerBlock_603177(name: "createWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateWorkerBlock",
    validator: validate_CreateWorkerBlock_603178, base: "/",
    url: url_CreateWorkerBlock_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHIT_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteHIT_603194(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteHIT_603193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteHIT"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeleteHIT_603192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteHIT_603192; body: JsonNode): Recallable =
  ## deleteHIT
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteHIT* = Call_DeleteHIT_603192(name: "deleteHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteHIT",
                                    validator: validate_DeleteHIT_603193,
                                    base: "/", url: url_DeleteHIT_603194,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQualificationType_603207 = ref object of OpenApiRestCall_602466
proc url_DeleteQualificationType_603209(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteQualificationType_603208(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteQualificationType"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DeleteQualificationType_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DeleteQualificationType_603207; body: JsonNode): Recallable =
  ## deleteQualificationType
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var deleteQualificationType* = Call_DeleteQualificationType_603207(
    name: "deleteQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteQualificationType",
    validator: validate_DeleteQualificationType_603208, base: "/",
    url: url_DeleteQualificationType_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkerBlock_603222 = ref object of OpenApiRestCall_602466
proc url_DeleteWorkerBlock_603224(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkerBlock_603223(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteWorkerBlock"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DeleteWorkerBlock_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteWorkerBlock_603222; body: JsonNode): Recallable =
  ## deleteWorkerBlock
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var deleteWorkerBlock* = Call_DeleteWorkerBlock_603222(name: "deleteWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteWorkerBlock",
    validator: validate_DeleteWorkerBlock_603223, base: "/",
    url: url_DeleteWorkerBlock_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateQualificationFromWorker_603237 = ref object of OpenApiRestCall_602466
proc url_DisassociateQualificationFromWorker_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateQualificationFromWorker_603238(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DisassociateQualificationFromWorker_603237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DisassociateQualificationFromWorker_603237;
          body: JsonNode): Recallable =
  ## disassociateQualificationFromWorker
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var disassociateQualificationFromWorker* = Call_DisassociateQualificationFromWorker_603237(
    name: "disassociateQualificationFromWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker",
    validator: validate_DisassociateQualificationFromWorker_603238, base: "/",
    url: url_DisassociateQualificationFromWorker_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountBalance_603252 = ref object of OpenApiRestCall_602466
proc url_GetAccountBalance_603254(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccountBalance_603253(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAccountBalance"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_GetAccountBalance_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_GetAccountBalance_603252; body: JsonNode): Recallable =
  ## getAccountBalance
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var getAccountBalance* = Call_GetAccountBalance_603252(name: "getAccountBalance",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAccountBalance",
    validator: validate_GetAccountBalance_603253, base: "/",
    url: url_GetAccountBalance_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssignment_603267 = ref object of OpenApiRestCall_602466
proc url_GetAssignment_603269(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAssignment_603268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAssignment"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_GetAssignment_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_GetAssignment_603267; body: JsonNode): Recallable =
  ## getAssignment
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var getAssignment* = Call_GetAssignment_603267(name: "getAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAssignment",
    validator: validate_GetAssignment_603268, base: "/", url: url_GetAssignment_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFileUploadURL_603282 = ref object of OpenApiRestCall_602466
proc url_GetFileUploadURL_603284(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFileUploadURL_603283(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetFileUploadURL"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_GetFileUploadURL_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_GetFileUploadURL_603282; body: JsonNode): Recallable =
  ## getFileUploadURL
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var getFileUploadURL* = Call_GetFileUploadURL_603282(name: "getFileUploadURL",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetFileUploadURL",
    validator: validate_GetFileUploadURL_603283, base: "/",
    url: url_GetFileUploadURL_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHIT_603297 = ref object of OpenApiRestCall_602466
proc url_GetHIT_603299(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetHIT_603298(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetHIT"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_GetHIT_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_GetHIT_603297; body: JsonNode): Recallable =
  ## getHIT
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var getHIT* = Call_GetHIT_603297(name: "getHIT", meth: HttpMethod.HttpPost,
                              host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetHIT",
                              validator: validate_GetHIT_603298, base: "/",
                              url: url_GetHIT_603299,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationScore_603312 = ref object of OpenApiRestCall_602466
proc url_GetQualificationScore_603314(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetQualificationScore_603313(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationScore"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_GetQualificationScore_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_GetQualificationScore_603312; body: JsonNode): Recallable =
  ## getQualificationScore
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var getQualificationScore* = Call_GetQualificationScore_603312(
    name: "getQualificationScore", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationScore",
    validator: validate_GetQualificationScore_603313, base: "/",
    url: url_GetQualificationScore_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationType_603327 = ref object of OpenApiRestCall_602466
proc url_GetQualificationType_603329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetQualificationType_603328(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationType"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_GetQualificationType_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_GetQualificationType_603327; body: JsonNode): Recallable =
  ## getQualificationType
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var getQualificationType* = Call_GetQualificationType_603327(
    name: "getQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationType",
    validator: validate_GetQualificationType_603328, base: "/",
    url: url_GetQualificationType_603329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssignmentsForHIT_603342 = ref object of OpenApiRestCall_602466
proc url_ListAssignmentsForHIT_603344(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssignmentsForHIT_603343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
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
  var valid_603345 = query.getOrDefault("NextToken")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "NextToken", valid_603345
  var valid_603346 = query.getOrDefault("MaxResults")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "MaxResults", valid_603346
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
  var valid_603347 = header.getOrDefault("X-Amz-Date")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Date", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Security-Token")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Security-Token", valid_603348
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603349 = header.getOrDefault("X-Amz-Target")
  valid_603349 = validateParameter(valid_603349, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListAssignmentsForHIT"))
  if valid_603349 != nil:
    section.add "X-Amz-Target", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Content-Sha256", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Algorithm")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Algorithm", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Signature")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Signature", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-SignedHeaders", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Credential")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Credential", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_ListAssignmentsForHIT_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_ListAssignmentsForHIT_603342; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssignmentsForHIT
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603358 = newJObject()
  var body_603359 = newJObject()
  add(query_603358, "NextToken", newJString(NextToken))
  if body != nil:
    body_603359 = body
  add(query_603358, "MaxResults", newJString(MaxResults))
  result = call_603357.call(nil, query_603358, nil, nil, body_603359)

var listAssignmentsForHIT* = Call_ListAssignmentsForHIT_603342(
    name: "listAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListAssignmentsForHIT",
    validator: validate_ListAssignmentsForHIT_603343, base: "/",
    url: url_ListAssignmentsForHIT_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBonusPayments_603361 = ref object of OpenApiRestCall_602466
proc url_ListBonusPayments_603363(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBonusPayments_603362(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
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
  var valid_603364 = query.getOrDefault("NextToken")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "NextToken", valid_603364
  var valid_603365 = query.getOrDefault("MaxResults")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "MaxResults", valid_603365
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
  var valid_603366 = header.getOrDefault("X-Amz-Date")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Date", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Security-Token")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Security-Token", valid_603367
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603368 = header.getOrDefault("X-Amz-Target")
  valid_603368 = validateParameter(valid_603368, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListBonusPayments"))
  if valid_603368 != nil:
    section.add "X-Amz-Target", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Content-Sha256", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Algorithm")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Algorithm", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Signature")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Signature", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-SignedHeaders", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Credential")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Credential", valid_603373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603375: Call_ListBonusPayments_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ## 
  let valid = call_603375.validator(path, query, header, formData, body)
  let scheme = call_603375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603375.url(scheme.get, call_603375.host, call_603375.base,
                         call_603375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603375, url, valid)

proc call*(call_603376: Call_ListBonusPayments_603361; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBonusPayments
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603377 = newJObject()
  var body_603378 = newJObject()
  add(query_603377, "NextToken", newJString(NextToken))
  if body != nil:
    body_603378 = body
  add(query_603377, "MaxResults", newJString(MaxResults))
  result = call_603376.call(nil, query_603377, nil, nil, body_603378)

var listBonusPayments* = Call_ListBonusPayments_603361(name: "listBonusPayments",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListBonusPayments",
    validator: validate_ListBonusPayments_603362, base: "/",
    url: url_ListBonusPayments_603363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITs_603379 = ref object of OpenApiRestCall_602466
proc url_ListHITs_603381(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHITs_603380(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
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
  var valid_603382 = query.getOrDefault("NextToken")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "NextToken", valid_603382
  var valid_603383 = query.getOrDefault("MaxResults")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "MaxResults", valid_603383
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
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603386 = header.getOrDefault("X-Amz-Target")
  valid_603386 = validateParameter(valid_603386, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITs"))
  if valid_603386 != nil:
    section.add "X-Amz-Target", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Content-Sha256", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Algorithm")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Algorithm", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Signature")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Signature", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-SignedHeaders", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Credential")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Credential", valid_603391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603393: Call_ListHITs_603379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ## 
  let valid = call_603393.validator(path, query, header, formData, body)
  let scheme = call_603393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603393.url(scheme.get, call_603393.host, call_603393.base,
                         call_603393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603393, url, valid)

proc call*(call_603394: Call_ListHITs_603379; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listHITs
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603395 = newJObject()
  var body_603396 = newJObject()
  add(query_603395, "NextToken", newJString(NextToken))
  if body != nil:
    body_603396 = body
  add(query_603395, "MaxResults", newJString(MaxResults))
  result = call_603394.call(nil, query_603395, nil, nil, body_603396)

var listHITs* = Call_ListHITs_603379(name: "listHITs", meth: HttpMethod.HttpPost,
                                  host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITs",
                                  validator: validate_ListHITs_603380, base: "/",
                                  url: url_ListHITs_603381,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITsForQualificationType_603397 = ref object of OpenApiRestCall_602466
proc url_ListHITsForQualificationType_603399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHITsForQualificationType_603398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
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
  var valid_603400 = query.getOrDefault("NextToken")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "NextToken", valid_603400
  var valid_603401 = query.getOrDefault("MaxResults")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "MaxResults", valid_603401
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
  var valid_603402 = header.getOrDefault("X-Amz-Date")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Date", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Security-Token")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Security-Token", valid_603403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603404 = header.getOrDefault("X-Amz-Target")
  valid_603404 = validateParameter(valid_603404, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITsForQualificationType"))
  if valid_603404 != nil:
    section.add "X-Amz-Target", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Content-Sha256", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Signature")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Signature", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Credential")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Credential", valid_603409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_ListHITsForQualificationType_603397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603411, url, valid)

proc call*(call_603412: Call_ListHITsForQualificationType_603397; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHITsForQualificationType
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603413 = newJObject()
  var body_603414 = newJObject()
  add(query_603413, "NextToken", newJString(NextToken))
  if body != nil:
    body_603414 = body
  add(query_603413, "MaxResults", newJString(MaxResults))
  result = call_603412.call(nil, query_603413, nil, nil, body_603414)

var listHITsForQualificationType* = Call_ListHITsForQualificationType_603397(
    name: "listHITsForQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITsForQualificationType",
    validator: validate_ListHITsForQualificationType_603398, base: "/",
    url: url_ListHITsForQualificationType_603399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationRequests_603415 = ref object of OpenApiRestCall_602466
proc url_ListQualificationRequests_603417(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQualificationRequests_603416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
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
  var valid_603418 = query.getOrDefault("NextToken")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "NextToken", valid_603418
  var valid_603419 = query.getOrDefault("MaxResults")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "MaxResults", valid_603419
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
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationRequests"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_ListQualificationRequests_603415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_ListQualificationRequests_603415; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQualificationRequests
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603431 = newJObject()
  var body_603432 = newJObject()
  add(query_603431, "NextToken", newJString(NextToken))
  if body != nil:
    body_603432 = body
  add(query_603431, "MaxResults", newJString(MaxResults))
  result = call_603430.call(nil, query_603431, nil, nil, body_603432)

var listQualificationRequests* = Call_ListQualificationRequests_603415(
    name: "listQualificationRequests", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationRequests",
    validator: validate_ListQualificationRequests_603416, base: "/",
    url: url_ListQualificationRequests_603417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationTypes_603433 = ref object of OpenApiRestCall_602466
proc url_ListQualificationTypes_603435(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQualificationTypes_603434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
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
  var valid_603436 = query.getOrDefault("NextToken")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "NextToken", valid_603436
  var valid_603437 = query.getOrDefault("MaxResults")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "MaxResults", valid_603437
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
  var valid_603438 = header.getOrDefault("X-Amz-Date")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Date", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Security-Token")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Security-Token", valid_603439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603440 = header.getOrDefault("X-Amz-Target")
  valid_603440 = validateParameter(valid_603440, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationTypes"))
  if valid_603440 != nil:
    section.add "X-Amz-Target", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Algorithm")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Algorithm", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Signature")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Signature", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Credential")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Credential", valid_603445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603447: Call_ListQualificationTypes_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ## 
  let valid = call_603447.validator(path, query, header, formData, body)
  let scheme = call_603447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603447.url(scheme.get, call_603447.host, call_603447.base,
                         call_603447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603447, url, valid)

proc call*(call_603448: Call_ListQualificationTypes_603433; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQualificationTypes
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603449 = newJObject()
  var body_603450 = newJObject()
  add(query_603449, "NextToken", newJString(NextToken))
  if body != nil:
    body_603450 = body
  add(query_603449, "MaxResults", newJString(MaxResults))
  result = call_603448.call(nil, query_603449, nil, nil, body_603450)

var listQualificationTypes* = Call_ListQualificationTypes_603433(
    name: "listQualificationTypes", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationTypes",
    validator: validate_ListQualificationTypes_603434, base: "/",
    url: url_ListQualificationTypes_603435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewPolicyResultsForHIT_603451 = ref object of OpenApiRestCall_602466
proc url_ListReviewPolicyResultsForHIT_603453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListReviewPolicyResultsForHIT_603452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
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
  var valid_603454 = query.getOrDefault("NextToken")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "NextToken", valid_603454
  var valid_603455 = query.getOrDefault("MaxResults")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "MaxResults", valid_603455
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
  var valid_603456 = header.getOrDefault("X-Amz-Date")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Date", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Security-Token")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Security-Token", valid_603457
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603458 = header.getOrDefault("X-Amz-Target")
  valid_603458 = validateParameter(valid_603458, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT"))
  if valid_603458 != nil:
    section.add "X-Amz-Target", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Signature")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Signature", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603465: Call_ListReviewPolicyResultsForHIT_603451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ## 
  let valid = call_603465.validator(path, query, header, formData, body)
  let scheme = call_603465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603465.url(scheme.get, call_603465.host, call_603465.base,
                         call_603465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603465, url, valid)

proc call*(call_603466: Call_ListReviewPolicyResultsForHIT_603451; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listReviewPolicyResultsForHIT
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603467 = newJObject()
  var body_603468 = newJObject()
  add(query_603467, "NextToken", newJString(NextToken))
  if body != nil:
    body_603468 = body
  add(query_603467, "MaxResults", newJString(MaxResults))
  result = call_603466.call(nil, query_603467, nil, nil, body_603468)

var listReviewPolicyResultsForHIT* = Call_ListReviewPolicyResultsForHIT_603451(
    name: "listReviewPolicyResultsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT",
    validator: validate_ListReviewPolicyResultsForHIT_603452, base: "/",
    url: url_ListReviewPolicyResultsForHIT_603453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewableHITs_603469 = ref object of OpenApiRestCall_602466
proc url_ListReviewableHITs_603471(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListReviewableHITs_603470(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
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
  var valid_603472 = query.getOrDefault("NextToken")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "NextToken", valid_603472
  var valid_603473 = query.getOrDefault("MaxResults")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "MaxResults", valid_603473
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
  var valid_603474 = header.getOrDefault("X-Amz-Date")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Date", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Security-Token")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Security-Token", valid_603475
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603476 = header.getOrDefault("X-Amz-Target")
  valid_603476 = validateParameter(valid_603476, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewableHITs"))
  if valid_603476 != nil:
    section.add "X-Amz-Target", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Content-Sha256", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Algorithm")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Algorithm", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Signature")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Signature", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-SignedHeaders", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Credential")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Credential", valid_603481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603483: Call_ListReviewableHITs_603469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ## 
  let valid = call_603483.validator(path, query, header, formData, body)
  let scheme = call_603483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603483.url(scheme.get, call_603483.host, call_603483.base,
                         call_603483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603483, url, valid)

proc call*(call_603484: Call_ListReviewableHITs_603469; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listReviewableHITs
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603485 = newJObject()
  var body_603486 = newJObject()
  add(query_603485, "NextToken", newJString(NextToken))
  if body != nil:
    body_603486 = body
  add(query_603485, "MaxResults", newJString(MaxResults))
  result = call_603484.call(nil, query_603485, nil, nil, body_603486)

var listReviewableHITs* = Call_ListReviewableHITs_603469(
    name: "listReviewableHITs", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewableHITs",
    validator: validate_ListReviewableHITs_603470, base: "/",
    url: url_ListReviewableHITs_603471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkerBlocks_603487 = ref object of OpenApiRestCall_602466
proc url_ListWorkerBlocks_603489(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkerBlocks_603488(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
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
  var valid_603490 = query.getOrDefault("NextToken")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "NextToken", valid_603490
  var valid_603491 = query.getOrDefault("MaxResults")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "MaxResults", valid_603491
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
  var valid_603492 = header.getOrDefault("X-Amz-Date")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Date", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Security-Token")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Security-Token", valid_603493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603494 = header.getOrDefault("X-Amz-Target")
  valid_603494 = validateParameter(valid_603494, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkerBlocks"))
  if valid_603494 != nil:
    section.add "X-Amz-Target", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Content-Sha256", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Credential")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Credential", valid_603499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603501: Call_ListWorkerBlocks_603487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ## 
  let valid = call_603501.validator(path, query, header, formData, body)
  let scheme = call_603501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603501.url(scheme.get, call_603501.host, call_603501.base,
                         call_603501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603501, url, valid)

proc call*(call_603502: Call_ListWorkerBlocks_603487; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkerBlocks
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603503 = newJObject()
  var body_603504 = newJObject()
  add(query_603503, "NextToken", newJString(NextToken))
  if body != nil:
    body_603504 = body
  add(query_603503, "MaxResults", newJString(MaxResults))
  result = call_603502.call(nil, query_603503, nil, nil, body_603504)

var listWorkerBlocks* = Call_ListWorkerBlocks_603487(name: "listWorkerBlocks",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkerBlocks",
    validator: validate_ListWorkerBlocks_603488, base: "/",
    url: url_ListWorkerBlocks_603489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkersWithQualificationType_603505 = ref object of OpenApiRestCall_602466
proc url_ListWorkersWithQualificationType_603507(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkersWithQualificationType_603506(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
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
  var valid_603508 = query.getOrDefault("NextToken")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "NextToken", valid_603508
  var valid_603509 = query.getOrDefault("MaxResults")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "MaxResults", valid_603509
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
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603512 = header.getOrDefault("X-Amz-Target")
  valid_603512 = validateParameter(valid_603512, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkersWithQualificationType"))
  if valid_603512 != nil:
    section.add "X-Amz-Target", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_ListWorkersWithQualificationType_603505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_ListWorkersWithQualificationType_603505;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkersWithQualificationType
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603521 = newJObject()
  var body_603522 = newJObject()
  add(query_603521, "NextToken", newJString(NextToken))
  if body != nil:
    body_603522 = body
  add(query_603521, "MaxResults", newJString(MaxResults))
  result = call_603520.call(nil, query_603521, nil, nil, body_603522)

var listWorkersWithQualificationType* = Call_ListWorkersWithQualificationType_603505(
    name: "listWorkersWithQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkersWithQualificationType",
    validator: validate_ListWorkersWithQualificationType_603506, base: "/",
    url: url_ListWorkersWithQualificationType_603507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWorkers_603523 = ref object of OpenApiRestCall_602466
proc url_NotifyWorkers_603525(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_NotifyWorkers_603524(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603526 = header.getOrDefault("X-Amz-Date")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Date", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Security-Token")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Security-Token", valid_603527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603528 = header.getOrDefault("X-Amz-Target")
  valid_603528 = validateParameter(valid_603528, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.NotifyWorkers"))
  if valid_603528 != nil:
    section.add "X-Amz-Target", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Content-Sha256", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Algorithm")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Algorithm", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603535: Call_NotifyWorkers_603523; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ## 
  let valid = call_603535.validator(path, query, header, formData, body)
  let scheme = call_603535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603535.url(scheme.get, call_603535.host, call_603535.base,
                         call_603535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603535, url, valid)

proc call*(call_603536: Call_NotifyWorkers_603523; body: JsonNode): Recallable =
  ## notifyWorkers
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ##   body: JObject (required)
  var body_603537 = newJObject()
  if body != nil:
    body_603537 = body
  result = call_603536.call(nil, nil, nil, nil, body_603537)

var notifyWorkers* = Call_NotifyWorkers_603523(name: "notifyWorkers",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.NotifyWorkers",
    validator: validate_NotifyWorkers_603524, base: "/", url: url_NotifyWorkers_603525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectAssignment_603538 = ref object of OpenApiRestCall_602466
proc url_RejectAssignment_603540(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectAssignment_603539(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603543 = header.getOrDefault("X-Amz-Target")
  valid_603543 = validateParameter(valid_603543, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectAssignment"))
  if valid_603543 != nil:
    section.add "X-Amz-Target", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Content-Sha256", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Algorithm")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Algorithm", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Signature")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Signature", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-SignedHeaders", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Credential")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Credential", valid_603548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603550: Call_RejectAssignment_603538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ## 
  let valid = call_603550.validator(path, query, header, formData, body)
  let scheme = call_603550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603550.url(scheme.get, call_603550.host, call_603550.base,
                         call_603550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603550, url, valid)

proc call*(call_603551: Call_RejectAssignment_603538; body: JsonNode): Recallable =
  ## rejectAssignment
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ##   body: JObject (required)
  var body_603552 = newJObject()
  if body != nil:
    body_603552 = body
  result = call_603551.call(nil, nil, nil, nil, body_603552)

var rejectAssignment* = Call_RejectAssignment_603538(name: "rejectAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectAssignment",
    validator: validate_RejectAssignment_603539, base: "/",
    url: url_RejectAssignment_603540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectQualificationRequest_603553 = ref object of OpenApiRestCall_602466
proc url_RejectQualificationRequest_603555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectQualificationRequest_603554(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603556 = header.getOrDefault("X-Amz-Date")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Date", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Security-Token")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Security-Token", valid_603557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603558 = header.getOrDefault("X-Amz-Target")
  valid_603558 = validateParameter(valid_603558, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectQualificationRequest"))
  if valid_603558 != nil:
    section.add "X-Amz-Target", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Content-Sha256", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Signature")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Signature", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-SignedHeaders", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Credential")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Credential", valid_603563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603565: Call_RejectQualificationRequest_603553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ## 
  let valid = call_603565.validator(path, query, header, formData, body)
  let scheme = call_603565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603565.url(scheme.get, call_603565.host, call_603565.base,
                         call_603565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603565, url, valid)

proc call*(call_603566: Call_RejectQualificationRequest_603553; body: JsonNode): Recallable =
  ## rejectQualificationRequest
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ##   body: JObject (required)
  var body_603567 = newJObject()
  if body != nil:
    body_603567 = body
  result = call_603566.call(nil, nil, nil, nil, body_603567)

var rejectQualificationRequest* = Call_RejectQualificationRequest_603553(
    name: "rejectQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectQualificationRequest",
    validator: validate_RejectQualificationRequest_603554, base: "/",
    url: url_RejectQualificationRequest_603555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendBonus_603568 = ref object of OpenApiRestCall_602466
proc url_SendBonus_603570(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendBonus_603569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603571 = header.getOrDefault("X-Amz-Date")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Date", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Security-Token")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Security-Token", valid_603572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603573 = header.getOrDefault("X-Amz-Target")
  valid_603573 = validateParameter(valid_603573, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendBonus"))
  if valid_603573 != nil:
    section.add "X-Amz-Target", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Content-Sha256", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Signature")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Signature", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Credential")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Credential", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603580: Call_SendBonus_603568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ## 
  let valid = call_603580.validator(path, query, header, formData, body)
  let scheme = call_603580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603580.url(scheme.get, call_603580.host, call_603580.base,
                         call_603580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603580, url, valid)

proc call*(call_603581: Call_SendBonus_603568; body: JsonNode): Recallable =
  ## sendBonus
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ##   body: JObject (required)
  var body_603582 = newJObject()
  if body != nil:
    body_603582 = body
  result = call_603581.call(nil, nil, nil, nil, body_603582)

var sendBonus* = Call_SendBonus_603568(name: "sendBonus", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendBonus",
                                    validator: validate_SendBonus_603569,
                                    base: "/", url: url_SendBonus_603570,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTestEventNotification_603583 = ref object of OpenApiRestCall_602466
proc url_SendTestEventNotification_603585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendTestEventNotification_603584(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603586 = header.getOrDefault("X-Amz-Date")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Date", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Security-Token")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Security-Token", valid_603587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603588 = header.getOrDefault("X-Amz-Target")
  valid_603588 = validateParameter(valid_603588, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendTestEventNotification"))
  if valid_603588 != nil:
    section.add "X-Amz-Target", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Content-Sha256", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Signature")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Signature", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Credential")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Credential", valid_603593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603595: Call_SendTestEventNotification_603583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ## 
  let valid = call_603595.validator(path, query, header, formData, body)
  let scheme = call_603595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603595.url(scheme.get, call_603595.host, call_603595.base,
                         call_603595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603595, url, valid)

proc call*(call_603596: Call_SendTestEventNotification_603583; body: JsonNode): Recallable =
  ## sendTestEventNotification
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ##   body: JObject (required)
  var body_603597 = newJObject()
  if body != nil:
    body_603597 = body
  result = call_603596.call(nil, nil, nil, nil, body_603597)

var sendTestEventNotification* = Call_SendTestEventNotification_603583(
    name: "sendTestEventNotification", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendTestEventNotification",
    validator: validate_SendTestEventNotification_603584, base: "/",
    url: url_SendTestEventNotification_603585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExpirationForHIT_603598 = ref object of OpenApiRestCall_602466
proc url_UpdateExpirationForHIT_603600(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateExpirationForHIT_603599(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603601 = header.getOrDefault("X-Amz-Date")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Date", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Security-Token")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Security-Token", valid_603602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603603 = header.getOrDefault("X-Amz-Target")
  valid_603603 = validateParameter(valid_603603, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateExpirationForHIT"))
  if valid_603603 != nil:
    section.add "X-Amz-Target", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Content-Sha256", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Algorithm")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Algorithm", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Signature")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Signature", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-SignedHeaders", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Credential")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Credential", valid_603608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603610: Call_UpdateExpirationForHIT_603598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ## 
  let valid = call_603610.validator(path, query, header, formData, body)
  let scheme = call_603610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603610.url(scheme.get, call_603610.host, call_603610.base,
                         call_603610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603610, url, valid)

proc call*(call_603611: Call_UpdateExpirationForHIT_603598; body: JsonNode): Recallable =
  ## updateExpirationForHIT
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ##   body: JObject (required)
  var body_603612 = newJObject()
  if body != nil:
    body_603612 = body
  result = call_603611.call(nil, nil, nil, nil, body_603612)

var updateExpirationForHIT* = Call_UpdateExpirationForHIT_603598(
    name: "updateExpirationForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateExpirationForHIT",
    validator: validate_UpdateExpirationForHIT_603599, base: "/",
    url: url_UpdateExpirationForHIT_603600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITReviewStatus_603613 = ref object of OpenApiRestCall_602466
proc url_UpdateHITReviewStatus_603615(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateHITReviewStatus_603614(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603616 = header.getOrDefault("X-Amz-Date")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Date", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Security-Token")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Security-Token", valid_603617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603618 = header.getOrDefault("X-Amz-Target")
  valid_603618 = validateParameter(valid_603618, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITReviewStatus"))
  if valid_603618 != nil:
    section.add "X-Amz-Target", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Content-Sha256", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Algorithm")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Algorithm", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Signature")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Signature", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-SignedHeaders", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Credential")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Credential", valid_603623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603625: Call_UpdateHITReviewStatus_603613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ## 
  let valid = call_603625.validator(path, query, header, formData, body)
  let scheme = call_603625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603625.url(scheme.get, call_603625.host, call_603625.base,
                         call_603625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603625, url, valid)

proc call*(call_603626: Call_UpdateHITReviewStatus_603613; body: JsonNode): Recallable =
  ## updateHITReviewStatus
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ##   body: JObject (required)
  var body_603627 = newJObject()
  if body != nil:
    body_603627 = body
  result = call_603626.call(nil, nil, nil, nil, body_603627)

var updateHITReviewStatus* = Call_UpdateHITReviewStatus_603613(
    name: "updateHITReviewStatus", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITReviewStatus",
    validator: validate_UpdateHITReviewStatus_603614, base: "/",
    url: url_UpdateHITReviewStatus_603615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITTypeOfHIT_603628 = ref object of OpenApiRestCall_602466
proc url_UpdateHITTypeOfHIT_603630(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateHITTypeOfHIT_603629(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603631 = header.getOrDefault("X-Amz-Date")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Date", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Security-Token")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Security-Token", valid_603632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603633 = header.getOrDefault("X-Amz-Target")
  valid_603633 = validateParameter(valid_603633, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT"))
  if valid_603633 != nil:
    section.add "X-Amz-Target", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Content-Sha256", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Signature")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Signature", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-SignedHeaders", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Credential")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Credential", valid_603638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603640: Call_UpdateHITTypeOfHIT_603628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ## 
  let valid = call_603640.validator(path, query, header, formData, body)
  let scheme = call_603640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603640.url(scheme.get, call_603640.host, call_603640.base,
                         call_603640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603640, url, valid)

proc call*(call_603641: Call_UpdateHITTypeOfHIT_603628; body: JsonNode): Recallable =
  ## updateHITTypeOfHIT
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ##   body: JObject (required)
  var body_603642 = newJObject()
  if body != nil:
    body_603642 = body
  result = call_603641.call(nil, nil, nil, nil, body_603642)

var updateHITTypeOfHIT* = Call_UpdateHITTypeOfHIT_603628(
    name: "updateHITTypeOfHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT",
    validator: validate_UpdateHITTypeOfHIT_603629, base: "/",
    url: url_UpdateHITTypeOfHIT_603630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationSettings_603643 = ref object of OpenApiRestCall_602466
proc url_UpdateNotificationSettings_603645(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNotificationSettings_603644(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603646 = header.getOrDefault("X-Amz-Date")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Date", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Security-Token")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Security-Token", valid_603647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603648 = header.getOrDefault("X-Amz-Target")
  valid_603648 = validateParameter(valid_603648, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateNotificationSettings"))
  if valid_603648 != nil:
    section.add "X-Amz-Target", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Content-Sha256", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Algorithm")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Algorithm", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Signature")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Signature", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-SignedHeaders", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Credential")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Credential", valid_603653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603655: Call_UpdateNotificationSettings_603643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ## 
  let valid = call_603655.validator(path, query, header, formData, body)
  let scheme = call_603655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603655.url(scheme.get, call_603655.host, call_603655.base,
                         call_603655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603655, url, valid)

proc call*(call_603656: Call_UpdateNotificationSettings_603643; body: JsonNode): Recallable =
  ## updateNotificationSettings
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ##   body: JObject (required)
  var body_603657 = newJObject()
  if body != nil:
    body_603657 = body
  result = call_603656.call(nil, nil, nil, nil, body_603657)

var updateNotificationSettings* = Call_UpdateNotificationSettings_603643(
    name: "updateNotificationSettings", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateNotificationSettings",
    validator: validate_UpdateNotificationSettings_603644, base: "/",
    url: url_UpdateNotificationSettings_603645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQualificationType_603658 = ref object of OpenApiRestCall_602466
proc url_UpdateQualificationType_603660(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateQualificationType_603659(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603661 = header.getOrDefault("X-Amz-Date")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Date", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Security-Token")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Security-Token", valid_603662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603663 = header.getOrDefault("X-Amz-Target")
  valid_603663 = validateParameter(valid_603663, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateQualificationType"))
  if valid_603663 != nil:
    section.add "X-Amz-Target", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Content-Sha256", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Algorithm")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Algorithm", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Signature")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Signature", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-SignedHeaders", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Credential")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Credential", valid_603668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603670: Call_UpdateQualificationType_603658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ## 
  let valid = call_603670.validator(path, query, header, formData, body)
  let scheme = call_603670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603670.url(scheme.get, call_603670.host, call_603670.base,
                         call_603670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603670, url, valid)

proc call*(call_603671: Call_UpdateQualificationType_603658; body: JsonNode): Recallable =
  ## updateQualificationType
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ##   body: JObject (required)
  var body_603672 = newJObject()
  if body != nil:
    body_603672 = body
  result = call_603671.call(nil, nil, nil, nil, body_603672)

var updateQualificationType* = Call_UpdateQualificationType_603658(
    name: "updateQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateQualificationType",
    validator: validate_UpdateQualificationType_603659, base: "/",
    url: url_UpdateQualificationType_603660, schemes: {Scheme.Https, Scheme.Http})
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
