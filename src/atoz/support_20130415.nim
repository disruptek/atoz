
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddAttachmentsToSet_601727 = ref object of OpenApiRestCall_601389
proc url_AddAttachmentsToSet_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AddAttachmentsToSet_601728(path: JsonNode; query: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddAttachmentsToSet"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AddAttachmentsToSet_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AddAttachmentsToSet_601727; body: JsonNode): Recallable =
  ## addAttachmentsToSet
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var addAttachmentsToSet* = Call_AddAttachmentsToSet_601727(
    name: "addAttachmentsToSet", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddAttachmentsToSet",
    validator: validate_AddAttachmentsToSet_601728, base: "/",
    url: url_AddAttachmentsToSet_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCommunicationToCase_601996 = ref object of OpenApiRestCall_601389
proc url_AddCommunicationToCase_601998(protocol: Scheme; host: string; base: string;
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

proc validate_AddCommunicationToCase_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddCommunicationToCase"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_AddCommunicationToCase_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_AddCommunicationToCase_601996; body: JsonNode): Recallable =
  ## addCommunicationToCase
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var addCommunicationToCase* = Call_AddCommunicationToCase_601996(
    name: "addCommunicationToCase", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddCommunicationToCase",
    validator: validate_AddCommunicationToCase_601997, base: "/",
    url: url_AddCommunicationToCase_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCase_602011 = ref object of OpenApiRestCall_601389
proc url_CreateCase_602013(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateCase_602012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AWSSupport_20130415.CreateCase"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateCase_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateCase_602011; body: JsonNode): Recallable =
  ## createCase
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createCase* = Call_CreateCase_602011(name: "createCase",
                                      meth: HttpMethod.HttpPost,
                                      host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.CreateCase",
                                      validator: validate_CreateCase_602012,
                                      base: "/", url: url_CreateCase_602013,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAttachment_602026 = ref object of OpenApiRestCall_601389
proc url_DescribeAttachment_602028(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAttachment_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeAttachment"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_DescribeAttachment_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_DescribeAttachment_602026; body: JsonNode): Recallable =
  ## describeAttachment
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var describeAttachment* = Call_DescribeAttachment_602026(
    name: "describeAttachment", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeAttachment",
    validator: validate_DescribeAttachment_602027, base: "/",
    url: url_DescribeAttachment_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCases_602041 = ref object of OpenApiRestCall_601389
proc url_DescribeCases_602043(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCases_602042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602044 = query.getOrDefault("nextToken")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "nextToken", valid_602044
  var valid_602045 = query.getOrDefault("maxResults")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "maxResults", valid_602045
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
  var valid_602046 = header.getOrDefault("X-Amz-Target")
  valid_602046 = validateParameter(valid_602046, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCases"))
  if valid_602046 != nil:
    section.add "X-Amz-Target", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Content-Sha256", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Date")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Date", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-SignedHeaders", valid_602053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_DescribeCases_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ## 
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602055, url, valid)

proc call*(call_602056: Call_DescribeCases_602041; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeCases
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602057 = newJObject()
  var body_602058 = newJObject()
  add(query_602057, "nextToken", newJString(nextToken))
  if body != nil:
    body_602058 = body
  add(query_602057, "maxResults", newJString(maxResults))
  result = call_602056.call(nil, query_602057, nil, nil, body_602058)

var describeCases* = Call_DescribeCases_602041(name: "describeCases",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCases",
    validator: validate_DescribeCases_602042, base: "/", url: url_DescribeCases_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCommunications_602060 = ref object of OpenApiRestCall_601389
proc url_DescribeCommunications_602062(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCommunications_602061(path: JsonNode; query: JsonNode;
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
  var valid_602063 = query.getOrDefault("nextToken")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "nextToken", valid_602063
  var valid_602064 = query.getOrDefault("maxResults")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "maxResults", valid_602064
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
  var valid_602065 = header.getOrDefault("X-Amz-Target")
  valid_602065 = validateParameter(valid_602065, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCommunications"))
  if valid_602065 != nil:
    section.add "X-Amz-Target", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602074: Call_DescribeCommunications_602060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ## 
  let valid = call_602074.validator(path, query, header, formData, body)
  let scheme = call_602074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602074.url(scheme.get, call_602074.host, call_602074.base,
                         call_602074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602074, url, valid)

proc call*(call_602075: Call_DescribeCommunications_602060; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeCommunications
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602076 = newJObject()
  var body_602077 = newJObject()
  add(query_602076, "nextToken", newJString(nextToken))
  if body != nil:
    body_602077 = body
  add(query_602076, "maxResults", newJString(maxResults))
  result = call_602075.call(nil, query_602076, nil, nil, body_602077)

var describeCommunications* = Call_DescribeCommunications_602060(
    name: "describeCommunications", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCommunications",
    validator: validate_DescribeCommunications_602061, base: "/",
    url: url_DescribeCommunications_602062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_602078 = ref object of OpenApiRestCall_601389
proc url_DescribeServices_602080(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServices_602079(path: JsonNode; query: JsonNode;
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
  var valid_602081 = header.getOrDefault("X-Amz-Target")
  valid_602081 = validateParameter(valid_602081, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeServices"))
  if valid_602081 != nil:
    section.add "X-Amz-Target", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Signature")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Signature", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Date")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Date", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Credential")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Credential", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Security-Token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Security-Token", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Algorithm")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Algorithm", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-SignedHeaders", valid_602088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602090: Call_DescribeServices_602078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ## 
  let valid = call_602090.validator(path, query, header, formData, body)
  let scheme = call_602090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602090.url(scheme.get, call_602090.host, call_602090.base,
                         call_602090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602090, url, valid)

proc call*(call_602091: Call_DescribeServices_602078; body: JsonNode): Recallable =
  ## describeServices
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ##   body: JObject (required)
  var body_602092 = newJObject()
  if body != nil:
    body_602092 = body
  result = call_602091.call(nil, nil, nil, nil, body_602092)

var describeServices* = Call_DescribeServices_602078(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeServices",
    validator: validate_DescribeServices_602079, base: "/",
    url: url_DescribeServices_602080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSeverityLevels_602093 = ref object of OpenApiRestCall_601389
proc url_DescribeSeverityLevels_602095(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSeverityLevels_602094(path: JsonNode; query: JsonNode;
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
  var valid_602096 = header.getOrDefault("X-Amz-Target")
  valid_602096 = validateParameter(valid_602096, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeSeverityLevels"))
  if valid_602096 != nil:
    section.add "X-Amz-Target", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Signature")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Signature", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Content-Sha256", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Date")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Date", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Credential")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Credential", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Security-Token")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Security-Token", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Algorithm")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Algorithm", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-SignedHeaders", valid_602103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602105: Call_DescribeSeverityLevels_602093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ## 
  let valid = call_602105.validator(path, query, header, formData, body)
  let scheme = call_602105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602105.url(scheme.get, call_602105.host, call_602105.base,
                         call_602105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602105, url, valid)

proc call*(call_602106: Call_DescribeSeverityLevels_602093; body: JsonNode): Recallable =
  ## describeSeverityLevels
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ##   body: JObject (required)
  var body_602107 = newJObject()
  if body != nil:
    body_602107 = body
  result = call_602106.call(nil, nil, nil, nil, body_602107)

var describeSeverityLevels* = Call_DescribeSeverityLevels_602093(
    name: "describeSeverityLevels", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeSeverityLevels",
    validator: validate_DescribeSeverityLevels_602094, base: "/",
    url: url_DescribeSeverityLevels_602095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckRefreshStatuses_602108 = ref object of OpenApiRestCall_601389
proc url_DescribeTrustedAdvisorCheckRefreshStatuses_602110(protocol: Scheme;
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

proc validate_DescribeTrustedAdvisorCheckRefreshStatuses_602109(path: JsonNode;
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
  var valid_602111 = header.getOrDefault("X-Amz-Target")
  valid_602111 = validateParameter(valid_602111, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses"))
  if valid_602111 != nil:
    section.add "X-Amz-Target", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Signature")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Signature", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Content-Sha256", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Date")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Date", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Credential")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Credential", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Security-Token")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Security-Token", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Algorithm")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Algorithm", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-SignedHeaders", valid_602118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_DescribeTrustedAdvisorCheckRefreshStatuses_602108;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_DescribeTrustedAdvisorCheckRefreshStatuses_602108;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckRefreshStatuses
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ##   body: JObject (required)
  var body_602122 = newJObject()
  if body != nil:
    body_602122 = body
  result = call_602121.call(nil, nil, nil, nil, body_602122)

var describeTrustedAdvisorCheckRefreshStatuses* = Call_DescribeTrustedAdvisorCheckRefreshStatuses_602108(
    name: "describeTrustedAdvisorCheckRefreshStatuses", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses",
    validator: validate_DescribeTrustedAdvisorCheckRefreshStatuses_602109,
    base: "/", url: url_DescribeTrustedAdvisorCheckRefreshStatuses_602110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckResult_602123 = ref object of OpenApiRestCall_601389
proc url_DescribeTrustedAdvisorCheckResult_602125(protocol: Scheme; host: string;
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

proc validate_DescribeTrustedAdvisorCheckResult_602124(path: JsonNode;
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
  var valid_602126 = header.getOrDefault("X-Amz-Target")
  valid_602126 = validateParameter(valid_602126, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckResult"))
  if valid_602126 != nil:
    section.add "X-Amz-Target", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Signature")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Signature", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Date")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Date", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Algorithm")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Algorithm", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-SignedHeaders", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602135: Call_DescribeTrustedAdvisorCheckResult_602123;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_602135.validator(path, query, header, formData, body)
  let scheme = call_602135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602135.url(scheme.get, call_602135.host, call_602135.base,
                         call_602135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602135, url, valid)

proc call*(call_602136: Call_DescribeTrustedAdvisorCheckResult_602123;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckResult
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602137 = newJObject()
  if body != nil:
    body_602137 = body
  result = call_602136.call(nil, nil, nil, nil, body_602137)

var describeTrustedAdvisorCheckResult* = Call_DescribeTrustedAdvisorCheckResult_602123(
    name: "describeTrustedAdvisorCheckResult", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckResult",
    validator: validate_DescribeTrustedAdvisorCheckResult_602124, base: "/",
    url: url_DescribeTrustedAdvisorCheckResult_602125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckSummaries_602138 = ref object of OpenApiRestCall_601389
proc url_DescribeTrustedAdvisorCheckSummaries_602140(protocol: Scheme;
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

proc validate_DescribeTrustedAdvisorCheckSummaries_602139(path: JsonNode;
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
  var valid_602141 = header.getOrDefault("X-Amz-Target")
  valid_602141 = validateParameter(valid_602141, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries"))
  if valid_602141 != nil:
    section.add "X-Amz-Target", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Signature")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Signature", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Content-Sha256", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Date")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Date", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Credential")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Credential", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Security-Token")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Security-Token", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Algorithm")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Algorithm", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-SignedHeaders", valid_602148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_DescribeTrustedAdvisorCheckSummaries_602138;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_DescribeTrustedAdvisorCheckSummaries_602138;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckSummaries
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ##   body: JObject (required)
  var body_602152 = newJObject()
  if body != nil:
    body_602152 = body
  result = call_602151.call(nil, nil, nil, nil, body_602152)

var describeTrustedAdvisorCheckSummaries* = Call_DescribeTrustedAdvisorCheckSummaries_602138(
    name: "describeTrustedAdvisorCheckSummaries", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries",
    validator: validate_DescribeTrustedAdvisorCheckSummaries_602139, base: "/",
    url: url_DescribeTrustedAdvisorCheckSummaries_602140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorChecks_602153 = ref object of OpenApiRestCall_601389
proc url_DescribeTrustedAdvisorChecks_602155(protocol: Scheme; host: string;
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

proc validate_DescribeTrustedAdvisorChecks_602154(path: JsonNode; query: JsonNode;
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
  var valid_602156 = header.getOrDefault("X-Amz-Target")
  valid_602156 = validateParameter(valid_602156, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorChecks"))
  if valid_602156 != nil:
    section.add "X-Amz-Target", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Signature", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Date")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Date", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Credential")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Credential", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Security-Token")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Security-Token", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Algorithm")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Algorithm", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-SignedHeaders", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602165: Call_DescribeTrustedAdvisorChecks_602153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ## 
  let valid = call_602165.validator(path, query, header, formData, body)
  let scheme = call_602165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602165.url(scheme.get, call_602165.host, call_602165.base,
                         call_602165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602165, url, valid)

proc call*(call_602166: Call_DescribeTrustedAdvisorChecks_602153; body: JsonNode): Recallable =
  ## describeTrustedAdvisorChecks
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ##   body: JObject (required)
  var body_602167 = newJObject()
  if body != nil:
    body_602167 = body
  result = call_602166.call(nil, nil, nil, nil, body_602167)

var describeTrustedAdvisorChecks* = Call_DescribeTrustedAdvisorChecks_602153(
    name: "describeTrustedAdvisorChecks", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorChecks",
    validator: validate_DescribeTrustedAdvisorChecks_602154, base: "/",
    url: url_DescribeTrustedAdvisorChecks_602155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshTrustedAdvisorCheck_602168 = ref object of OpenApiRestCall_601389
proc url_RefreshTrustedAdvisorCheck_602170(protocol: Scheme; host: string;
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

proc validate_RefreshTrustedAdvisorCheck_602169(path: JsonNode; query: JsonNode;
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
  var valid_602171 = header.getOrDefault("X-Amz-Target")
  valid_602171 = validateParameter(valid_602171, JString, required = true, default = newJString(
      "AWSSupport_20130415.RefreshTrustedAdvisorCheck"))
  if valid_602171 != nil:
    section.add "X-Amz-Target", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Signature")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Signature", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Content-Sha256", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Date")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Date", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Credential")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Credential", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Security-Token")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Security-Token", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Algorithm")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Algorithm", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-SignedHeaders", valid_602178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602180: Call_RefreshTrustedAdvisorCheck_602168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_602180.validator(path, query, header, formData, body)
  let scheme = call_602180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602180.url(scheme.get, call_602180.host, call_602180.base,
                         call_602180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602180, url, valid)

proc call*(call_602181: Call_RefreshTrustedAdvisorCheck_602168; body: JsonNode): Recallable =
  ## refreshTrustedAdvisorCheck
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602182 = newJObject()
  if body != nil:
    body_602182 = body
  result = call_602181.call(nil, nil, nil, nil, body_602182)

var refreshTrustedAdvisorCheck* = Call_RefreshTrustedAdvisorCheck_602168(
    name: "refreshTrustedAdvisorCheck", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.RefreshTrustedAdvisorCheck",
    validator: validate_RefreshTrustedAdvisorCheck_602169, base: "/",
    url: url_RefreshTrustedAdvisorCheck_602170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCase_602183 = ref object of OpenApiRestCall_601389
proc url_ResolveCase_602185(protocol: Scheme; host: string; base: string;
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

proc validate_ResolveCase_602184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602186 = header.getOrDefault("X-Amz-Target")
  valid_602186 = validateParameter(valid_602186, JString, required = true, default = newJString(
      "AWSSupport_20130415.ResolveCase"))
  if valid_602186 != nil:
    section.add "X-Amz-Target", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Signature")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Signature", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Content-Sha256", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Credential")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Credential", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Security-Token")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Security-Token", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-SignedHeaders", valid_602193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602195: Call_ResolveCase_602183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ## 
  let valid = call_602195.validator(path, query, header, formData, body)
  let scheme = call_602195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602195.url(scheme.get, call_602195.host, call_602195.base,
                         call_602195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602195, url, valid)

proc call*(call_602196: Call_ResolveCase_602183; body: JsonNode): Recallable =
  ## resolveCase
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ##   body: JObject (required)
  var body_602197 = newJObject()
  if body != nil:
    body_602197 = body
  result = call_602196.call(nil, nil, nil, nil, body_602197)

var resolveCase* = Call_ResolveCase_602183(name: "resolveCase",
                                        meth: HttpMethod.HttpPost,
                                        host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.ResolveCase",
                                        validator: validate_ResolveCase_602184,
                                        base: "/", url: url_ResolveCase_602185,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
