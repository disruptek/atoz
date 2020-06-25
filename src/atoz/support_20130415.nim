
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "support.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "support.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "support"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddAttachmentsToSet_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddAttachmentsToSet_21625781(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddAttachmentsToSet_21625780(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddAttachmentsToSet"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AddAttachmentsToSet_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AddAttachmentsToSet_21625779; body: JsonNode): Recallable =
  ## addAttachmentsToSet
  ## <p>Adds one or more attachments to an attachment set. If an <code>attachmentSetId</code> is not specified, a new attachment set is created, and the ID of the set is returned in the response. If an <code>attachmentSetId</code> is specified, the attachments are added to the specified set, if it exists.</p> <p>An attachment set is a temporary container for attachments that are to be added to a case or case communication. The set is available for one hour after it is created; the <code>expiryTime</code> returned in the response indicates when the set expires. The maximum number of attachments in a set is 3, and the maximum size of any attachment in the set is 5 MB.</p>
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var addAttachmentsToSet* = Call_AddAttachmentsToSet_21625779(
    name: "addAttachmentsToSet", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddAttachmentsToSet",
    validator: validate_AddAttachmentsToSet_21625780, base: "/",
    makeUrl: url_AddAttachmentsToSet_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddCommunicationToCase_21626029 = ref object of OpenApiRestCall_21625435
proc url_AddCommunicationToCase_21626031(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddCommunicationToCase_21626030(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWSSupport_20130415.AddCommunicationToCase"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_AddCommunicationToCase_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AddCommunicationToCase_21626029; body: JsonNode): Recallable =
  ## addCommunicationToCase
  ## <p>Adds additional customer communication to an AWS Support case. You use the <code>caseId</code> value to identify the case to add communication to. You can list a set of email addresses to copy on the communication using the <code>ccEmailAddresses</code> value. The <code>communicationBody</code> value contains the text of the communication.</p> <p>The response indicates the success or failure of the request.</p> <p>This operation implements a subset of the features of the AWS Support Center.</p>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var addCommunicationToCase* = Call_AddCommunicationToCase_21626029(
    name: "addCommunicationToCase", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.AddCommunicationToCase",
    validator: validate_AddCommunicationToCase_21626030, base: "/",
    makeUrl: url_AddCommunicationToCase_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCase_21626044 = ref object of OpenApiRestCall_21625435
proc url_CreateCase_21626046(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCase_21626045(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWSSupport_20130415.CreateCase"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
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

proc call*(call_21626056: Call_CreateCase_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_CreateCase_21626044; body: JsonNode): Recallable =
  ## createCase
  ## <p>Creates a new case in the AWS Support Center. This operation is modeled on the behavior of the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. Its parameters require you to specify the following information:</p> <ul> <li> <p> <b>issueType.</b> The type of issue for the case. You can specify either "customer-service" or "technical." If you do not indicate a value, the default is "technical."</p> <note> <p>Service limit increases are not supported by the Support API; you must submit service limit increase requests in <a href="https://console.aws.amazon.com/support">Support Center</a>.</p> <p>The <code>caseId</code> is not the <code>displayId</code> that appears in <a href="https://console.aws.amazon.com/support">Support Center</a>. You can use the <a>DescribeCases</a> API to get the <code>displayId</code>.</p> </note> </li> <li> <p> <b>serviceCode.</b> The code for an AWS service. You can get the possible <code>serviceCode</code> values by calling <a>DescribeServices</a>.</p> </li> <li> <p> <b>categoryCode.</b> The category for the service defined for the <code>serviceCode</code> value. You also get the category code for a service by calling <a>DescribeServices</a>. Each AWS service defines its own set of category codes.</p> </li> <li> <p> <b>severityCode.</b> A value that indicates the urgency of the case, which in turn determines the response time according to your service level agreement with AWS Support. You can get the possible <code>severityCode</code> values by calling <a>DescribeSeverityLevels</a>. For more information about the meaning of the codes, see <a>SeverityLevel</a> and <a href="https://docs.aws.amazon.com/awssupport/latest/user/getting-started.html#choosing-severity">Choosing a Severity</a>.</p> </li> <li> <p> <b>subject.</b> The <b>Subject</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>communicationBody.</b> The <b>Description</b> field on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page.</p> </li> <li> <p> <b>attachmentSetId.</b> The ID of a set of attachments that has been created by using <a>AddAttachmentsToSet</a>.</p> </li> <li> <p> <b>language.</b> The human language in which AWS Support handles the case. English and Japanese are currently supported.</p> </li> <li> <p> <b>ccEmailAddresses.</b> The AWS Support Center <b>CC</b> field on the <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. You can list email addresses to be copied on any correspondence about the case. The account that opens the case is already identified by passing the AWS Credentials in the HTTP POST method or in a method or function call from one of the programming languages supported by an <a href="http://aws.amazon.com/tools/">AWS SDK</a>. </p> </li> </ul> <note> <p>To add additional communication or attachments to an existing case, use <a>AddCommunicationToCase</a>.</p> </note> <p>A successful <a>CreateCase</a> request returns an AWS Support case number. Case numbers are used by the <a>DescribeCases</a> operation to retrieve existing AWS Support cases.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var createCase* = Call_CreateCase_21626044(name: "createCase",
                                        meth: HttpMethod.HttpPost,
                                        host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.CreateCase",
                                        validator: validate_CreateCase_21626045,
                                        base: "/", makeUrl: url_CreateCase_21626046,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAttachment_21626059 = ref object of OpenApiRestCall_21625435
proc url_DescribeAttachment_21626061(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAttachment_21626060(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeAttachment"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_DescribeAttachment_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_DescribeAttachment_21626059; body: JsonNode): Recallable =
  ## describeAttachment
  ## Returns the attachment that has the specified ID. Attachment IDs are generated by the case management system when you add an attachment to a case or case communication. Attachment IDs are returned in the <a>AttachmentDetails</a> objects that are returned by the <a>DescribeCommunications</a> operation.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var describeAttachment* = Call_DescribeAttachment_21626059(
    name: "describeAttachment", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeAttachment",
    validator: validate_DescribeAttachment_21626060, base: "/",
    makeUrl: url_DescribeAttachment_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCases_21626074 = ref object of OpenApiRestCall_21625435
proc url_DescribeCases_21626076(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCases_21626075(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626077 = query.getOrDefault("maxResults")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "maxResults", valid_21626077
  var valid_21626078 = query.getOrDefault("nextToken")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "nextToken", valid_21626078
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
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Target")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCases"))
  if valid_21626081 != nil:
    section.add "X-Amz-Target", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Algorithm", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Signature")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Signature", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Credential")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Credential", valid_21626086
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

proc call*(call_21626088: Call_DescribeCases_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_DescribeCases_21626074; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeCases
  ## <p>Returns a list of cases that you specify by passing one or more case IDs. In addition, you can filter the cases by date by setting values for the <code>afterTime</code> and <code>beforeTime</code> request parameters. You can set values for the <code>includeResolvedCases</code> and <code>includeCommunications</code> request parameters to control how much information is returned.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>The response returns the following in JSON format:</p> <ul> <li> <p>One or more <a>CaseDetails</a> data types.</p> </li> <li> <p>One or more <code>nextToken</code> values, which specify where to paginate the returned records represented by the <code>CaseDetails</code> objects.</p> </li> </ul>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626091 = newJObject()
  var body_21626092 = newJObject()
  add(query_21626091, "maxResults", newJString(maxResults))
  add(query_21626091, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626092 = body
  result = call_21626089.call(nil, query_21626091, nil, nil, body_21626092)

var describeCases* = Call_DescribeCases_21626074(name: "describeCases",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCases",
    validator: validate_DescribeCases_21626075, base: "/",
    makeUrl: url_DescribeCases_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCommunications_21626096 = ref object of OpenApiRestCall_21625435
proc url_DescribeCommunications_21626098(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCommunications_21626097(path: JsonNode; query: JsonNode;
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
  var valid_21626099 = query.getOrDefault("maxResults")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "maxResults", valid_21626099
  var valid_21626100 = query.getOrDefault("nextToken")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "nextToken", valid_21626100
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
  var valid_21626101 = header.getOrDefault("X-Amz-Date")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Date", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Security-Token", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Target")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeCommunications"))
  if valid_21626103 != nil:
    section.add "X-Amz-Target", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
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

proc call*(call_21626110: Call_DescribeCommunications_21626096;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ## 
  let valid = call_21626110.validator(path, query, header, formData, body, _)
  let scheme = call_21626110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626110.makeUrl(scheme.get, call_21626110.host, call_21626110.base,
                               call_21626110.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626110, uri, valid, _)

proc call*(call_21626111: Call_DescribeCommunications_21626096; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeCommunications
  ## <p>Returns communications (and attachments) for one or more support cases. You can use the <code>afterTime</code> and <code>beforeTime</code> parameters to filter by date. You can use the <code>caseId</code> parameter to restrict the results to a particular case.</p> <p>Case data is available for 12 months after creation. If a case was created more than 12 months ago, a request for data might cause an error.</p> <p>You can use the <code>maxResults</code> and <code>nextToken</code> parameters to control the pagination of the result set. Set <code>maxResults</code> to the number of cases you want displayed on each page, and use <code>nextToken</code> to specify the resumption of pagination.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626112 = newJObject()
  var body_21626113 = newJObject()
  add(query_21626112, "maxResults", newJString(maxResults))
  add(query_21626112, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626113 = body
  result = call_21626111.call(nil, query_21626112, nil, nil, body_21626113)

var describeCommunications* = Call_DescribeCommunications_21626096(
    name: "describeCommunications", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeCommunications",
    validator: validate_DescribeCommunications_21626097, base: "/",
    makeUrl: url_DescribeCommunications_21626098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_21626114 = ref object of OpenApiRestCall_21625435
proc url_DescribeServices_21626116(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServices_21626115(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626117 = header.getOrDefault("X-Amz-Date")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Date", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Security-Token", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Target")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeServices"))
  if valid_21626119 != nil:
    section.add "X-Amz-Target", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
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

proc call*(call_21626126: Call_DescribeServices_21626114; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ## 
  let valid = call_21626126.validator(path, query, header, formData, body, _)
  let scheme = call_21626126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626126.makeUrl(scheme.get, call_21626126.host, call_21626126.base,
                               call_21626126.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626126, uri, valid, _)

proc call*(call_21626127: Call_DescribeServices_21626114; body: JsonNode): Recallable =
  ## describeServices
  ## <p>Returns the current list of AWS services and a list of service categories that applies to each one. You then use service names and categories in your <a>CreateCase</a> requests. Each AWS service has its own set of categories.</p> <p>The service codes and category codes correspond to the values that are displayed in the <b>Service</b> and <b>Category</b> drop-down lists on the AWS Support Center <a href="https://console.aws.amazon.com/support/home#/case/create">Create Case</a> page. The values in those fields, however, do not necessarily match the service codes and categories returned by the <code>DescribeServices</code> request. Always use the service codes and categories obtained programmatically. This practice ensures that you always have the most recent set of service and category codes.</p>
  ##   body: JObject (required)
  var body_21626128 = newJObject()
  if body != nil:
    body_21626128 = body
  result = call_21626127.call(nil, nil, nil, nil, body_21626128)

var describeServices* = Call_DescribeServices_21626114(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeServices",
    validator: validate_DescribeServices_21626115, base: "/",
    makeUrl: url_DescribeServices_21626116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSeverityLevels_21626129 = ref object of OpenApiRestCall_21625435
proc url_DescribeSeverityLevels_21626131(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSeverityLevels_21626130(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626132 = header.getOrDefault("X-Amz-Date")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Date", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Security-Token", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Target")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeSeverityLevels"))
  if valid_21626134 != nil:
    section.add "X-Amz-Target", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Algorithm", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Signature")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Signature", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Credential")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Credential", valid_21626139
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

proc call*(call_21626141: Call_DescribeSeverityLevels_21626129;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ## 
  let valid = call_21626141.validator(path, query, header, formData, body, _)
  let scheme = call_21626141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626141.makeUrl(scheme.get, call_21626141.host, call_21626141.base,
                               call_21626141.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626141, uri, valid, _)

proc call*(call_21626142: Call_DescribeSeverityLevels_21626129; body: JsonNode): Recallable =
  ## describeSeverityLevels
  ## Returns the list of severity levels that you can assign to an AWS Support case. The severity level for a case is also a field in the <a>CaseDetails</a> data type included in any <a>CreateCase</a> request.
  ##   body: JObject (required)
  var body_21626143 = newJObject()
  if body != nil:
    body_21626143 = body
  result = call_21626142.call(nil, nil, nil, nil, body_21626143)

var describeSeverityLevels* = Call_DescribeSeverityLevels_21626129(
    name: "describeSeverityLevels", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeSeverityLevels",
    validator: validate_DescribeSeverityLevels_21626130, base: "/",
    makeUrl: url_DescribeSeverityLevels_21626131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckRefreshStatuses_21626144 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrustedAdvisorCheckRefreshStatuses_21626146(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckRefreshStatuses_21626145(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
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
  var valid_21626147 = header.getOrDefault("X-Amz-Date")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Date", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Security-Token", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Target")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses"))
  if valid_21626149 != nil:
    section.add "X-Amz-Target", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Algorithm", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Signature")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Signature", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Credential")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Credential", valid_21626154
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

proc call*(call_21626156: Call_DescribeTrustedAdvisorCheckRefreshStatuses_21626144;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_DescribeTrustedAdvisorCheckRefreshStatuses_21626144;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckRefreshStatuses
  ## <p>Returns the refresh status of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and their refresh statuses cannot be retrieved by using this operation. Use of the <code>DescribeTrustedAdvisorCheckRefreshStatuses</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note>
  ##   body: JObject (required)
  var body_21626158 = newJObject()
  if body != nil:
    body_21626158 = body
  result = call_21626157.call(nil, nil, nil, nil, body_21626158)

var describeTrustedAdvisorCheckRefreshStatuses* = Call_DescribeTrustedAdvisorCheckRefreshStatuses_21626144(
    name: "describeTrustedAdvisorCheckRefreshStatuses", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckRefreshStatuses",
    validator: validate_DescribeTrustedAdvisorCheckRefreshStatuses_21626145,
    base: "/", makeUrl: url_DescribeTrustedAdvisorCheckRefreshStatuses_21626146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckResult_21626159 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrustedAdvisorCheckResult_21626161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckResult_21626160(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626162 = header.getOrDefault("X-Amz-Date")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Date", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Security-Token", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Target")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckResult"))
  if valid_21626164 != nil:
    section.add "X-Amz-Target", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Algorithm", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Signature")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Signature", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Credential")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Credential", valid_21626169
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

proc call*(call_21626171: Call_DescribeTrustedAdvisorCheckResult_21626159;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_21626171.validator(path, query, header, formData, body, _)
  let scheme = call_21626171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626171.makeUrl(scheme.get, call_21626171.host, call_21626171.base,
                               call_21626171.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626171, uri, valid, _)

proc call*(call_21626172: Call_DescribeTrustedAdvisorCheckResult_21626159;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckResult
  ## <p>Returns the results of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains a <a>TrustedAdvisorCheckResult</a> object, which contains these three objects:</p> <ul> <li> <p> <a>TrustedAdvisorCategorySpecificSummary</a> </p> </li> <li> <p> <a>TrustedAdvisorResourceDetail</a> </p> </li> <li> <p> <a>TrustedAdvisorResourcesSummary</a> </p> </li> </ul> <p>In addition, the response contains these fields:</p> <ul> <li> <p> <b>status.</b> The alert status of the check: "ok" (green), "warning" (yellow), "error" (red), or "not_available".</p> </li> <li> <p> <b>timestamp.</b> The time of the last refresh of the check.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626173 = newJObject()
  if body != nil:
    body_21626173 = body
  result = call_21626172.call(nil, nil, nil, nil, body_21626173)

var describeTrustedAdvisorCheckResult* = Call_DescribeTrustedAdvisorCheckResult_21626159(
    name: "describeTrustedAdvisorCheckResult", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckResult",
    validator: validate_DescribeTrustedAdvisorCheckResult_21626160, base: "/",
    makeUrl: url_DescribeTrustedAdvisorCheckResult_21626161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorCheckSummaries_21626174 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrustedAdvisorCheckSummaries_21626176(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorCheckSummaries_21626175(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626177 = header.getOrDefault("X-Amz-Date")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Date", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Security-Token", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Target")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries"))
  if valid_21626179 != nil:
    section.add "X-Amz-Target", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Algorithm", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Signature")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Signature", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Credential")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Credential", valid_21626184
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

proc call*(call_21626186: Call_DescribeTrustedAdvisorCheckSummaries_21626174;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ## 
  let valid = call_21626186.validator(path, query, header, formData, body, _)
  let scheme = call_21626186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626186.makeUrl(scheme.get, call_21626186.host, call_21626186.base,
                               call_21626186.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626186, uri, valid, _)

proc call*(call_21626187: Call_DescribeTrustedAdvisorCheckSummaries_21626174;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorCheckSummaries
  ## <p>Returns the summaries of the results of the Trusted Advisor checks that have the specified check IDs. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <p>The response contains an array of <a>TrustedAdvisorCheckSummary</a> objects.</p>
  ##   body: JObject (required)
  var body_21626188 = newJObject()
  if body != nil:
    body_21626188 = body
  result = call_21626187.call(nil, nil, nil, nil, body_21626188)

var describeTrustedAdvisorCheckSummaries* = Call_DescribeTrustedAdvisorCheckSummaries_21626174(
    name: "describeTrustedAdvisorCheckSummaries", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com", route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorCheckSummaries",
    validator: validate_DescribeTrustedAdvisorCheckSummaries_21626175, base: "/",
    makeUrl: url_DescribeTrustedAdvisorCheckSummaries_21626176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrustedAdvisorChecks_21626189 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrustedAdvisorChecks_21626191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrustedAdvisorChecks_21626190(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626192 = header.getOrDefault("X-Amz-Date")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Date", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Security-Token", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Target")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true, default = newJString(
      "AWSSupport_20130415.DescribeTrustedAdvisorChecks"))
  if valid_21626194 != nil:
    section.add "X-Amz-Target", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Algorithm", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Signature")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Signature", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Credential")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Credential", valid_21626199
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

proc call*(call_21626201: Call_DescribeTrustedAdvisorChecks_21626189;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ## 
  let valid = call_21626201.validator(path, query, header, formData, body, _)
  let scheme = call_21626201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626201.makeUrl(scheme.get, call_21626201.host, call_21626201.base,
                               call_21626201.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626201, uri, valid, _)

proc call*(call_21626202: Call_DescribeTrustedAdvisorChecks_21626189;
          body: JsonNode): Recallable =
  ## describeTrustedAdvisorChecks
  ## Returns information about all available Trusted Advisor checks, including name, ID, category, description, and metadata. You must specify a language code; English ("en") and Japanese ("ja") are currently supported. The response contains a <a>TrustedAdvisorCheckDescription</a> for each check. The region must be set to us-east-1.
  ##   body: JObject (required)
  var body_21626203 = newJObject()
  if body != nil:
    body_21626203 = body
  result = call_21626202.call(nil, nil, nil, nil, body_21626203)

var describeTrustedAdvisorChecks* = Call_DescribeTrustedAdvisorChecks_21626189(
    name: "describeTrustedAdvisorChecks", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.DescribeTrustedAdvisorChecks",
    validator: validate_DescribeTrustedAdvisorChecks_21626190, base: "/",
    makeUrl: url_DescribeTrustedAdvisorChecks_21626191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshTrustedAdvisorCheck_21626204 = ref object of OpenApiRestCall_21625435
proc url_RefreshTrustedAdvisorCheck_21626206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RefreshTrustedAdvisorCheck_21626205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
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
  var valid_21626207 = header.getOrDefault("X-Amz-Date")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Date", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Security-Token", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Target")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true, default = newJString(
      "AWSSupport_20130415.RefreshTrustedAdvisorCheck"))
  if valid_21626209 != nil:
    section.add "X-Amz-Target", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
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

proc call*(call_21626216: Call_RefreshTrustedAdvisorCheck_21626204;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ## 
  let valid = call_21626216.validator(path, query, header, formData, body, _)
  let scheme = call_21626216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626216.makeUrl(scheme.get, call_21626216.host, call_21626216.base,
                               call_21626216.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626216, uri, valid, _)

proc call*(call_21626217: Call_RefreshTrustedAdvisorCheck_21626204; body: JsonNode): Recallable =
  ## refreshTrustedAdvisorCheck
  ## <p>Requests a refresh of the Trusted Advisor check that has the specified check ID. Check IDs can be obtained by calling <a>DescribeTrustedAdvisorChecks</a>.</p> <note> <p>Some checks are refreshed automatically, and they cannot be refreshed by using this operation. Use of the <code>RefreshTrustedAdvisorCheck</code> operation for these checks causes an <code>InvalidParameterValue</code> error.</p> </note> <p>The response contains a <a>TrustedAdvisorCheckRefreshStatus</a> object, which contains these fields:</p> <ul> <li> <p> <b>status.</b> The refresh status of the check: </p> <ul> <li> <p> <code>none:</code> The check is not refreshed or the non-success status exceeds the timeout</p> </li> <li> <p> <code>enqueued:</code> The check refresh requests has entered the refresh queue</p> </li> <li> <p> <code>processing:</code> The check refresh request is picked up by the rule processing engine</p> </li> <li> <p> <code>success:</code> The check is successfully refreshed</p> </li> <li> <p> <code>abandoned:</code> The check refresh has failed</p> </li> </ul> </li> <li> <p> <b>millisUntilNextRefreshable.</b> The amount of time, in milliseconds, until the check is eligible for refresh.</p> </li> <li> <p> <b>checkId.</b> The unique identifier for the check.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626218 = newJObject()
  if body != nil:
    body_21626218 = body
  result = call_21626217.call(nil, nil, nil, nil, body_21626218)

var refreshTrustedAdvisorCheck* = Call_RefreshTrustedAdvisorCheck_21626204(
    name: "refreshTrustedAdvisorCheck", meth: HttpMethod.HttpPost,
    host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.RefreshTrustedAdvisorCheck",
    validator: validate_RefreshTrustedAdvisorCheck_21626205, base: "/",
    makeUrl: url_RefreshTrustedAdvisorCheck_21626206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCase_21626219 = ref object of OpenApiRestCall_21625435
proc url_ResolveCase_21626221(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResolveCase_21626220(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626222 = header.getOrDefault("X-Amz-Date")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Date", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Security-Token", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Target")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true, default = newJString(
      "AWSSupport_20130415.ResolveCase"))
  if valid_21626224 != nil:
    section.add "X-Amz-Target", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Algorithm", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Signature")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Signature", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Credential")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Credential", valid_21626229
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

proc call*(call_21626231: Call_ResolveCase_21626219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ## 
  let valid = call_21626231.validator(path, query, header, formData, body, _)
  let scheme = call_21626231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626231.makeUrl(scheme.get, call_21626231.host, call_21626231.base,
                               call_21626231.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626231, uri, valid, _)

proc call*(call_21626232: Call_ResolveCase_21626219; body: JsonNode): Recallable =
  ## resolveCase
  ## Takes a <code>caseId</code> and returns the initial state of the case along with the state of the case after the call to <a>ResolveCase</a> completed.
  ##   body: JObject (required)
  var body_21626233 = newJObject()
  if body != nil:
    body_21626233 = body
  result = call_21626232.call(nil, nil, nil, nil, body_21626233)

var resolveCase* = Call_ResolveCase_21626219(name: "resolveCase",
    meth: HttpMethod.HttpPost, host: "support.amazonaws.com",
    route: "/#X-Amz-Target=AWSSupport_20130415.ResolveCase",
    validator: validate_ResolveCase_21626220, base: "/", makeUrl: url_ResolveCase_21626221,
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