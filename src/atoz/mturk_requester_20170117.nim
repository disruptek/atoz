
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptQualificationRequest_602770 = ref object of OpenApiRestCall_602433
proc url_AcceptQualificationRequest_602772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptQualificationRequest_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AcceptQualificationRequest"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_AcceptQualificationRequest_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AcceptQualificationRequest_602770; body: JsonNode): Recallable =
  ## acceptQualificationRequest
  ## <p> The <code>AcceptQualificationRequest</code> operation approves a Worker's request for a Qualification. </p> <p> Only the owner of the Qualification type can grant a Qualification request for that type. </p> <p> A successful request for the <code>AcceptQualificationRequest</code> operation returns with no errors and an empty body. </p>
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var acceptQualificationRequest* = Call_AcceptQualificationRequest_602770(
    name: "acceptQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AcceptQualificationRequest",
    validator: validate_AcceptQualificationRequest_602771, base: "/",
    url: url_AcceptQualificationRequest_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApproveAssignment_603039 = ref object of OpenApiRestCall_602433
proc url_ApproveAssignment_603041(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApproveAssignment_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ApproveAssignment"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_ApproveAssignment_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_ApproveAssignment_603039; body: JsonNode): Recallable =
  ## approveAssignment
  ## <p> The <code>ApproveAssignment</code> operation approves the results of a completed assignment. </p> <p> Approving an assignment initiates two payments from the Requester's Amazon.com account </p> <ul> <li> <p> The Worker who submitted the results is paid the reward specified in the HIT. </p> </li> <li> <p> Amazon Mechanical Turk fees are debited. </p> </li> </ul> <p> If the Requester's account does not have adequate funds for these payments, the call to ApproveAssignment returns an exception, and the approval is not processed. You can include an optional feedback message with the approval, which the Worker can see in the Status section of the web site. </p> <p> You can also call this operation for assignments that were previous rejected and approve them by explicitly overriding the previous rejection. This only works on rejected assignments that were submitted within the previous 30 days and only if the assignment's related HIT has not been deleted. </p>
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var approveAssignment* = Call_ApproveAssignment_603039(name: "approveAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ApproveAssignment",
    validator: validate_ApproveAssignment_603040, base: "/",
    url: url_ApproveAssignment_603041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateQualificationWithWorker_603054 = ref object of OpenApiRestCall_602433
proc url_AssociateQualificationWithWorker_603056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateQualificationWithWorker_603055(path: JsonNode;
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
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.AssociateQualificationWithWorker"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_AssociateQualificationWithWorker_603054;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_AssociateQualificationWithWorker_603054;
          body: JsonNode): Recallable =
  ## associateQualificationWithWorker
  ## <p> The <code>AssociateQualificationWithWorker</code> operation gives a Worker a Qualification. <code>AssociateQualificationWithWorker</code> does not require that the Worker submit a Qualification request. It gives the Qualification directly to the Worker. </p> <p> You can only assign a Qualification of a Qualification type that you created (using the <code>CreateQualificationType</code> operation). </p> <note> <p> Note: <code>AssociateQualificationWithWorker</code> does not affect any pending Qualification requests for the Qualification by the Worker. If you assign a Qualification to a Worker, then later grant a Qualification request made by the Worker, the granting of the request may modify the Qualification score. To resolve a pending Qualification request without affecting the Qualification the Worker already has, reject the request with the <code>RejectQualificationRequest</code> operation. </p> </note>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var associateQualificationWithWorker* = Call_AssociateQualificationWithWorker_603054(
    name: "associateQualificationWithWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.AssociateQualificationWithWorker",
    validator: validate_AssociateQualificationWithWorker_603055, base: "/",
    url: url_AssociateQualificationWithWorker_603056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAdditionalAssignmentsForHIT_603069 = ref object of OpenApiRestCall_602433
proc url_CreateAdditionalAssignmentsForHIT_603071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAdditionalAssignmentsForHIT_603070(path: JsonNode;
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
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_CreateAdditionalAssignmentsForHIT_603069;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_CreateAdditionalAssignmentsForHIT_603069;
          body: JsonNode): Recallable =
  ## createAdditionalAssignmentsForHIT
  ## <p> The <code>CreateAdditionalAssignmentsForHIT</code> operation increases the maximum number of assignments of an existing HIT. </p> <p> To extend the maximum number of assignments, specify the number of additional assignments.</p> <note> <ul> <li> <p>HITs created with fewer than 10 assignments cannot be extended to have 10 or more assignments. Attempting to add assignments in a way that brings the total number of assignments for a HIT from fewer than 10 assignments to 10 or more assignments will result in an <code>AWS.MechanicalTurk.InvalidMaximumAssignmentsIncrease</code> exception.</p> </li> <li> <p>HITs that were created before July 22, 2015 cannot be extended. Attempting to extend HITs that were created before July 22, 2015 will result in an <code>AWS.MechanicalTurk.HITTooOldForExtension</code> exception. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var createAdditionalAssignmentsForHIT* = Call_CreateAdditionalAssignmentsForHIT_603069(
    name: "createAdditionalAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateAdditionalAssignmentsForHIT",
    validator: validate_CreateAdditionalAssignmentsForHIT_603070, base: "/",
    url: url_CreateAdditionalAssignmentsForHIT_603071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHIT_603084 = ref object of OpenApiRestCall_602433
proc url_CreateHIT_603086(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHIT_603085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHIT"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_CreateHIT_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_CreateHIT_603084; body: JsonNode): Recallable =
  ## createHIT
  ## <p>The <code>CreateHIT</code> operation creates a new Human Intelligence Task (HIT). The new HIT is made available for Workers to find and accept on the Amazon Mechanical Turk website. </p> <p> This operation allows you to specify a new HIT by passing in values for the properties of the HIT, such as its title, reward amount and number of assignments. When you pass these values to <code>CreateHIT</code>, a new HIT is created for you, with a new <code>HITTypeID</code>. The HITTypeID can be used to create additional HITs in the future without needing to specify common parameters such as the title, description and reward amount each time.</p> <p> An alternative way to create HITs is to first generate a HITTypeID using the <code>CreateHITType</code> operation and then call the <code>CreateHITWithHITType</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHIT also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>.</p> </note>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var createHIT* = Call_CreateHIT_603084(name: "createHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHIT",
                                    validator: validate_CreateHIT_603085,
                                    base: "/", url: url_CreateHIT_603086,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITType_603099 = ref object of OpenApiRestCall_602433
proc url_CreateHITType_603101(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHITType_603100(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITType"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_CreateHITType_603099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_CreateHITType_603099; body: JsonNode): Recallable =
  ## createHITType
  ##  The <code>CreateHITType</code> operation creates a new HIT type. This operation allows you to define a standard set of HIT properties to use when creating HITs. If you register a HIT type with values that match an existing HIT type, the HIT type ID of the existing type will be returned. 
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var createHITType* = Call_CreateHITType_603099(name: "createHITType",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITType",
    validator: validate_CreateHITType_603100, base: "/", url: url_CreateHITType_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHITWithHITType_603114 = ref object of OpenApiRestCall_602433
proc url_CreateHITWithHITType_603116(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHITWithHITType_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateHITWithHITType"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_CreateHITWithHITType_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_CreateHITWithHITType_603114; body: JsonNode): Recallable =
  ## createHITWithHITType
  ## <p> The <code>CreateHITWithHITType</code> operation creates a new Human Intelligence Task (HIT) using an existing HITTypeID generated by the <code>CreateHITType</code> operation. </p> <p> This is an alternative way to create HITs from the <code>CreateHIT</code> operation. This is the recommended best practice for Requesters who are creating large numbers of HITs. </p> <p>CreateHITWithHITType also supports several ways to provide question data: by providing a value for the <code>Question</code> parameter that fully specifies the contents of the HIT, or by providing a <code>HitLayoutId</code> and associated <code>HitLayoutParameters</code>. </p> <note> <p> If a HIT is created with 10 or more maximum assignments, there is an additional fee. For more information, see <a href="https://requester.mturk.com/pricing">Amazon Mechanical Turk Pricing</a>. </p> </note>
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var createHITWithHITType* = Call_CreateHITWithHITType_603114(
    name: "createHITWithHITType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateHITWithHITType",
    validator: validate_CreateHITWithHITType_603115, base: "/",
    url: url_CreateHITWithHITType_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQualificationType_603129 = ref object of OpenApiRestCall_602433
proc url_CreateQualificationType_603131(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateQualificationType_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateQualificationType"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_CreateQualificationType_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_CreateQualificationType_603129; body: JsonNode): Recallable =
  ## createQualificationType
  ##  The <code>CreateQualificationType</code> operation creates a new Qualification type, which is represented by a <code>QualificationType</code> data structure. 
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var createQualificationType* = Call_CreateQualificationType_603129(
    name: "createQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateQualificationType",
    validator: validate_CreateQualificationType_603130, base: "/",
    url: url_CreateQualificationType_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkerBlock_603144 = ref object of OpenApiRestCall_602433
proc url_CreateWorkerBlock_603146(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateWorkerBlock_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.CreateWorkerBlock"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_CreateWorkerBlock_603144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_CreateWorkerBlock_603144; body: JsonNode): Recallable =
  ## createWorkerBlock
  ## The <code>CreateWorkerBlock</code> operation allows you to prevent a Worker from working on your HITs. For example, you can block a Worker who is producing poor quality work. You can block up to 100,000 Workers.
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var createWorkerBlock* = Call_CreateWorkerBlock_603144(name: "createWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.CreateWorkerBlock",
    validator: validate_CreateWorkerBlock_603145, base: "/",
    url: url_CreateWorkerBlock_603146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHIT_603159 = ref object of OpenApiRestCall_602433
proc url_DeleteHIT_603161(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteHIT_603160(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteHIT"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_DeleteHIT_603159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_DeleteHIT_603159; body: JsonNode): Recallable =
  ## deleteHIT
  ## <p> The <code>DeleteHIT</code> operation is used to delete HIT that is no longer needed. Only the Requester who created the HIT can delete it. </p> <p> You can only dispose of HITs that are in the <code>Reviewable</code> state, with all of their submitted assignments already either approved or rejected. If you call the DeleteHIT operation on a HIT that is not in the <code>Reviewable</code> state (for example, that has not expired, or still has active assignments), or on a HIT that is Reviewable but without all of its submitted assignments already approved or rejected, the service will return an error. </p> <note> <ul> <li> <p> HITs are automatically disposed of after 120 days. </p> </li> <li> <p> After you dispose of a HIT, you can no longer approve the HIT's rejected assignments. </p> </li> <li> <p> Disposed HITs are not returned in results for the ListHITs operation. </p> </li> <li> <p> Disposing HITs can improve the performance of operations such as ListReviewableHITs and ListHITs. </p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var deleteHIT* = Call_DeleteHIT_603159(name: "deleteHIT", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteHIT",
                                    validator: validate_DeleteHIT_603160,
                                    base: "/", url: url_DeleteHIT_603161,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQualificationType_603174 = ref object of OpenApiRestCall_602433
proc url_DeleteQualificationType_603176(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteQualificationType_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteQualificationType"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_DeleteQualificationType_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_DeleteQualificationType_603174; body: JsonNode): Recallable =
  ## deleteQualificationType
  ## <p> The <code>DeleteQualificationType</code> deletes a Qualification type and deletes any HIT types that are associated with the Qualification type. </p> <p>This operation does not revoke Qualifications already assigned to Workers because the Qualifications might be needed for active HITs. If there are any pending requests for the Qualification type, Amazon Mechanical Turk rejects those requests. After you delete a Qualification type, you can no longer use it to create HITs or HIT types.</p> <note> <p>DeleteQualificationType must wait for all the HITs that use the deleted Qualification type to be deleted before completing. It may take up to 48 hours before DeleteQualificationType completes and the unique name of the Qualification type is available for reuse with CreateQualificationType.</p> </note>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var deleteQualificationType* = Call_DeleteQualificationType_603174(
    name: "deleteQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteQualificationType",
    validator: validate_DeleteQualificationType_603175, base: "/",
    url: url_DeleteQualificationType_603176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkerBlock_603189 = ref object of OpenApiRestCall_602433
proc url_DeleteWorkerBlock_603191(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteWorkerBlock_603190(path: JsonNode; query: JsonNode;
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603194 = header.getOrDefault("X-Amz-Target")
  valid_603194 = validateParameter(valid_603194, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DeleteWorkerBlock"))
  if valid_603194 != nil:
    section.add "X-Amz-Target", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_DeleteWorkerBlock_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_DeleteWorkerBlock_603189; body: JsonNode): Recallable =
  ## deleteWorkerBlock
  ## The <code>DeleteWorkerBlock</code> operation allows you to reinstate a blocked Worker to work on your HITs. This operation reverses the effects of the CreateWorkerBlock operation. You need the Worker ID to use this operation. If the Worker ID is missing or invalid, this operation fails and returns the message “WorkerId is invalid.” If the specified Worker is not blocked, this operation returns successfully.
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var deleteWorkerBlock* = Call_DeleteWorkerBlock_603189(name: "deleteWorkerBlock",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DeleteWorkerBlock",
    validator: validate_DeleteWorkerBlock_603190, base: "/",
    url: url_DeleteWorkerBlock_603191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateQualificationFromWorker_603204 = ref object of OpenApiRestCall_602433
proc url_DisassociateQualificationFromWorker_603206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateQualificationFromWorker_603205(path: JsonNode;
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
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603209 = header.getOrDefault("X-Amz-Target")
  valid_603209 = validateParameter(valid_603209, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker"))
  if valid_603209 != nil:
    section.add "X-Amz-Target", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_DisassociateQualificationFromWorker_603204;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_DisassociateQualificationFromWorker_603204;
          body: JsonNode): Recallable =
  ## disassociateQualificationFromWorker
  ## <p> The <code>DisassociateQualificationFromWorker</code> revokes a previously granted Qualification from a user. </p> <p> You can provide a text message explaining why the Qualification was revoked. The user who had the Qualification can see this message. </p>
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var disassociateQualificationFromWorker* = Call_DisassociateQualificationFromWorker_603204(
    name: "disassociateQualificationFromWorker", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.DisassociateQualificationFromWorker",
    validator: validate_DisassociateQualificationFromWorker_603205, base: "/",
    url: url_DisassociateQualificationFromWorker_603206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountBalance_603219 = ref object of OpenApiRestCall_602433
proc url_GetAccountBalance_603221(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAccountBalance_603220(path: JsonNode; query: JsonNode;
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603224 = header.getOrDefault("X-Amz-Target")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAccountBalance"))
  if valid_603224 != nil:
    section.add "X-Amz-Target", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Content-Sha256", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Algorithm")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Algorithm", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Signature")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Signature", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Credential")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Credential", valid_603229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_GetAccountBalance_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_GetAccountBalance_603219; body: JsonNode): Recallable =
  ## getAccountBalance
  ## The <code>GetAccountBalance</code> operation retrieves the amount of money in your Amazon Mechanical Turk account.
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var getAccountBalance* = Call_GetAccountBalance_603219(name: "getAccountBalance",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAccountBalance",
    validator: validate_GetAccountBalance_603220, base: "/",
    url: url_GetAccountBalance_603221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssignment_603234 = ref object of OpenApiRestCall_602433
proc url_GetAssignment_603236(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssignment_603235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603239 = header.getOrDefault("X-Amz-Target")
  valid_603239 = validateParameter(valid_603239, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetAssignment"))
  if valid_603239 != nil:
    section.add "X-Amz-Target", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_GetAssignment_603234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_GetAssignment_603234; body: JsonNode): Recallable =
  ## getAssignment
  ##  The <code>GetAssignment</code> operation retrieves the details of the specified Assignment. 
  ##   body: JObject (required)
  var body_603248 = newJObject()
  if body != nil:
    body_603248 = body
  result = call_603247.call(nil, nil, nil, nil, body_603248)

var getAssignment* = Call_GetAssignment_603234(name: "getAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetAssignment",
    validator: validate_GetAssignment_603235, base: "/", url: url_GetAssignment_603236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFileUploadURL_603249 = ref object of OpenApiRestCall_602433
proc url_GetFileUploadURL_603251(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFileUploadURL_603250(path: JsonNode; query: JsonNode;
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
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603254 = header.getOrDefault("X-Amz-Target")
  valid_603254 = validateParameter(valid_603254, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetFileUploadURL"))
  if valid_603254 != nil:
    section.add "X-Amz-Target", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_GetFileUploadURL_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_GetFileUploadURL_603249; body: JsonNode): Recallable =
  ## getFileUploadURL
  ##  The <code>GetFileUploadURL</code> operation generates and returns a temporary URL. You use the temporary URL to retrieve a file uploaded by a Worker as an answer to a FileUploadAnswer question for a HIT. The temporary URL is generated the instant the GetFileUploadURL operation is called, and is valid for 60 seconds. You can get a temporary file upload URL any time until the HIT is disposed. After the HIT is disposed, any uploaded files are deleted, and cannot be retrieved. Pending Deprecation on December 12, 2017. The Answer Specification structure will no longer support the <code>FileUploadAnswer</code> element to be used for the QuestionForm data structure. Instead, we recommend that Requesters who want to create HITs asking Workers to upload files to use Amazon S3. 
  ##   body: JObject (required)
  var body_603263 = newJObject()
  if body != nil:
    body_603263 = body
  result = call_603262.call(nil, nil, nil, nil, body_603263)

var getFileUploadURL* = Call_GetFileUploadURL_603249(name: "getFileUploadURL",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetFileUploadURL",
    validator: validate_GetFileUploadURL_603250, base: "/",
    url: url_GetFileUploadURL_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHIT_603264 = ref object of OpenApiRestCall_602433
proc url_GetHIT_603266(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetHIT_603265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603269 = header.getOrDefault("X-Amz-Target")
  valid_603269 = validateParameter(valid_603269, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetHIT"))
  if valid_603269 != nil:
    section.add "X-Amz-Target", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_GetHIT_603264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_GetHIT_603264; body: JsonNode): Recallable =
  ## getHIT
  ##  The <code>GetHIT</code> operation retrieves the details of the specified HIT. 
  ##   body: JObject (required)
  var body_603278 = newJObject()
  if body != nil:
    body_603278 = body
  result = call_603277.call(nil, nil, nil, nil, body_603278)

var getHIT* = Call_GetHIT_603264(name: "getHIT", meth: HttpMethod.HttpPost,
                              host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetHIT",
                              validator: validate_GetHIT_603265, base: "/",
                              url: url_GetHIT_603266,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationScore_603279 = ref object of OpenApiRestCall_602433
proc url_GetQualificationScore_603281(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetQualificationScore_603280(path: JsonNode; query: JsonNode;
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603284 = header.getOrDefault("X-Amz-Target")
  valid_603284 = validateParameter(valid_603284, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationScore"))
  if valid_603284 != nil:
    section.add "X-Amz-Target", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603291: Call_GetQualificationScore_603279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_GetQualificationScore_603279; body: JsonNode): Recallable =
  ## getQualificationScore
  ## <p> The <code>GetQualificationScore</code> operation returns the value of a Worker's Qualification for a given Qualification type. </p> <p> To get a Worker's Qualification, you must know the Worker's ID. The Worker's ID is included in the assignment data returned by the <code>ListAssignmentsForHIT</code> operation. </p> <p>Only the owner of a Qualification type can query the value of a Worker's Qualification of that type.</p>
  ##   body: JObject (required)
  var body_603293 = newJObject()
  if body != nil:
    body_603293 = body
  result = call_603292.call(nil, nil, nil, nil, body_603293)

var getQualificationScore* = Call_GetQualificationScore_603279(
    name: "getQualificationScore", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationScore",
    validator: validate_GetQualificationScore_603280, base: "/",
    url: url_GetQualificationScore_603281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQualificationType_603294 = ref object of OpenApiRestCall_602433
proc url_GetQualificationType_603296(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetQualificationType_603295(path: JsonNode; query: JsonNode;
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
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603299 = header.getOrDefault("X-Amz-Target")
  valid_603299 = validateParameter(valid_603299, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.GetQualificationType"))
  if valid_603299 != nil:
    section.add "X-Amz-Target", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_GetQualificationType_603294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_GetQualificationType_603294; body: JsonNode): Recallable =
  ## getQualificationType
  ##  The <code>GetQualificationType</code>operation retrieves information about a Qualification type using its ID. 
  ##   body: JObject (required)
  var body_603308 = newJObject()
  if body != nil:
    body_603308 = body
  result = call_603307.call(nil, nil, nil, nil, body_603308)

var getQualificationType* = Call_GetQualificationType_603294(
    name: "getQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.GetQualificationType",
    validator: validate_GetQualificationType_603295, base: "/",
    url: url_GetQualificationType_603296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssignmentsForHIT_603309 = ref object of OpenApiRestCall_602433
proc url_ListAssignmentsForHIT_603311(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssignmentsForHIT_603310(path: JsonNode; query: JsonNode;
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
  var valid_603312 = query.getOrDefault("NextToken")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "NextToken", valid_603312
  var valid_603313 = query.getOrDefault("MaxResults")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "MaxResults", valid_603313
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
  var valid_603314 = header.getOrDefault("X-Amz-Date")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Date", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Security-Token")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Security-Token", valid_603315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603316 = header.getOrDefault("X-Amz-Target")
  valid_603316 = validateParameter(valid_603316, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListAssignmentsForHIT"))
  if valid_603316 != nil:
    section.add "X-Amz-Target", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Algorithm")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Algorithm", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Signature", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-SignedHeaders", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_ListAssignmentsForHIT_603309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"))
  result = hook(call_603323, url, valid)

proc call*(call_603324: Call_ListAssignmentsForHIT_603309; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssignmentsForHIT
  ## <p> The <code>ListAssignmentsForHIT</code> operation retrieves completed assignments for a HIT. You can use this operation to retrieve the results for a HIT. </p> <p> You can get assignments for a HIT at any time, even if the HIT is not yet Reviewable. If a HIT requested multiple assignments, and has received some results but has not yet become Reviewable, you can still retrieve the partial results with this operation. </p> <p> Use the AssignmentStatus parameter to control which set of assignments for a HIT are returned. The ListAssignmentsForHIT operation can return submitted assignments awaiting approval, or it can return assignments that have already been approved or rejected. You can set AssignmentStatus=Approved,Rejected to get assignments that have already been approved and rejected together in one result set. </p> <p> Only the Requester who created the HIT can retrieve the assignments for that HIT. </p> <p> Results are sorted and divided into numbered pages and the operation returns a single page of results. You can use the parameters of the operation to control sorting and pagination. </p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603325 = newJObject()
  var body_603326 = newJObject()
  add(query_603325, "NextToken", newJString(NextToken))
  if body != nil:
    body_603326 = body
  add(query_603325, "MaxResults", newJString(MaxResults))
  result = call_603324.call(nil, query_603325, nil, nil, body_603326)

var listAssignmentsForHIT* = Call_ListAssignmentsForHIT_603309(
    name: "listAssignmentsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListAssignmentsForHIT",
    validator: validate_ListAssignmentsForHIT_603310, base: "/",
    url: url_ListAssignmentsForHIT_603311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBonusPayments_603328 = ref object of OpenApiRestCall_602433
proc url_ListBonusPayments_603330(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBonusPayments_603329(path: JsonNode; query: JsonNode;
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
  var valid_603331 = query.getOrDefault("NextToken")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "NextToken", valid_603331
  var valid_603332 = query.getOrDefault("MaxResults")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "MaxResults", valid_603332
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
  var valid_603333 = header.getOrDefault("X-Amz-Date")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Date", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Security-Token")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Security-Token", valid_603334
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603335 = header.getOrDefault("X-Amz-Target")
  valid_603335 = validateParameter(valid_603335, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListBonusPayments"))
  if valid_603335 != nil:
    section.add "X-Amz-Target", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Content-Sha256", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Algorithm")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Algorithm", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Signature")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Signature", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-SignedHeaders", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Credential")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Credential", valid_603340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603342: Call_ListBonusPayments_603328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ## 
  let valid = call_603342.validator(path, query, header, formData, body)
  let scheme = call_603342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603342.url(scheme.get, call_603342.host, call_603342.base,
                         call_603342.route, valid.getOrDefault("path"))
  result = hook(call_603342, url, valid)

proc call*(call_603343: Call_ListBonusPayments_603328; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listBonusPayments
  ##  The <code>ListBonusPayments</code> operation retrieves the amounts of bonuses you have paid to Workers for a given HIT or assignment. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603344 = newJObject()
  var body_603345 = newJObject()
  add(query_603344, "NextToken", newJString(NextToken))
  if body != nil:
    body_603345 = body
  add(query_603344, "MaxResults", newJString(MaxResults))
  result = call_603343.call(nil, query_603344, nil, nil, body_603345)

var listBonusPayments* = Call_ListBonusPayments_603328(name: "listBonusPayments",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListBonusPayments",
    validator: validate_ListBonusPayments_603329, base: "/",
    url: url_ListBonusPayments_603330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITs_603346 = ref object of OpenApiRestCall_602433
proc url_ListHITs_603348(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHITs_603347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603349 = query.getOrDefault("NextToken")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "NextToken", valid_603349
  var valid_603350 = query.getOrDefault("MaxResults")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "MaxResults", valid_603350
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
  var valid_603351 = header.getOrDefault("X-Amz-Date")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Date", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Security-Token")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Security-Token", valid_603352
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603353 = header.getOrDefault("X-Amz-Target")
  valid_603353 = validateParameter(valid_603353, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITs"))
  if valid_603353 != nil:
    section.add "X-Amz-Target", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Content-Sha256", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Algorithm")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Algorithm", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Signature")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Signature", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-SignedHeaders", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Credential")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Credential", valid_603358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603360: Call_ListHITs_603346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ## 
  let valid = call_603360.validator(path, query, header, formData, body)
  let scheme = call_603360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603360.url(scheme.get, call_603360.host, call_603360.base,
                         call_603360.route, valid.getOrDefault("path"))
  result = hook(call_603360, url, valid)

proc call*(call_603361: Call_ListHITs_603346; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listHITs
  ##  The <code>ListHITs</code> operation returns all of a Requester's HITs. The operation returns HITs of any status, except for HITs that have been deleted of with the DeleteHIT operation or that have been auto-deleted. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603362 = newJObject()
  var body_603363 = newJObject()
  add(query_603362, "NextToken", newJString(NextToken))
  if body != nil:
    body_603363 = body
  add(query_603362, "MaxResults", newJString(MaxResults))
  result = call_603361.call(nil, query_603362, nil, nil, body_603363)

var listHITs* = Call_ListHITs_603346(name: "listHITs", meth: HttpMethod.HttpPost,
                                  host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITs",
                                  validator: validate_ListHITs_603347, base: "/",
                                  url: url_ListHITs_603348,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHITsForQualificationType_603364 = ref object of OpenApiRestCall_602433
proc url_ListHITsForQualificationType_603366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHITsForQualificationType_603365(path: JsonNode; query: JsonNode;
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
  var valid_603367 = query.getOrDefault("NextToken")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "NextToken", valid_603367
  var valid_603368 = query.getOrDefault("MaxResults")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "MaxResults", valid_603368
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
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Security-Token")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Security-Token", valid_603370
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603371 = header.getOrDefault("X-Amz-Target")
  valid_603371 = validateParameter(valid_603371, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListHITsForQualificationType"))
  if valid_603371 != nil:
    section.add "X-Amz-Target", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Content-Sha256", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Algorithm")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Algorithm", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Signature")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Signature", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-SignedHeaders", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_ListHITsForQualificationType_603364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_ListHITsForQualificationType_603364; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHITsForQualificationType
  ##  The <code>ListHITsForQualificationType</code> operation returns the HITs that use the given Qualification type for a Qualification requirement. The operation returns HITs of any status, except for HITs that have been deleted with the <code>DeleteHIT</code> operation or that have been auto-deleted. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603380 = newJObject()
  var body_603381 = newJObject()
  add(query_603380, "NextToken", newJString(NextToken))
  if body != nil:
    body_603381 = body
  add(query_603380, "MaxResults", newJString(MaxResults))
  result = call_603379.call(nil, query_603380, nil, nil, body_603381)

var listHITsForQualificationType* = Call_ListHITsForQualificationType_603364(
    name: "listHITsForQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListHITsForQualificationType",
    validator: validate_ListHITsForQualificationType_603365, base: "/",
    url: url_ListHITsForQualificationType_603366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationRequests_603382 = ref object of OpenApiRestCall_602433
proc url_ListQualificationRequests_603384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQualificationRequests_603383(path: JsonNode; query: JsonNode;
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
  var valid_603385 = query.getOrDefault("NextToken")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "NextToken", valid_603385
  var valid_603386 = query.getOrDefault("MaxResults")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "MaxResults", valid_603386
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
  var valid_603387 = header.getOrDefault("X-Amz-Date")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Date", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Security-Token")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Security-Token", valid_603388
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603389 = header.getOrDefault("X-Amz-Target")
  valid_603389 = validateParameter(valid_603389, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationRequests"))
  if valid_603389 != nil:
    section.add "X-Amz-Target", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Content-Sha256", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Algorithm")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Algorithm", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Signature")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Signature", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Credential")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Credential", valid_603394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603396: Call_ListQualificationRequests_603382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ## 
  let valid = call_603396.validator(path, query, header, formData, body)
  let scheme = call_603396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603396.url(scheme.get, call_603396.host, call_603396.base,
                         call_603396.route, valid.getOrDefault("path"))
  result = hook(call_603396, url, valid)

proc call*(call_603397: Call_ListQualificationRequests_603382; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQualificationRequests
  ##  The <code>ListQualificationRequests</code> operation retrieves requests for Qualifications of a particular Qualification type. The owner of the Qualification type calls this operation to poll for pending requests, and accepts them using the AcceptQualification operation. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603398 = newJObject()
  var body_603399 = newJObject()
  add(query_603398, "NextToken", newJString(NextToken))
  if body != nil:
    body_603399 = body
  add(query_603398, "MaxResults", newJString(MaxResults))
  result = call_603397.call(nil, query_603398, nil, nil, body_603399)

var listQualificationRequests* = Call_ListQualificationRequests_603382(
    name: "listQualificationRequests", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationRequests",
    validator: validate_ListQualificationRequests_603383, base: "/",
    url: url_ListQualificationRequests_603384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQualificationTypes_603400 = ref object of OpenApiRestCall_602433
proc url_ListQualificationTypes_603402(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQualificationTypes_603401(path: JsonNode; query: JsonNode;
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
  var valid_603403 = query.getOrDefault("NextToken")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "NextToken", valid_603403
  var valid_603404 = query.getOrDefault("MaxResults")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "MaxResults", valid_603404
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
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListQualificationTypes"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_ListQualificationTypes_603400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_ListQualificationTypes_603400; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listQualificationTypes
  ##  The <code>ListQualificationTypes</code> operation returns a list of Qualification types, filtered by an optional search term. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603416 = newJObject()
  var body_603417 = newJObject()
  add(query_603416, "NextToken", newJString(NextToken))
  if body != nil:
    body_603417 = body
  add(query_603416, "MaxResults", newJString(MaxResults))
  result = call_603415.call(nil, query_603416, nil, nil, body_603417)

var listQualificationTypes* = Call_ListQualificationTypes_603400(
    name: "listQualificationTypes", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListQualificationTypes",
    validator: validate_ListQualificationTypes_603401, base: "/",
    url: url_ListQualificationTypes_603402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewPolicyResultsForHIT_603418 = ref object of OpenApiRestCall_602433
proc url_ListReviewPolicyResultsForHIT_603420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListReviewPolicyResultsForHIT_603419(path: JsonNode; query: JsonNode;
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
  var valid_603421 = query.getOrDefault("NextToken")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "NextToken", valid_603421
  var valid_603422 = query.getOrDefault("MaxResults")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "MaxResults", valid_603422
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
  var valid_603423 = header.getOrDefault("X-Amz-Date")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Date", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Security-Token")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Security-Token", valid_603424
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603425 = header.getOrDefault("X-Amz-Target")
  valid_603425 = validateParameter(valid_603425, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT"))
  if valid_603425 != nil:
    section.add "X-Amz-Target", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Content-Sha256", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Algorithm")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Algorithm", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Signature")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Signature", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-SignedHeaders", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Credential")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Credential", valid_603430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603432: Call_ListReviewPolicyResultsForHIT_603418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ## 
  let valid = call_603432.validator(path, query, header, formData, body)
  let scheme = call_603432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603432.url(scheme.get, call_603432.host, call_603432.base,
                         call_603432.route, valid.getOrDefault("path"))
  result = hook(call_603432, url, valid)

proc call*(call_603433: Call_ListReviewPolicyResultsForHIT_603418; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listReviewPolicyResultsForHIT
  ##  The <code>ListReviewPolicyResultsForHIT</code> operation retrieves the computed results and the actions taken in the course of executing your Review Policies for a given HIT. For information about how to specify Review Policies when you call CreateHIT, see Review Policies. The ListReviewPolicyResultsForHIT operation can return results for both Assignment-level and HIT-level review results. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603434 = newJObject()
  var body_603435 = newJObject()
  add(query_603434, "NextToken", newJString(NextToken))
  if body != nil:
    body_603435 = body
  add(query_603434, "MaxResults", newJString(MaxResults))
  result = call_603433.call(nil, query_603434, nil, nil, body_603435)

var listReviewPolicyResultsForHIT* = Call_ListReviewPolicyResultsForHIT_603418(
    name: "listReviewPolicyResultsForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewPolicyResultsForHIT",
    validator: validate_ListReviewPolicyResultsForHIT_603419, base: "/",
    url: url_ListReviewPolicyResultsForHIT_603420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReviewableHITs_603436 = ref object of OpenApiRestCall_602433
proc url_ListReviewableHITs_603438(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListReviewableHITs_603437(path: JsonNode; query: JsonNode;
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
  var valid_603439 = query.getOrDefault("NextToken")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "NextToken", valid_603439
  var valid_603440 = query.getOrDefault("MaxResults")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "MaxResults", valid_603440
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
  var valid_603441 = header.getOrDefault("X-Amz-Date")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Date", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Security-Token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Security-Token", valid_603442
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603443 = header.getOrDefault("X-Amz-Target")
  valid_603443 = validateParameter(valid_603443, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListReviewableHITs"))
  if valid_603443 != nil:
    section.add "X-Amz-Target", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Content-Sha256", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Algorithm")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Algorithm", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Signature")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Signature", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-SignedHeaders", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Credential")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Credential", valid_603448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603450: Call_ListReviewableHITs_603436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ## 
  let valid = call_603450.validator(path, query, header, formData, body)
  let scheme = call_603450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603450.url(scheme.get, call_603450.host, call_603450.base,
                         call_603450.route, valid.getOrDefault("path"))
  result = hook(call_603450, url, valid)

proc call*(call_603451: Call_ListReviewableHITs_603436; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listReviewableHITs
  ##  The <code>ListReviewableHITs</code> operation retrieves the HITs with Status equal to Reviewable or Status equal to Reviewing that belong to the Requester calling the operation. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603452 = newJObject()
  var body_603453 = newJObject()
  add(query_603452, "NextToken", newJString(NextToken))
  if body != nil:
    body_603453 = body
  add(query_603452, "MaxResults", newJString(MaxResults))
  result = call_603451.call(nil, query_603452, nil, nil, body_603453)

var listReviewableHITs* = Call_ListReviewableHITs_603436(
    name: "listReviewableHITs", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListReviewableHITs",
    validator: validate_ListReviewableHITs_603437, base: "/",
    url: url_ListReviewableHITs_603438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkerBlocks_603454 = ref object of OpenApiRestCall_602433
proc url_ListWorkerBlocks_603456(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWorkerBlocks_603455(path: JsonNode; query: JsonNode;
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
  var valid_603457 = query.getOrDefault("NextToken")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "NextToken", valid_603457
  var valid_603458 = query.getOrDefault("MaxResults")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "MaxResults", valid_603458
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
  var valid_603459 = header.getOrDefault("X-Amz-Date")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Date", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Security-Token")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Security-Token", valid_603460
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603461 = header.getOrDefault("X-Amz-Target")
  valid_603461 = validateParameter(valid_603461, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkerBlocks"))
  if valid_603461 != nil:
    section.add "X-Amz-Target", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Content-Sha256", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Algorithm")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Algorithm", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Signature")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Signature", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-SignedHeaders", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Credential")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Credential", valid_603466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603468: Call_ListWorkerBlocks_603454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ## 
  let valid = call_603468.validator(path, query, header, formData, body)
  let scheme = call_603468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603468.url(scheme.get, call_603468.host, call_603468.base,
                         call_603468.route, valid.getOrDefault("path"))
  result = hook(call_603468, url, valid)

proc call*(call_603469: Call_ListWorkerBlocks_603454; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkerBlocks
  ## The <code>ListWorkersBlocks</code> operation retrieves a list of Workers who are blocked from working on your HITs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603470 = newJObject()
  var body_603471 = newJObject()
  add(query_603470, "NextToken", newJString(NextToken))
  if body != nil:
    body_603471 = body
  add(query_603470, "MaxResults", newJString(MaxResults))
  result = call_603469.call(nil, query_603470, nil, nil, body_603471)

var listWorkerBlocks* = Call_ListWorkerBlocks_603454(name: "listWorkerBlocks",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkerBlocks",
    validator: validate_ListWorkerBlocks_603455, base: "/",
    url: url_ListWorkerBlocks_603456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkersWithQualificationType_603472 = ref object of OpenApiRestCall_602433
proc url_ListWorkersWithQualificationType_603474(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWorkersWithQualificationType_603473(path: JsonNode;
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
  var valid_603475 = query.getOrDefault("NextToken")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "NextToken", valid_603475
  var valid_603476 = query.getOrDefault("MaxResults")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "MaxResults", valid_603476
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
  var valid_603477 = header.getOrDefault("X-Amz-Date")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Date", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Security-Token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Security-Token", valid_603478
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603479 = header.getOrDefault("X-Amz-Target")
  valid_603479 = validateParameter(valid_603479, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.ListWorkersWithQualificationType"))
  if valid_603479 != nil:
    section.add "X-Amz-Target", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Content-Sha256", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Algorithm")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Algorithm", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Signature")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Signature", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-SignedHeaders", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Credential")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Credential", valid_603484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603486: Call_ListWorkersWithQualificationType_603472;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ## 
  let valid = call_603486.validator(path, query, header, formData, body)
  let scheme = call_603486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603486.url(scheme.get, call_603486.host, call_603486.base,
                         call_603486.route, valid.getOrDefault("path"))
  result = hook(call_603486, url, valid)

proc call*(call_603487: Call_ListWorkersWithQualificationType_603472;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkersWithQualificationType
  ##  The <code>ListWorkersWithQualificationType</code> operation returns all of the Workers that have been associated with a given Qualification type. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603488 = newJObject()
  var body_603489 = newJObject()
  add(query_603488, "NextToken", newJString(NextToken))
  if body != nil:
    body_603489 = body
  add(query_603488, "MaxResults", newJString(MaxResults))
  result = call_603487.call(nil, query_603488, nil, nil, body_603489)

var listWorkersWithQualificationType* = Call_ListWorkersWithQualificationType_603472(
    name: "listWorkersWithQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.ListWorkersWithQualificationType",
    validator: validate_ListWorkersWithQualificationType_603473, base: "/",
    url: url_ListWorkersWithQualificationType_603474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_NotifyWorkers_603490 = ref object of OpenApiRestCall_602433
proc url_NotifyWorkers_603492(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_NotifyWorkers_603491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603493 = header.getOrDefault("X-Amz-Date")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Date", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Security-Token")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Security-Token", valid_603494
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603495 = header.getOrDefault("X-Amz-Target")
  valid_603495 = validateParameter(valid_603495, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.NotifyWorkers"))
  if valid_603495 != nil:
    section.add "X-Amz-Target", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Content-Sha256", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Algorithm")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Algorithm", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Signature")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Signature", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-SignedHeaders", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Credential")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Credential", valid_603500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603502: Call_NotifyWorkers_603490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ## 
  let valid = call_603502.validator(path, query, header, formData, body)
  let scheme = call_603502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603502.url(scheme.get, call_603502.host, call_603502.base,
                         call_603502.route, valid.getOrDefault("path"))
  result = hook(call_603502, url, valid)

proc call*(call_603503: Call_NotifyWorkers_603490; body: JsonNode): Recallable =
  ## notifyWorkers
  ##  The <code>NotifyWorkers</code> operation sends an email to one or more Workers that you specify with the Worker ID. You can specify up to 100 Worker IDs to send the same message with a single call to the NotifyWorkers operation. The NotifyWorkers operation will send a notification email to a Worker only if you have previously approved or rejected work from the Worker. 
  ##   body: JObject (required)
  var body_603504 = newJObject()
  if body != nil:
    body_603504 = body
  result = call_603503.call(nil, nil, nil, nil, body_603504)

var notifyWorkers* = Call_NotifyWorkers_603490(name: "notifyWorkers",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.NotifyWorkers",
    validator: validate_NotifyWorkers_603491, base: "/", url: url_NotifyWorkers_603492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectAssignment_603505 = ref object of OpenApiRestCall_602433
proc url_RejectAssignment_603507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectAssignment_603506(path: JsonNode; query: JsonNode;
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
  var valid_603508 = header.getOrDefault("X-Amz-Date")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Date", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603510 = header.getOrDefault("X-Amz-Target")
  valid_603510 = validateParameter(valid_603510, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectAssignment"))
  if valid_603510 != nil:
    section.add "X-Amz-Target", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Content-Sha256", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Algorithm")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Algorithm", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Signature")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Signature", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-SignedHeaders", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_RejectAssignment_603505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ## 
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"))
  result = hook(call_603517, url, valid)

proc call*(call_603518: Call_RejectAssignment_603505; body: JsonNode): Recallable =
  ## rejectAssignment
  ## <p> The <code>RejectAssignment</code> operation rejects the results of a completed assignment. </p> <p> You can include an optional feedback message with the rejection, which the Worker can see in the Status section of the web site. When you include a feedback message with the rejection, it helps the Worker understand why the assignment was rejected, and can improve the quality of the results the Worker submits in the future. </p> <p> Only the Requester who created the HIT can reject an assignment for the HIT. </p>
  ##   body: JObject (required)
  var body_603519 = newJObject()
  if body != nil:
    body_603519 = body
  result = call_603518.call(nil, nil, nil, nil, body_603519)

var rejectAssignment* = Call_RejectAssignment_603505(name: "rejectAssignment",
    meth: HttpMethod.HttpPost, host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectAssignment",
    validator: validate_RejectAssignment_603506, base: "/",
    url: url_RejectAssignment_603507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectQualificationRequest_603520 = ref object of OpenApiRestCall_602433
proc url_RejectQualificationRequest_603522(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RejectQualificationRequest_603521(path: JsonNode; query: JsonNode;
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
  var valid_603523 = header.getOrDefault("X-Amz-Date")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Date", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Security-Token")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Security-Token", valid_603524
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603525 = header.getOrDefault("X-Amz-Target")
  valid_603525 = validateParameter(valid_603525, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.RejectQualificationRequest"))
  if valid_603525 != nil:
    section.add "X-Amz-Target", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Signature")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Signature", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-SignedHeaders", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Credential")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Credential", valid_603530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603532: Call_RejectQualificationRequest_603520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ## 
  let valid = call_603532.validator(path, query, header, formData, body)
  let scheme = call_603532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603532.url(scheme.get, call_603532.host, call_603532.base,
                         call_603532.route, valid.getOrDefault("path"))
  result = hook(call_603532, url, valid)

proc call*(call_603533: Call_RejectQualificationRequest_603520; body: JsonNode): Recallable =
  ## rejectQualificationRequest
  ## <p> The <code>RejectQualificationRequest</code> operation rejects a user's request for a Qualification. </p> <p> You can provide a text message explaining why the request was rejected. The Worker who made the request can see this message.</p>
  ##   body: JObject (required)
  var body_603534 = newJObject()
  if body != nil:
    body_603534 = body
  result = call_603533.call(nil, nil, nil, nil, body_603534)

var rejectQualificationRequest* = Call_RejectQualificationRequest_603520(
    name: "rejectQualificationRequest", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.RejectQualificationRequest",
    validator: validate_RejectQualificationRequest_603521, base: "/",
    url: url_RejectQualificationRequest_603522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendBonus_603535 = ref object of OpenApiRestCall_602433
proc url_SendBonus_603537(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendBonus_603536(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Security-Token")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Security-Token", valid_603539
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603540 = header.getOrDefault("X-Amz-Target")
  valid_603540 = validateParameter(valid_603540, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendBonus"))
  if valid_603540 != nil:
    section.add "X-Amz-Target", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Content-Sha256", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Algorithm")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Algorithm", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Signature")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Signature", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-SignedHeaders", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Credential")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Credential", valid_603545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603547: Call_SendBonus_603535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ## 
  let valid = call_603547.validator(path, query, header, formData, body)
  let scheme = call_603547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603547.url(scheme.get, call_603547.host, call_603547.base,
                         call_603547.route, valid.getOrDefault("path"))
  result = hook(call_603547, url, valid)

proc call*(call_603548: Call_SendBonus_603535; body: JsonNode): Recallable =
  ## sendBonus
  ##  The <code>SendBonus</code> operation issues a payment of money from your account to a Worker. This payment happens separately from the reward you pay to the Worker when you approve the Worker's assignment. The SendBonus operation requires the Worker's ID and the assignment ID as parameters to initiate payment of the bonus. You must include a message that explains the reason for the bonus payment, as the Worker may not be expecting the payment. Amazon Mechanical Turk collects a fee for bonus payments, similar to the HIT listing fee. This operation fails if your account does not have enough funds to pay for both the bonus and the fees. 
  ##   body: JObject (required)
  var body_603549 = newJObject()
  if body != nil:
    body_603549 = body
  result = call_603548.call(nil, nil, nil, nil, body_603549)

var sendBonus* = Call_SendBonus_603535(name: "sendBonus", meth: HttpMethod.HttpPost,
                                    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendBonus",
                                    validator: validate_SendBonus_603536,
                                    base: "/", url: url_SendBonus_603537,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTestEventNotification_603550 = ref object of OpenApiRestCall_602433
proc url_SendTestEventNotification_603552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SendTestEventNotification_603551(path: JsonNode; query: JsonNode;
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
  var valid_603553 = header.getOrDefault("X-Amz-Date")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Date", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Security-Token")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Security-Token", valid_603554
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603555 = header.getOrDefault("X-Amz-Target")
  valid_603555 = validateParameter(valid_603555, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.SendTestEventNotification"))
  if valid_603555 != nil:
    section.add "X-Amz-Target", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Content-Sha256", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Algorithm")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Algorithm", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Signature")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Signature", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-SignedHeaders", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Credential")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Credential", valid_603560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_SendTestEventNotification_603550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"))
  result = hook(call_603562, url, valid)

proc call*(call_603563: Call_SendTestEventNotification_603550; body: JsonNode): Recallable =
  ## sendTestEventNotification
  ##  The <code>SendTestEventNotification</code> operation causes Amazon Mechanical Turk to send a notification message as if a HIT event occurred, according to the provided notification specification. This allows you to test notifications without setting up notifications for a real HIT type and trying to trigger them using the website. When you call this operation, the service attempts to send the test notification immediately. 
  ##   body: JObject (required)
  var body_603564 = newJObject()
  if body != nil:
    body_603564 = body
  result = call_603563.call(nil, nil, nil, nil, body_603564)

var sendTestEventNotification* = Call_SendTestEventNotification_603550(
    name: "sendTestEventNotification", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.SendTestEventNotification",
    validator: validate_SendTestEventNotification_603551, base: "/",
    url: url_SendTestEventNotification_603552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExpirationForHIT_603565 = ref object of OpenApiRestCall_602433
proc url_UpdateExpirationForHIT_603567(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateExpirationForHIT_603566(path: JsonNode; query: JsonNode;
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
  var valid_603568 = header.getOrDefault("X-Amz-Date")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Date", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Security-Token")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Security-Token", valid_603569
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603570 = header.getOrDefault("X-Amz-Target")
  valid_603570 = validateParameter(valid_603570, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateExpirationForHIT"))
  if valid_603570 != nil:
    section.add "X-Amz-Target", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Algorithm")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Algorithm", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Signature")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Signature", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-SignedHeaders", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Credential")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Credential", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603577: Call_UpdateExpirationForHIT_603565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ## 
  let valid = call_603577.validator(path, query, header, formData, body)
  let scheme = call_603577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603577.url(scheme.get, call_603577.host, call_603577.base,
                         call_603577.route, valid.getOrDefault("path"))
  result = hook(call_603577, url, valid)

proc call*(call_603578: Call_UpdateExpirationForHIT_603565; body: JsonNode): Recallable =
  ## updateExpirationForHIT
  ##  The <code>UpdateExpirationForHIT</code> operation allows you update the expiration time of a HIT. If you update it to a time in the past, the HIT will be immediately expired. 
  ##   body: JObject (required)
  var body_603579 = newJObject()
  if body != nil:
    body_603579 = body
  result = call_603578.call(nil, nil, nil, nil, body_603579)

var updateExpirationForHIT* = Call_UpdateExpirationForHIT_603565(
    name: "updateExpirationForHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateExpirationForHIT",
    validator: validate_UpdateExpirationForHIT_603566, base: "/",
    url: url_UpdateExpirationForHIT_603567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITReviewStatus_603580 = ref object of OpenApiRestCall_602433
proc url_UpdateHITReviewStatus_603582(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateHITReviewStatus_603581(path: JsonNode; query: JsonNode;
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
  var valid_603583 = header.getOrDefault("X-Amz-Date")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Date", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Security-Token")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Security-Token", valid_603584
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603585 = header.getOrDefault("X-Amz-Target")
  valid_603585 = validateParameter(valid_603585, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITReviewStatus"))
  if valid_603585 != nil:
    section.add "X-Amz-Target", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_UpdateHITReviewStatus_603580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_UpdateHITReviewStatus_603580; body: JsonNode): Recallable =
  ## updateHITReviewStatus
  ##  The <code>UpdateHITReviewStatus</code> operation updates the status of a HIT. If the status is Reviewable, this operation can update the status to Reviewing, or it can revert a Reviewing HIT back to the Reviewable status. 
  ##   body: JObject (required)
  var body_603594 = newJObject()
  if body != nil:
    body_603594 = body
  result = call_603593.call(nil, nil, nil, nil, body_603594)

var updateHITReviewStatus* = Call_UpdateHITReviewStatus_603580(
    name: "updateHITReviewStatus", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITReviewStatus",
    validator: validate_UpdateHITReviewStatus_603581, base: "/",
    url: url_UpdateHITReviewStatus_603582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHITTypeOfHIT_603595 = ref object of OpenApiRestCall_602433
proc url_UpdateHITTypeOfHIT_603597(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateHITTypeOfHIT_603596(path: JsonNode; query: JsonNode;
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
  var valid_603598 = header.getOrDefault("X-Amz-Date")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Date", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Security-Token")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Security-Token", valid_603599
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603600 = header.getOrDefault("X-Amz-Target")
  valid_603600 = validateParameter(valid_603600, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT"))
  if valid_603600 != nil:
    section.add "X-Amz-Target", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_UpdateHITTypeOfHIT_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_UpdateHITTypeOfHIT_603595; body: JsonNode): Recallable =
  ## updateHITTypeOfHIT
  ##  The <code>UpdateHITTypeOfHIT</code> operation allows you to change the HITType properties of a HIT. This operation disassociates the HIT from its old HITType properties and associates it with the new HITType properties. The HIT takes on the properties of the new HITType in place of the old ones. 
  ##   body: JObject (required)
  var body_603609 = newJObject()
  if body != nil:
    body_603609 = body
  result = call_603608.call(nil, nil, nil, nil, body_603609)

var updateHITTypeOfHIT* = Call_UpdateHITTypeOfHIT_603595(
    name: "updateHITTypeOfHIT", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com",
    route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateHITTypeOfHIT",
    validator: validate_UpdateHITTypeOfHIT_603596, base: "/",
    url: url_UpdateHITTypeOfHIT_603597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationSettings_603610 = ref object of OpenApiRestCall_602433
proc url_UpdateNotificationSettings_603612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateNotificationSettings_603611(path: JsonNode; query: JsonNode;
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
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603615 = header.getOrDefault("X-Amz-Target")
  valid_603615 = validateParameter(valid_603615, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateNotificationSettings"))
  if valid_603615 != nil:
    section.add "X-Amz-Target", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Algorithm")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Algorithm", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Signature")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Signature", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-SignedHeaders", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Credential")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Credential", valid_603620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_UpdateNotificationSettings_603610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_UpdateNotificationSettings_603610; body: JsonNode): Recallable =
  ## updateNotificationSettings
  ##  The <code>UpdateNotificationSettings</code> operation creates, updates, disables or re-enables notifications for a HIT type. If you call the UpdateNotificationSettings operation for a HIT type that already has a notification specification, the operation replaces the old specification with a new one. You can call the UpdateNotificationSettings operation to enable or disable notifications for the HIT type, without having to modify the notification specification itself by providing updates to the Active status without specifying a new notification specification. To change the Active status of a HIT type's notifications, the HIT type must already have a notification specification, or one must be provided in the same call to <code>UpdateNotificationSettings</code>. 
  ##   body: JObject (required)
  var body_603624 = newJObject()
  if body != nil:
    body_603624 = body
  result = call_603623.call(nil, nil, nil, nil, body_603624)

var updateNotificationSettings* = Call_UpdateNotificationSettings_603610(
    name: "updateNotificationSettings", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateNotificationSettings",
    validator: validate_UpdateNotificationSettings_603611, base: "/",
    url: url_UpdateNotificationSettings_603612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateQualificationType_603625 = ref object of OpenApiRestCall_602433
proc url_UpdateQualificationType_603627(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateQualificationType_603626(path: JsonNode; query: JsonNode;
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
  var valid_603628 = header.getOrDefault("X-Amz-Date")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Date", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Security-Token")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Security-Token", valid_603629
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603630 = header.getOrDefault("X-Amz-Target")
  valid_603630 = validateParameter(valid_603630, JString, required = true, default = newJString(
      "MTurkRequesterServiceV20170117.UpdateQualificationType"))
  if valid_603630 != nil:
    section.add "X-Amz-Target", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Algorithm")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Algorithm", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Signature")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Signature", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-SignedHeaders", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Credential")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Credential", valid_603635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603637: Call_UpdateQualificationType_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ## 
  let valid = call_603637.validator(path, query, header, formData, body)
  let scheme = call_603637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603637.url(scheme.get, call_603637.host, call_603637.base,
                         call_603637.route, valid.getOrDefault("path"))
  result = hook(call_603637, url, valid)

proc call*(call_603638: Call_UpdateQualificationType_603625; body: JsonNode): Recallable =
  ## updateQualificationType
  ## <p> The <code>UpdateQualificationType</code> operation modifies the attributes of an existing Qualification type, which is represented by a QualificationType data structure. Only the owner of a Qualification type can modify its attributes. </p> <p> Most attributes of a Qualification type can be changed after the type has been created. However, the Name and Keywords fields cannot be modified. The RetryDelayInSeconds parameter can be modified or added to change the delay or to enable retries, but RetryDelayInSeconds cannot be used to disable retries. </p> <p> You can use this operation to update the test for a Qualification type. The test is updated based on the values specified for the Test, TestDurationInSeconds and AnswerKey parameters. All three parameters specify the updated test. If you are updating the test for a type, you must specify the Test and TestDurationInSeconds parameters. The AnswerKey parameter is optional; omitting it specifies that the updated test does not have an answer key. </p> <p> If you omit the Test parameter, the test for the Qualification type is unchanged. There is no way to remove a test from a Qualification type that has one. If the type already has a test, you cannot update it to be AutoGranted. If the Qualification type does not have a test and one is provided by an update, the type will henceforth have a test. </p> <p> If you want to update the test duration or answer key for an existing test without changing the questions, you must specify a Test parameter with the original questions, along with the updated values. </p> <p> If you provide an updated Test but no AnswerKey, the new test will not have an answer key. Requests for such Qualifications must be granted manually. </p> <p> You can also update the AutoGranted and AutoGrantedValue attributes of the Qualification type.</p>
  ##   body: JObject (required)
  var body_603639 = newJObject()
  if body != nil:
    body_603639 = body
  result = call_603638.call(nil, nil, nil, nil, body_603639)

var updateQualificationType* = Call_UpdateQualificationType_603625(
    name: "updateQualificationType", meth: HttpMethod.HttpPost,
    host: "mturk-requester.amazonaws.com", route: "/#X-Amz-Target=MTurkRequesterServiceV20170117.UpdateQualificationType",
    validator: validate_UpdateQualificationType_603626, base: "/",
    url: url_UpdateQualificationType_603627, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
