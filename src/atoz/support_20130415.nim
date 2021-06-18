
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Support
## version: 2013-04-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Support</fullname> <p>The AWS Support API reference is intended for programmers who need detailed information about the AWS Support operations and data types. This service enables you to manage your AWS Support cases programmatically. It uses HTTP methods that return results in JSON format.</p> <p>The AWS Support service also exposes a set of <a href="http://aws.amazon.com/premiumsupport/trustedadvisor/">Trusted Advisor</a> features. You can retrieve a list of checks and their descriptions, get check results, specify checks to refresh, and get the refresh status of checks.</p> <p>The following list describes the AWS Support case management operations:</p> <ul> <li> <p> <b>Service names, issue categories, and available severity levels. </b>The <a>DescribeServices</a> and <a>DescribeSeverityLevels</a> operations return AWS service names, service codes, service categories, and problem severity levels. You use these values when you call the <a>CreateCase</a> operation.</p> </li> <li> <p> <b>Case creation, case details, and case resolution.</b> The <a>CreateCase</a>, <a>DescribeCases</a>, <a>DescribeAttachment</a>, and <a>ResolveCase</a> operations create AWS Support cases, retrieve information about cases, and resolve cases.</p> </li> <li> <p> <b>Case communication.</b> The <a>DescribeCommunications</a>, <a>AddCommunicationToCase</a>, and <a>AddAttachmentsToSet</a> operations retrieve and add communications and attachments to AWS Support cases.</p> </li> </ul> <p>The following list describes the operations available from the AWS Support service for Trusted Advisor:</p> <ul> <li> <p> <a>DescribeTrustedAdvisorChecks</a> returns the list of checks that run against your AWS resources.</p> </li> <li> <p>Using the <code>checkId</code> for a specific check returned by <a>DescribeTrustedAdvisorChecks</a>, you can call <a>DescribeTrustedAdvisorCheckResult</a> to obtain the results for the check you specified.</p> </li> <li> <p> <a>DescribeTrustedAdvisorCheckSummaries</a> returns summarized results for one or more Trusted Advisor checks.</p> </li> <li> <p> <a>RefreshTrustedAdvisorCheck</a> requests that Trusted Advisor rerun a specified check.</p> </li> <li> <p> <a>DescribeTrustedAdvisorCheckRefreshStatuses</a> reports the refresh status of one or more checks.</p> </li> </ul> <p>For authentication of requests, AWS Support uses <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>.</p> <p>See <a href="https://docs.aws.amazon.com/awssupport/latest/user/Welcome.html">About the AWS Support API</a> in the <i>AWS Support User Guide</i> for information about how to use this service to create and manage your support cases, and how to call Trusted Advisor for results of checks on your resources.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/support/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Http: {
      "cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "support"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddAttachmentsToSet_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddAttachmentsToSet_402656296(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddAttachmentsToSet_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddAttachmentsToSet"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_AddAttachmentsToSet_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AddAttachmentsToSet_402656294; body: JsonNode): Recallable =
  ## addAttachmentsToSet
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var addAttachmentsToSet* = Call_AddAttachmentsToSet_402656294(
    name: "addAttachmentsToSet", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddAttachmentsToSet",
    validator: validate_AddAttachmentsToSet_402656295, base: "/",
    makeUrl: url_AddAttachmentsToSet_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCommunicationToCase_402656489 = ref object of OpenApiRestCall_402656044
proc url_AddCommunicationToCase_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCommunicationToCase_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddCommunicationToCase"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_AddCommunicationToCase_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AddCommunicationToCase_402656489; body: JsonNode): Recallable =
  ## addCommunicationToCase
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var addCommunicationToCase* = Call_AddCommunicationToCase_402656489(
    name: "addCommunicationToCase", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddCommunicationToCase",
    validator: validate_AddCommunicationToCase_402656490, base: "/",
    makeUrl: url_AddCommunicationToCase_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCase_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateCase_402656506(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCase_402656505(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AWSSupport_20130415.CreateCase"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_CreateCase_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateCase_402656504; body: JsonNode): Recallable =
  ## createCase
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createCase* = Call_CreateCase_402656504(name: "createCase",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.CreateCase",
    validator: validate_CreateCase_402656505, base: "/",
    makeUrl: url_CreateCase_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAttachment_402656519 = ref object of OpenApiRestCall_402656044
proc url_DescribeAttachment_402656521(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAttachment_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeAttachment"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_DescribeAttachment_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_DescribeAttachment_402656519; body: JsonNode): Recallable =
  ## describeAttachment
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ##   
                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var describeAttachment* = Call_DescribeAttachment_402656519(
    name: "describeAttachment", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeAttachment",
    validator: validate_DescribeAttachment_402656520, base: "/",
    makeUrl: url_DescribeAttachment_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCases_402656534 = ref object of OpenApiRestCall_402656044
proc url_DescribeCases_402656536(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCases_402656535(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656537 = query.getOrDefault("maxResults")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "maxResults", valid_402656537
  var valid_402656538 = query.getOrDefault("nextToken")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "nextToken", valid_402656538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656539 = header.getOrDefault("X-Amz-Target")
  valid_402656539 = validateParameter(valid_402656539, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCases"))
  if valid_402656539 != nil:
    section.add "X-Amz-Target", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
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

proc call*(call_402656548: Call_DescribeCases_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_DescribeCases_402656534; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeCases
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## maxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var query_402656550 = newJObject()
  var body_402656551 = newJObject()
  add(query_402656550, "maxResults", newJString(maxResults))
  add(query_402656550, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656551 = body
  result = call_402656549.call(nil, query_402656550, nil, nil, body_402656551)

var describeCases* = Call_DescribeCases_402656534(name: "describeCases",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCases",
    validator: validate_DescribeCases_402656535, base: "/",
    makeUrl: url_DescribeCases_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCommunications_402656552 = ref object of OpenApiRestCall_402656044
proc url_DescribeCommunications_402656554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCommunications_402656553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656555 = query.getOrDefault("maxResults")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "maxResults", valid_402656555
  var valid_402656556 = query.getOrDefault("nextToken")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "nextToken", valid_402656556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656557 = header.getOrDefault("X-Amz-Target")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCommunications"))
  if valid_402656557 != nil:
    section.add "X-Amz-Target", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
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

proc call*(call_402656566: Call_DescribeCommunications_402656552;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_DescribeCommunications_402656552;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeCommunications
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## maxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var query_402656568 = newJObject()
  var body_402656569 = newJObject()
  add(query_402656568, "maxResults", newJString(maxResults))
  add(query_402656568, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656569 = body
  result = call_402656567.call(nil, query_402656568, nil, nil, body_402656569)

var describeCommunications* = Call_DescribeCommunications_402656552(
    name: "describeCommunications", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCommunications",
    validator: validate_DescribeCommunications_402656553, base: "/",
    makeUrl: url_DescribeCommunications_402656554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_402656570 = ref object of OpenApiRestCall_402656044
proc url_DescribeServices_402656572(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServices_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Target")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeServices"))
  if valid_402656573 != nil:
    section.add "X-Amz-Target", valid_402656573
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

proc call*(call_402656582: Call_DescribeServices_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
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

proc call*(call_402656583: Call_DescribeServices_402656570; body: JsonNode): Recallable =
  ## describeServices
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656584 = newJObject()
  if body != nil:
    body_402656584 = body
  result = call_402656583.call(nil, nil, nil, nil, body_402656584)

var describeServices* = Call_DescribeServices_402656570(
    name: "describeServices", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeServices",
    validator: validate_DescribeServices_402656571, base: "/",
    makeUrl: url_DescribeServices_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSeverityLevels_402656585 = ref object of OpenApiRestCall_402656044
proc url_DescribeSeverityLevels_402656587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSeverityLevels_402656586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656588 = header.getOrDefault("X-Amz-Target")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeSeverityLevels"))
  if valid_402656588 != nil:
    section.add "X-Amz-Target", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Security-Token", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Signature")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Signature", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Algorithm", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Date")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Date", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Credential")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Credential", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656595
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

proc call*(call_402656597: Call_DescribeSeverityLevels_402656585;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
                                                                                         ## 
  let valid = call_402656597.validator(path, query, header, formData, body, _)
  let scheme = call_402656597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656597.makeUrl(scheme.get, call_402656597.host, call_402656597.base,
                                   call_402656597.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656597, uri, valid, _)

proc call*(call_402656598: Call_DescribeSeverityLevels_402656585; body: JsonNode): Recallable =
  ## describeSeverityLevels
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ##   
                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656599 = newJObject()
  if body != nil:
    body_402656599 = body
  result = call_402656598.call(nil, nil, nil, nil, body_402656599)

var describeSeverityLevels* = Call_DescribeSeverityLevels_402656585(
    name: "describeSeverityLevels", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeSeverityLevels",
    validator: validate_DescribeSeverityLevels_402656586, base: "/",
    makeUrl: url_DescribeSeverityLevels_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckRefreshStatuses_402656600 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrustedAdvisorCheckRefreshStatuses_402656602(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckRefreshStatuses_402656601(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656603 = header.getOrDefault("X-Amz-Target")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses"))
  if valid_402656603 != nil:
    section.add "X-Amz-Target", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_DescribeTrustedAdvisorCheckRefreshStatuses_402656600;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_DescribeTrustedAdvisorCheckRefreshStatuses_402656600;
           body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckRefreshStatuses
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  result = call_402656613.call(nil, nil, nil, nil, body_402656614)

var describeTrustedAdvisorCheckRefreshStatuses* = Call_DescribeTrustedAdvisorCheckRefreshStatuses_402656600(
    name: "describeTrustedAdvisorCheckRefreshStatuses",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses",
    validator: validate_DescribeTrustedAdvisorCheckRefreshStatuses_402656601,
    base: "/", makeUrl: url_DescribeTrustedAdvisorCheckRefreshStatuses_402656602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckResult_402656615 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrustedAdvisorCheckResult_402656617(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckResult_402656616(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656618 = header.getOrDefault("X-Amz-Target")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckResult"))
  if valid_402656618 != nil:
    section.add "X-Amz-Target", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Security-Token", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Signature")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Signature", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Algorithm", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Date")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Date", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Credential")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Credential", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656625
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

proc call*(call_402656627: Call_DescribeTrustedAdvisorCheckResult_402656615;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656627.validator(path, query, header, formData, body, _)
  let scheme = call_402656627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656627.makeUrl(scheme.get, call_402656627.host, call_402656627.base,
                                   call_402656627.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656627, uri, valid, _)

proc call*(call_402656628: Call_DescribeTrustedAdvisorCheckResult_402656615;
           body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckResult
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656629 = newJObject()
  if body != nil:
    body_402656629 = body
  result = call_402656628.call(nil, nil, nil, nil, body_402656629)

var describeTrustedAdvisorCheckResult* = Call_DescribeTrustedAdvisorCheckResult_402656615(
    name: "describeTrustedAdvisorCheckResult", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckResult",
    validator: validate_DescribeTrustedAdvisorCheckResult_402656616, base: "/",
    makeUrl: url_DescribeTrustedAdvisorCheckResult_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckSummaries_402656630 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrustedAdvisorCheckSummaries_402656632(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckSummaries_402656631(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656633 = header.getOrDefault("X-Amz-Target")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries"))
  if valid_402656633 != nil:
    section.add "X-Amz-Target", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Security-Token", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Signature")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Signature", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Algorithm", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Date")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Date", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Credential")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Credential", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656640
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

proc call*(call_402656642: Call_DescribeTrustedAdvisorCheckSummaries_402656630;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_DescribeTrustedAdvisorCheckSummaries_402656630;
           body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckSummaries
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ##   
                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656644 = newJObject()
  if body != nil:
    body_402656644 = body
  result = call_402656643.call(nil, nil, nil, nil, body_402656644)

var describeTrustedAdvisorCheckSummaries* = Call_DescribeTrustedAdvisorCheckSummaries_402656630(
    name: "describeTrustedAdvisorCheckSummaries", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries",
    validator: validate_DescribeTrustedAdvisorCheckSummaries_402656631,
    base: "/", makeUrl: url_DescribeTrustedAdvisorCheckSummaries_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorChecks_402656645 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrustedAdvisorChecks_402656647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorChecks_402656646(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656648 = header.getOrDefault("X-Amz-Target")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorChecks"))
  if valid_402656648 != nil:
    section.add "X-Amz-Target", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Security-Token", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Signature")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Signature", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Algorithm", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Date")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Date", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Credential")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Credential", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656655
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

proc call*(call_402656657: Call_DescribeTrustedAdvisorChecks_402656645;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
                                                                                         ## 
  let valid = call_402656657.validator(path, query, header, formData, body, _)
  let scheme = call_402656657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656657.makeUrl(scheme.get, call_402656657.host, call_402656657.base,
                                   call_402656657.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656657, uri, valid, _)

proc call*(call_402656658: Call_DescribeTrustedAdvisorChecks_402656645;
           body: JsonNode): Recallable =
  ## describeTrustedAdvisorChecks
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ##   
                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656659 = newJObject()
  if body != nil:
    body_402656659 = body
  result = call_402656658.call(nil, nil, nil, nil, body_402656659)

var describeTrustedAdvisorChecks* = Call_DescribeTrustedAdvisorChecks_402656645(
    name: "describeTrustedAdvisorChecks", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorChecks",
    validator: validate_DescribeTrustedAdvisorChecks_402656646, base: "/",
    makeUrl: url_DescribeTrustedAdvisorChecks_402656647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshTrustedAdvisorCheck_402656660 = ref object of OpenApiRestCall_402656044
proc url_RefreshTrustedAdvisorCheck_402656662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RefreshTrustedAdvisorCheck_402656661(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656663 = header.getOrDefault("X-Amz-Target")
  valid_402656663 = validateParameter(valid_402656663, JString, required = true, default = newJString(
      "AWSSupport_20130415.RefreshTrustedAdvisorCheck"))
  if valid_402656663 != nil:
    section.add "X-Amz-Target", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Security-Token", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Signature")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Signature", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Algorithm", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Date")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Date", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Credential")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Credential", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656670
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

proc call*(call_402656672: Call_RefreshTrustedAdvisorCheck_402656660;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656672.validator(path, query, header, formData, body, _)
  let scheme = call_402656672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656672.makeUrl(scheme.get, call_402656672.host, call_402656672.base,
                                   call_402656672.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656672, uri, valid, _)

proc call*(call_402656673: Call_RefreshTrustedAdvisorCheck_402656660;
           body: JsonNode): Recallable =
  ## refreshTrustedAdvisorCheck
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656674 = newJObject()
  if body != nil:
    body_402656674 = body
  result = call_402656673.call(nil, nil, nil, nil, body_402656674)

var refreshTrustedAdvisorCheck* = Call_RefreshTrustedAdvisorCheck_402656660(
    name: "refreshTrustedAdvisorCheck", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.RefreshTrustedAdvisorCheck",
    validator: validate_RefreshTrustedAdvisorCheck_402656661, base: "/",
    makeUrl: url_RefreshTrustedAdvisorCheck_402656662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCase_402656675 = ref object of OpenApiRestCall_402656044
proc url_ResolveCase_402656677(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResolveCase_402656676(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656678 = header.getOrDefault("X-Amz-Target")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true, default = newJString(
      "AWSSupport_20130415.ResolveCase"))
  if valid_402656678 != nil:
    section.add "X-Amz-Target", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Security-Token", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Signature")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Signature", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Algorithm", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Date")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Date", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Credential")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Credential", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656685
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

proc call*(call_402656687: Call_ResolveCase_402656675; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
                                                                                         ## 
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_ResolveCase_402656675; body: JsonNode): Recallable =
  ## resolveCase
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ##   
                                                                                                                                                           ## body: JObject (required)
  var body_402656689 = newJObject()
  if body != nil:
    body_402656689 = body
  result = call_402656688.call(nil, nil, nil, nil, body_402656689)

var resolveCase* = Call_ResolveCase_402656675(name: "resolveCase",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.ResolveCase",
    validator: validate_ResolveCase_402656676, base: "/",
    makeUrl: url_ResolveCase_402656677, schemes: {Scheme.Https, Scheme.Http})
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