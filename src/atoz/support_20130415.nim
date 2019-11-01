
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "support"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddAttachmentsToSet_591703 = ref object of OpenApiRestCall_591364
proc url_AddAttachmentsToSet_591705(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddAttachmentsToSet_591704(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_591830 = header.getOrDefault("X-Amz-Target")
  valid_591830 = validateParameter(valid_591830, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddAttachmentsToSet"))
  if valid_591830 != nil:
    section.add "X-Amz-Target", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-Signature")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-Signature", valid_591831
  var valid_591832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591832 = validateParameter(valid_591832, JString, required = false,
                                 default = nil)
  if valid_591832 != nil:
    section.add "X-Amz-Content-Sha256", valid_591832
  var valid_591833 = header.getOrDefault("X-Amz-Date")
  valid_591833 = validateParameter(valid_591833, JString, required = false,
                                 default = nil)
  if valid_591833 != nil:
    section.add "X-Amz-Date", valid_591833
  var valid_591834 = header.getOrDefault("X-Amz-Credential")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "X-Amz-Credential", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Security-Token")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Security-Token", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Algorithm")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Algorithm", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-SignedHeaders", valid_591837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_AddAttachmentsToSet_591703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591932: Call_AddAttachmentsToSet_591703; body: JsonNode): Recallable =
  ## addAttachmentsToSet
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ##   body: JObject (required)
  var body_591933 = newJObject()
  if body != nil:
    body_591933 = body
  result = call_591932.call(nil, nil, nil, nil, body_591933)

var addAttachmentsToSet* = Call_AddAttachmentsToSet_591703(
    name: "addAttachmentsToSet", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddAttachmentsToSet",
    validator: validate_AddAttachmentsToSet_591704, base: "/",
    url: url_AddAttachmentsToSet_591705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCommunicationToCase_591972 = ref object of OpenApiRestCall_591364
proc url_AddCommunicationToCase_591974(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddCommunicationToCase_591973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_591975 = header.getOrDefault("X-Amz-Target")
  valid_591975 = validateParameter(valid_591975, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddCommunicationToCase"))
  if valid_591975 != nil:
    section.add "X-Amz-Target", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591984: Call_AddCommunicationToCase_591972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ## 
  let valid = call_591984.validator(path, query, header, formData, body)
  let scheme = call_591984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591984.url(scheme.get, call_591984.host, call_591984.base,
                         call_591984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591984, url, valid)

proc call*(call_591985: Call_AddCommunicationToCase_591972; body: JsonNode): Recallable =
  ## addCommunicationToCase
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ##   body: JObject (required)
  var body_591986 = newJObject()
  if body != nil:
    body_591986 = body
  result = call_591985.call(nil, nil, nil, nil, body_591986)

var addCommunicationToCase* = Call_AddCommunicationToCase_591972(
    name: "addCommunicationToCase", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddCommunicationToCase",
    validator: validate_AddCommunicationToCase_591973, base: "/",
    url: url_AddCommunicationToCase_591974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCase_591987 = ref object of OpenApiRestCall_591364
proc url_CreateCase_591989(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCase_591988(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_591990 = header.getOrDefault("X-Amz-Target")
  valid_591990 = validateParameter(valid_591990, JString, required = true, default = newJString(
      "AWSSupport_20130415.CreateCase"))
  if valid_591990 != nil:
    section.add "X-Amz-Target", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591999: Call_CreateCase_591987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ## 
  let valid = call_591999.validator(path, query, header, formData, body)
  let scheme = call_591999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591999.url(scheme.get, call_591999.host, call_591999.base,
                         call_591999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591999, url, valid)

proc call*(call_592000: Call_CreateCase_591987; body: JsonNode): Recallable =
  ## createCase
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ##   body: JObject (required)
  var body_592001 = newJObject()
  if body != nil:
    body_592001 = body
  result = call_592000.call(nil, nil, nil, nil, body_592001)

var createCase* = Call_CreateCase_591987(name: "createCase",
                                      meth: HttpMethod.HttpPost,
                                      host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.CreateCase",
                                      validator: validate_CreateCase_591988,
                                      base: "/", url: url_CreateCase_591989,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAttachment_592002 = ref object of OpenApiRestCall_591364
proc url_DescribeAttachment_592004(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAttachment_592003(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_592005 = header.getOrDefault("X-Amz-Target")
  valid_592005 = validateParameter(valid_592005, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeAttachment"))
  if valid_592005 != nil:
    section.add "X-Amz-Target", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Signature")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Signature", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Content-Sha256", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Date")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Date", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Credential")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Credential", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Security-Token")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Security-Token", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Algorithm")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Algorithm", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-SignedHeaders", valid_592012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592014: Call_DescribeAttachment_592002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ## 
  let valid = call_592014.validator(path, query, header, formData, body)
  let scheme = call_592014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592014.url(scheme.get, call_592014.host, call_592014.base,
                         call_592014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592014, url, valid)

proc call*(call_592015: Call_DescribeAttachment_592002; body: JsonNode): Recallable =
  ## describeAttachment
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ##   body: JObject (required)
  var body_592016 = newJObject()
  if body != nil:
    body_592016 = body
  result = call_592015.call(nil, nil, nil, nil, body_592016)

var describeAttachment* = Call_DescribeAttachment_592002(
    name: "describeAttachment", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeAttachment",
    validator: validate_DescribeAttachment_592003, base: "/",
    url: url_DescribeAttachment_592004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCases_592017 = ref object of OpenApiRestCall_591364
proc url_DescribeCases_592019(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCases_592018(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
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
  var valid_592020 = query.getOrDefault("nextToken")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = nil)
  if valid_592020 != nil:
    section.add "nextToken", valid_592020
  var valid_592021 = query.getOrDefault("maxResults")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "maxResults", valid_592021
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
  var valid_592022 = header.getOrDefault("X-Amz-Target")
  valid_592022 = validateParameter(valid_592022, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCases"))
  if valid_592022 != nil:
    section.add "X-Amz-Target", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-Signature")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-Signature", valid_592023
  var valid_592024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Content-Sha256", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Date")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Date", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Credential")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Credential", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-Security-Token")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-Security-Token", valid_592027
  var valid_592028 = header.getOrDefault("X-Amz-Algorithm")
  valid_592028 = validateParameter(valid_592028, JString, required = false,
                                 default = nil)
  if valid_592028 != nil:
    section.add "X-Amz-Algorithm", valid_592028
  var valid_592029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "X-Amz-SignedHeaders", valid_592029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592031: Call_DescribeCases_592017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ## 
  let valid = call_592031.validator(path, query, header, formData, body)
  let scheme = call_592031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592031.url(scheme.get, call_592031.host, call_592031.base,
                         call_592031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592031, url, valid)

proc call*(call_592032: Call_DescribeCases_592017; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeCases
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592033 = newJObject()
  var body_592034 = newJObject()
  add(query_592033, "nextToken", newJString(nextToken))
  if body != nil:
    body_592034 = body
  add(query_592033, "maxResults", newJString(maxResults))
  result = call_592032.call(nil, query_592033, nil, nil, body_592034)

var describeCases* = Call_DescribeCases_592017(name: "describeCases",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCases",
    validator: validate_DescribeCases_592018, base: "/", url: url_DescribeCases_592019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCommunications_592036 = ref object of OpenApiRestCall_591364
proc url_DescribeCommunications_592038(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCommunications_592037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
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
  var valid_592039 = query.getOrDefault("nextToken")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "nextToken", valid_592039
  var valid_592040 = query.getOrDefault("maxResults")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "maxResults", valid_592040
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
  var valid_592041 = header.getOrDefault("X-Amz-Target")
  valid_592041 = validateParameter(valid_592041, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCommunications"))
  if valid_592041 != nil:
    section.add "X-Amz-Target", valid_592041
  var valid_592042 = header.getOrDefault("X-Amz-Signature")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "X-Amz-Signature", valid_592042
  var valid_592043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592043 = validateParameter(valid_592043, JString, required = false,
                                 default = nil)
  if valid_592043 != nil:
    section.add "X-Amz-Content-Sha256", valid_592043
  var valid_592044 = header.getOrDefault("X-Amz-Date")
  valid_592044 = validateParameter(valid_592044, JString, required = false,
                                 default = nil)
  if valid_592044 != nil:
    section.add "X-Amz-Date", valid_592044
  var valid_592045 = header.getOrDefault("X-Amz-Credential")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Credential", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-Security-Token")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-Security-Token", valid_592046
  var valid_592047 = header.getOrDefault("X-Amz-Algorithm")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "X-Amz-Algorithm", valid_592047
  var valid_592048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-SignedHeaders", valid_592048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592050: Call_DescribeCommunications_592036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ## 
  let valid = call_592050.validator(path, query, header, formData, body)
  let scheme = call_592050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592050.url(scheme.get, call_592050.host, call_592050.base,
                         call_592050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592050, url, valid)

proc call*(call_592051: Call_DescribeCommunications_592036; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeCommunications
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592052 = newJObject()
  var body_592053 = newJObject()
  add(query_592052, "nextToken", newJString(nextToken))
  if body != nil:
    body_592053 = body
  add(query_592052, "maxResults", newJString(maxResults))
  result = call_592051.call(nil, query_592052, nil, nil, body_592053)

var describeCommunications* = Call_DescribeCommunications_592036(
    name: "describeCommunications", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCommunications",
    validator: validate_DescribeCommunications_592037, base: "/",
    url: url_DescribeCommunications_592038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_592054 = ref object of OpenApiRestCall_591364
proc url_DescribeServices_592056(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServices_592055(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_592057 = header.getOrDefault("X-Amz-Target")
  valid_592057 = validateParameter(valid_592057, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeServices"))
  if valid_592057 != nil:
    section.add "X-Amz-Target", valid_592057
  var valid_592058 = header.getOrDefault("X-Amz-Signature")
  valid_592058 = validateParameter(valid_592058, JString, required = false,
                                 default = nil)
  if valid_592058 != nil:
    section.add "X-Amz-Signature", valid_592058
  var valid_592059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592059 = validateParameter(valid_592059, JString, required = false,
                                 default = nil)
  if valid_592059 != nil:
    section.add "X-Amz-Content-Sha256", valid_592059
  var valid_592060 = header.getOrDefault("X-Amz-Date")
  valid_592060 = validateParameter(valid_592060, JString, required = false,
                                 default = nil)
  if valid_592060 != nil:
    section.add "X-Amz-Date", valid_592060
  var valid_592061 = header.getOrDefault("X-Amz-Credential")
  valid_592061 = validateParameter(valid_592061, JString, required = false,
                                 default = nil)
  if valid_592061 != nil:
    section.add "X-Amz-Credential", valid_592061
  var valid_592062 = header.getOrDefault("X-Amz-Security-Token")
  valid_592062 = validateParameter(valid_592062, JString, required = false,
                                 default = nil)
  if valid_592062 != nil:
    section.add "X-Amz-Security-Token", valid_592062
  var valid_592063 = header.getOrDefault("X-Amz-Algorithm")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "X-Amz-Algorithm", valid_592063
  var valid_592064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-SignedHeaders", valid_592064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592066: Call_DescribeServices_592054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ## 
  let valid = call_592066.validator(path, query, header, formData, body)
  let scheme = call_592066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592066.url(scheme.get, call_592066.host, call_592066.base,
                         call_592066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592066, url, valid)

proc call*(call_592067: Call_DescribeServices_592054; body: JsonNode): Recallable =
  ## describeServices
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ##   body: JObject (required)
  var body_592068 = newJObject()
  if body != nil:
    body_592068 = body
  result = call_592067.call(nil, nil, nil, nil, body_592068)

var describeServices* = Call_DescribeServices_592054(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeServices",
    validator: validate_DescribeServices_592055, base: "/",
    url: url_DescribeServices_592056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSeverityLevels_592069 = ref object of OpenApiRestCall_591364
proc url_DescribeSeverityLevels_592071(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSeverityLevels_592070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592072 = header.getOrDefault("X-Amz-Target")
  valid_592072 = validateParameter(valid_592072, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeSeverityLevels"))
  if valid_592072 != nil:
    section.add "X-Amz-Target", valid_592072
  var valid_592073 = header.getOrDefault("X-Amz-Signature")
  valid_592073 = validateParameter(valid_592073, JString, required = false,
                                 default = nil)
  if valid_592073 != nil:
    section.add "X-Amz-Signature", valid_592073
  var valid_592074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592074 = validateParameter(valid_592074, JString, required = false,
                                 default = nil)
  if valid_592074 != nil:
    section.add "X-Amz-Content-Sha256", valid_592074
  var valid_592075 = header.getOrDefault("X-Amz-Date")
  valid_592075 = validateParameter(valid_592075, JString, required = false,
                                 default = nil)
  if valid_592075 != nil:
    section.add "X-Amz-Date", valid_592075
  var valid_592076 = header.getOrDefault("X-Amz-Credential")
  valid_592076 = validateParameter(valid_592076, JString, required = false,
                                 default = nil)
  if valid_592076 != nil:
    section.add "X-Amz-Credential", valid_592076
  var valid_592077 = header.getOrDefault("X-Amz-Security-Token")
  valid_592077 = validateParameter(valid_592077, JString, required = false,
                                 default = nil)
  if valid_592077 != nil:
    section.add "X-Amz-Security-Token", valid_592077
  var valid_592078 = header.getOrDefault("X-Amz-Algorithm")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "X-Amz-Algorithm", valid_592078
  var valid_592079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592079 = validateParameter(valid_592079, JString, required = false,
                                 default = nil)
  if valid_592079 != nil:
    section.add "X-Amz-SignedHeaders", valid_592079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592081: Call_DescribeSeverityLevels_592069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ## 
  let valid = call_592081.validator(path, query, header, formData, body)
  let scheme = call_592081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592081.url(scheme.get, call_592081.host, call_592081.base,
                         call_592081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592081, url, valid)

proc call*(call_592082: Call_DescribeSeverityLevels_592069; body: JsonNode): Recallable =
  ## describeSeverityLevels
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ##   body: JObject (required)
  var body_592083 = newJObject()
  if body != nil:
    body_592083 = body
  result = call_592082.call(nil, nil, nil, nil, body_592083)

var describeSeverityLevels* = Call_DescribeSeverityLevels_592069(
    name: "describeSeverityLevels", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeSeverityLevels",
    validator: validate_DescribeSeverityLevels_592070, base: "/",
    url: url_DescribeSeverityLevels_592071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckRefreshStatuses_592084 = ref object of OpenApiRestCall_591364
proc url_DescribeTrustedAdvisorCheckRefreshStatuses_592086(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrustedAdvisorCheckRefreshStatuses_592085(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592087 = header.getOrDefault("X-Amz-Target")
  valid_592087 = validateParameter(valid_592087, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses"))
  if valid_592087 != nil:
    section.add "X-Amz-Target", valid_592087
  var valid_592088 = header.getOrDefault("X-Amz-Signature")
  valid_592088 = validateParameter(valid_592088, JString, required = false,
                                 default = nil)
  if valid_592088 != nil:
    section.add "X-Amz-Signature", valid_592088
  var valid_592089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592089 = validateParameter(valid_592089, JString, required = false,
                                 default = nil)
  if valid_592089 != nil:
    section.add "X-Amz-Content-Sha256", valid_592089
  var valid_592090 = header.getOrDefault("X-Amz-Date")
  valid_592090 = validateParameter(valid_592090, JString, required = false,
                                 default = nil)
  if valid_592090 != nil:
    section.add "X-Amz-Date", valid_592090
  var valid_592091 = header.getOrDefault("X-Amz-Credential")
  valid_592091 = validateParameter(valid_592091, JString, required = false,
                                 default = nil)
  if valid_592091 != nil:
    section.add "X-Amz-Credential", valid_592091
  var valid_592092 = header.getOrDefault("X-Amz-Security-Token")
  valid_592092 = validateParameter(valid_592092, JString, required = false,
                                 default = nil)
  if valid_592092 != nil:
    section.add "X-Amz-Security-Token", valid_592092
  var valid_592093 = header.getOrDefault("X-Amz-Algorithm")
  valid_592093 = validateParameter(valid_592093, JString, required = false,
                                 default = nil)
  if valid_592093 != nil:
    section.add "X-Amz-Algorithm", valid_592093
  var valid_592094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-SignedHeaders", valid_592094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592096: Call_DescribeTrustedAdvisorCheckRefreshStatuses_592084;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ## 
  let valid = call_592096.validator(path, query, header, formData, body)
  let scheme = call_592096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592096.url(scheme.get, call_592096.host, call_592096.base,
                         call_592096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592096, url, valid)

proc call*(call_592097: Call_DescribeTrustedAdvisorCheckRefreshStatuses_592084;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckRefreshStatuses
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ##   body: JObject (required)
  var body_592098 = newJObject()
  if body != nil:
    body_592098 = body
  result = call_592097.call(nil, nil, nil, nil, body_592098)

var describeTrustedAdvisorCheckRefreshStatuses* = Call_DescribeTrustedAdvisorCheckRefreshStatuses_592084(
    name: "describeTrustedAdvisorCheckRefreshStatuses", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses",
    validator: validate_DescribeTrustedAdvisorCheckRefreshStatuses_592085,
    base: "/", url: url_DescribeTrustedAdvisorCheckRefreshStatuses_592086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckResult_592099 = ref object of OpenApiRestCall_591364
proc url_DescribeTrustedAdvisorCheckResult_592101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrustedAdvisorCheckResult_592100(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592102 = header.getOrDefault("X-Amz-Target")
  valid_592102 = validateParameter(valid_592102, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckResult"))
  if valid_592102 != nil:
    section.add "X-Amz-Target", valid_592102
  var valid_592103 = header.getOrDefault("X-Amz-Signature")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-Signature", valid_592103
  var valid_592104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592104 = validateParameter(valid_592104, JString, required = false,
                                 default = nil)
  if valid_592104 != nil:
    section.add "X-Amz-Content-Sha256", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Date")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Date", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Credential")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Credential", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Security-Token")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Security-Token", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-Algorithm")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-Algorithm", valid_592108
  var valid_592109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-SignedHeaders", valid_592109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592111: Call_DescribeTrustedAdvisorCheckResult_592099;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_592111.validator(path, query, header, formData, body)
  let scheme = call_592111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592111.url(scheme.get, call_592111.host, call_592111.base,
                         call_592111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592111, url, valid)

proc call*(call_592112: Call_DescribeTrustedAdvisorCheckResult_592099;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckResult
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_592113 = newJObject()
  if body != nil:
    body_592113 = body
  result = call_592112.call(nil, nil, nil, nil, body_592113)

var describeTrustedAdvisorCheckResult* = Call_DescribeTrustedAdvisorCheckResult_592099(
    name: "describeTrustedAdvisorCheckResult", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckResult",
    validator: validate_DescribeTrustedAdvisorCheckResult_592100, base: "/",
    url: url_DescribeTrustedAdvisorCheckResult_592101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckSummaries_592114 = ref object of OpenApiRestCall_591364
proc url_DescribeTrustedAdvisorCheckSummaries_592116(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrustedAdvisorCheckSummaries_592115(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592117 = header.getOrDefault("X-Amz-Target")
  valid_592117 = validateParameter(valid_592117, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries"))
  if valid_592117 != nil:
    section.add "X-Amz-Target", valid_592117
  var valid_592118 = header.getOrDefault("X-Amz-Signature")
  valid_592118 = validateParameter(valid_592118, JString, required = false,
                                 default = nil)
  if valid_592118 != nil:
    section.add "X-Amz-Signature", valid_592118
  var valid_592119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592119 = validateParameter(valid_592119, JString, required = false,
                                 default = nil)
  if valid_592119 != nil:
    section.add "X-Amz-Content-Sha256", valid_592119
  var valid_592120 = header.getOrDefault("X-Amz-Date")
  valid_592120 = validateParameter(valid_592120, JString, required = false,
                                 default = nil)
  if valid_592120 != nil:
    section.add "X-Amz-Date", valid_592120
  var valid_592121 = header.getOrDefault("X-Amz-Credential")
  valid_592121 = validateParameter(valid_592121, JString, required = false,
                                 default = nil)
  if valid_592121 != nil:
    section.add "X-Amz-Credential", valid_592121
  var valid_592122 = header.getOrDefault("X-Amz-Security-Token")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "X-Amz-Security-Token", valid_592122
  var valid_592123 = header.getOrDefault("X-Amz-Algorithm")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "X-Amz-Algorithm", valid_592123
  var valid_592124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-SignedHeaders", valid_592124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592126: Call_DescribeTrustedAdvisorCheckSummaries_592114;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ## 
  let valid = call_592126.validator(path, query, header, formData, body)
  let scheme = call_592126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592126.url(scheme.get, call_592126.host, call_592126.base,
                         call_592126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592126, url, valid)

proc call*(call_592127: Call_DescribeTrustedAdvisorCheckSummaries_592114;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckSummaries
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ##   body: JObject (required)
  var body_592128 = newJObject()
  if body != nil:
    body_592128 = body
  result = call_592127.call(nil, nil, nil, nil, body_592128)

var describeTrustedAdvisorCheckSummaries* = Call_DescribeTrustedAdvisorCheckSummaries_592114(
    name: "describeTrustedAdvisorCheckSummaries", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries",
    validator: validate_DescribeTrustedAdvisorCheckSummaries_592115, base: "/",
    url: url_DescribeTrustedAdvisorCheckSummaries_592116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorChecks_592129 = ref object of OpenApiRestCall_591364
proc url_DescribeTrustedAdvisorChecks_592131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrustedAdvisorChecks_592130(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592132 = header.getOrDefault("X-Amz-Target")
  valid_592132 = validateParameter(valid_592132, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorChecks"))
  if valid_592132 != nil:
    section.add "X-Amz-Target", valid_592132
  var valid_592133 = header.getOrDefault("X-Amz-Signature")
  valid_592133 = validateParameter(valid_592133, JString, required = false,
                                 default = nil)
  if valid_592133 != nil:
    section.add "X-Amz-Signature", valid_592133
  var valid_592134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592134 = validateParameter(valid_592134, JString, required = false,
                                 default = nil)
  if valid_592134 != nil:
    section.add "X-Amz-Content-Sha256", valid_592134
  var valid_592135 = header.getOrDefault("X-Amz-Date")
  valid_592135 = validateParameter(valid_592135, JString, required = false,
                                 default = nil)
  if valid_592135 != nil:
    section.add "X-Amz-Date", valid_592135
  var valid_592136 = header.getOrDefault("X-Amz-Credential")
  valid_592136 = validateParameter(valid_592136, JString, required = false,
                                 default = nil)
  if valid_592136 != nil:
    section.add "X-Amz-Credential", valid_592136
  var valid_592137 = header.getOrDefault("X-Amz-Security-Token")
  valid_592137 = validateParameter(valid_592137, JString, required = false,
                                 default = nil)
  if valid_592137 != nil:
    section.add "X-Amz-Security-Token", valid_592137
  var valid_592138 = header.getOrDefault("X-Amz-Algorithm")
  valid_592138 = validateParameter(valid_592138, JString, required = false,
                                 default = nil)
  if valid_592138 != nil:
    section.add "X-Amz-Algorithm", valid_592138
  var valid_592139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "X-Amz-SignedHeaders", valid_592139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592141: Call_DescribeTrustedAdvisorChecks_592129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ## 
  let valid = call_592141.validator(path, query, header, formData, body)
  let scheme = call_592141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592141.url(scheme.get, call_592141.host, call_592141.base,
                         call_592141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592141, url, valid)

proc call*(call_592142: Call_DescribeTrustedAdvisorChecks_592129; body: JsonNode): Recallable =
  ## describeTrustedAdvisorChecks
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ##   body: JObject (required)
  var body_592143 = newJObject()
  if body != nil:
    body_592143 = body
  result = call_592142.call(nil, nil, nil, nil, body_592143)

var describeTrustedAdvisorChecks* = Call_DescribeTrustedAdvisorChecks_592129(
    name: "describeTrustedAdvisorChecks", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorChecks",
    validator: validate_DescribeTrustedAdvisorChecks_592130, base: "/",
    url: url_DescribeTrustedAdvisorChecks_592131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshTrustedAdvisorCheck_592144 = ref object of OpenApiRestCall_591364
proc url_RefreshTrustedAdvisorCheck_592146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RefreshTrustedAdvisorCheck_592145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592147 = header.getOrDefault("X-Amz-Target")
  valid_592147 = validateParameter(valid_592147, JString, required = true, default = newJString(
      "AWSSupport_20130415.RefreshTrustedAdvisorCheck"))
  if valid_592147 != nil:
    section.add "X-Amz-Target", valid_592147
  var valid_592148 = header.getOrDefault("X-Amz-Signature")
  valid_592148 = validateParameter(valid_592148, JString, required = false,
                                 default = nil)
  if valid_592148 != nil:
    section.add "X-Amz-Signature", valid_592148
  var valid_592149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592149 = validateParameter(valid_592149, JString, required = false,
                                 default = nil)
  if valid_592149 != nil:
    section.add "X-Amz-Content-Sha256", valid_592149
  var valid_592150 = header.getOrDefault("X-Amz-Date")
  valid_592150 = validateParameter(valid_592150, JString, required = false,
                                 default = nil)
  if valid_592150 != nil:
    section.add "X-Amz-Date", valid_592150
  var valid_592151 = header.getOrDefault("X-Amz-Credential")
  valid_592151 = validateParameter(valid_592151, JString, required = false,
                                 default = nil)
  if valid_592151 != nil:
    section.add "X-Amz-Credential", valid_592151
  var valid_592152 = header.getOrDefault("X-Amz-Security-Token")
  valid_592152 = validateParameter(valid_592152, JString, required = false,
                                 default = nil)
  if valid_592152 != nil:
    section.add "X-Amz-Security-Token", valid_592152
  var valid_592153 = header.getOrDefault("X-Amz-Algorithm")
  valid_592153 = validateParameter(valid_592153, JString, required = false,
                                 default = nil)
  if valid_592153 != nil:
    section.add "X-Amz-Algorithm", valid_592153
  var valid_592154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592154 = validateParameter(valid_592154, JString, required = false,
                                 default = nil)
  if valid_592154 != nil:
    section.add "X-Amz-SignedHeaders", valid_592154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592156: Call_RefreshTrustedAdvisorCheck_592144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_592156.validator(path, query, header, formData, body)
  let scheme = call_592156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592156.url(scheme.get, call_592156.host, call_592156.base,
                         call_592156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592156, url, valid)

proc call*(call_592157: Call_RefreshTrustedAdvisorCheck_592144; body: JsonNode): Recallable =
  ## refreshTrustedAdvisorCheck
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_592158 = newJObject()
  if body != nil:
    body_592158 = body
  result = call_592157.call(nil, nil, nil, nil, body_592158)

var refreshTrustedAdvisorCheck* = Call_RefreshTrustedAdvisorCheck_592144(
    name: "refreshTrustedAdvisorCheck", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.RefreshTrustedAdvisorCheck",
    validator: validate_RefreshTrustedAdvisorCheck_592145, base: "/",
    url: url_RefreshTrustedAdvisorCheck_592146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCase_592159 = ref object of OpenApiRestCall_591364
proc url_ResolveCase_592161(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResolveCase_592160(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_592162 = header.getOrDefault("X-Amz-Target")
  valid_592162 = validateParameter(valid_592162, JString, required = true, default = newJString(
      "AWSSupport_20130415.ResolveCase"))
  if valid_592162 != nil:
    section.add "X-Amz-Target", valid_592162
  var valid_592163 = header.getOrDefault("X-Amz-Signature")
  valid_592163 = validateParameter(valid_592163, JString, required = false,
                                 default = nil)
  if valid_592163 != nil:
    section.add "X-Amz-Signature", valid_592163
  var valid_592164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592164 = validateParameter(valid_592164, JString, required = false,
                                 default = nil)
  if valid_592164 != nil:
    section.add "X-Amz-Content-Sha256", valid_592164
  var valid_592165 = header.getOrDefault("X-Amz-Date")
  valid_592165 = validateParameter(valid_592165, JString, required = false,
                                 default = nil)
  if valid_592165 != nil:
    section.add "X-Amz-Date", valid_592165
  var valid_592166 = header.getOrDefault("X-Amz-Credential")
  valid_592166 = validateParameter(valid_592166, JString, required = false,
                                 default = nil)
  if valid_592166 != nil:
    section.add "X-Amz-Credential", valid_592166
  var valid_592167 = header.getOrDefault("X-Amz-Security-Token")
  valid_592167 = validateParameter(valid_592167, JString, required = false,
                                 default = nil)
  if valid_592167 != nil:
    section.add "X-Amz-Security-Token", valid_592167
  var valid_592168 = header.getOrDefault("X-Amz-Algorithm")
  valid_592168 = validateParameter(valid_592168, JString, required = false,
                                 default = nil)
  if valid_592168 != nil:
    section.add "X-Amz-Algorithm", valid_592168
  var valid_592169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592169 = validateParameter(valid_592169, JString, required = false,
                                 default = nil)
  if valid_592169 != nil:
    section.add "X-Amz-SignedHeaders", valid_592169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592171: Call_ResolveCase_592159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ## 
  let valid = call_592171.validator(path, query, header, formData, body)
  let scheme = call_592171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592171.url(scheme.get, call_592171.host, call_592171.base,
                         call_592171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592171, url, valid)

proc call*(call_592172: Call_ResolveCase_592159; body: JsonNode): Recallable =
  ## resolveCase
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ##   body: JObject (required)
  var body_592173 = newJObject()
  if body != nil:
    body_592173 = body
  result = call_592172.call(nil, nil, nil, nil, body_592173)

var resolveCase* = Call_ResolveCase_592159(name: "resolveCase",
                                        meth: HttpMethod.HttpPost,
                                        host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.ResolveCase",
                                        validator: validate_ResolveCase_592160,
                                        base: "/", url: url_ResolveCase_592161,
                                        schemes: {Scheme.Https, Scheme.Http})
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
