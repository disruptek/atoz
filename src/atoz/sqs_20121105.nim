
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Queue Service
## version: 2012-11-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Welcome to the <i>Amazon Simple Queue Service API Reference</i>.</p> <p>Amazon Simple Queue Service (Amazon SQS) is a reliable, highly-scalable hosted queue for storing messages as they travel between applications or microservices. Amazon SQS moves data between distributed application components and helps you decouple these components.</p> <p>You can use <a href="http://aws.amazon.com/tools/#sdk">AWS SDKs</a> to access Amazon SQS using your favorite programming language. The SDKs perform tasks such as the following automatically:</p> <ul> <li> <p>Cryptographically sign your service requests</p> </li> <li> <p>Retry requests</p> </li> <li> <p>Handle error responses</p> </li> </ul> <p> <b>Additional Information</b> </p> <ul> <li> <p> <a href="http://aws.amazon.com/sqs/">Amazon SQS Product Page</a> </p> </li> <li> <p> <i>Amazon Simple Queue Service Developer Guide</i> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html">Making API Requests</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-attributes.html">Amazon SQS Message Attributes</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Amazon SQS Dead-Letter Queues</a> </p> </li> </ul> </li> <li> <p> <a href="http://docs.aws.amazon.com/cli/latest/reference/sqs/index.html">Amazon SQS in the <i>AWS CLI Command Reference</i> </a> </p> </li> <li> <p> <i>Amazon Web Services General Reference</i> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#sqs_region">Regions and Endpoints</a> </p> </li> </ul> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sqs/
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "sqs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sqs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sqs.us-west-2.amazonaws.com",
                           "eu-west-2": "sqs.eu-west-2.amazonaws.com", "ap-northeast-3": "sqs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sqs.eu-central-1.amazonaws.com",
                           "us-east-2": "sqs.us-east-2.amazonaws.com",
                           "us-east-1": "sqs.us-east-1.amazonaws.com", "cn-northwest-1": "sqs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sqs.ap-south-1.amazonaws.com",
                           "eu-north-1": "sqs.eu-north-1.amazonaws.com", "ap-northeast-2": "sqs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sqs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sqs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sqs.eu-west-3.amazonaws.com",
                           "cn-north-1": "sqs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sqs.sa-east-1.amazonaws.com",
                           "eu-west-1": "sqs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sqs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sqs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sqs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sqs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sqs.ap-southeast-1.amazonaws.com",
      "us-west-2": "sqs.us-west-2.amazonaws.com",
      "eu-west-2": "sqs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sqs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sqs.eu-central-1.amazonaws.com",
      "us-east-2": "sqs.us-east-2.amazonaws.com",
      "us-east-1": "sqs.us-east-1.amazonaws.com",
      "cn-northwest-1": "sqs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sqs.ap-south-1.amazonaws.com",
      "eu-north-1": "sqs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sqs.ap-northeast-2.amazonaws.com",
      "us-west-1": "sqs.us-west-1.amazonaws.com",
      "us-gov-east-1": "sqs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sqs.eu-west-3.amazonaws.com",
      "cn-north-1": "sqs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sqs.sa-east-1.amazonaws.com",
      "eu-west-1": "sqs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sqs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sqs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sqs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sqs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_599979 = ref object of OpenApiRestCall_599352
proc url_PostAddPermission_599981(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=AddPermission")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostAddPermission_599980(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_599982 = path.getOrDefault("QueueName")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = nil)
  if valid_599982 != nil:
    section.add "QueueName", valid_599982
  var valid_599983 = path.getOrDefault("AccountNumber")
  valid_599983 = validateParameter(valid_599983, JInt, required = true, default = nil)
  if valid_599983 != nil:
    section.add "AccountNumber", valid_599983
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599984 = query.getOrDefault("Action")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_599984 != nil:
    section.add "Action", valid_599984
  var valid_599985 = query.getOrDefault("Version")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_599985 != nil:
    section.add "Version", valid_599985
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
  var valid_599986 = header.getOrDefault("X-Amz-Date")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Date", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Security-Token")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Security-Token", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Content-Sha256", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Algorithm")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Algorithm", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Signature")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Signature", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-SignedHeaders", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Credential")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Credential", valid_599992
  result.add "header", section
  ## parameters in `formData` object:
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   Label: JString (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Actions` field"
  var valid_599993 = formData.getOrDefault("Actions")
  valid_599993 = validateParameter(valid_599993, JArray, required = true, default = nil)
  if valid_599993 != nil:
    section.add "Actions", valid_599993
  var valid_599994 = formData.getOrDefault("Label")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "Label", valid_599994
  var valid_599995 = formData.getOrDefault("AWSAccountIds")
  valid_599995 = validateParameter(valid_599995, JArray, required = true, default = nil)
  if valid_599995 != nil:
    section.add "AWSAccountIds", valid_599995
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599996: Call_PostAddPermission_599979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_599996.validator(path, query, header, formData, body)
  let scheme = call_599996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599996.url(scheme.get, call_599996.host, call_599996.base,
                         call_599996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599996, url, valid)

proc call*(call_599997: Call_PostAddPermission_599979; Actions: JsonNode;
          Label: string; AWSAccountIds: JsonNode; QueueName: string;
          AccountNumber: int; Action: string = "AddPermission";
          Version: string = "2012-11-05"): Recallable =
  ## postAddPermission
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   Label: string (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_599998 = newJObject()
  var query_599999 = newJObject()
  var formData_600000 = newJObject()
  if Actions != nil:
    formData_600000.add "Actions", Actions
  add(formData_600000, "Label", newJString(Label))
  if AWSAccountIds != nil:
    formData_600000.add "AWSAccountIds", AWSAccountIds
  add(path_599998, "QueueName", newJString(QueueName))
  add(query_599999, "Action", newJString(Action))
  add(path_599998, "AccountNumber", newJInt(AccountNumber))
  add(query_599999, "Version", newJString(Version))
  result = call_599997.call(path_599998, query_599999, nil, formData_600000, nil)

var postAddPermission* = Call_PostAddPermission_599979(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_PostAddPermission_599980, base: "/",
    url: url_PostAddPermission_599981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_599689 = ref object of OpenApiRestCall_599352
proc url_GetAddPermission_599691(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=AddPermission")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAddPermission_599690(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_599817 = path.getOrDefault("QueueName")
  valid_599817 = validateParameter(valid_599817, JString, required = true,
                                 default = nil)
  if valid_599817 != nil:
    section.add "QueueName", valid_599817
  var valid_599818 = path.getOrDefault("AccountNumber")
  valid_599818 = validateParameter(valid_599818, JInt, required = true, default = nil)
  if valid_599818 != nil:
    section.add "AccountNumber", valid_599818
  result.add "path", section
  ## parameters in `query` object:
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  ##   Action: JString (required)
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AWSAccountIds` field"
  var valid_599819 = query.getOrDefault("AWSAccountIds")
  valid_599819 = validateParameter(valid_599819, JArray, required = true, default = nil)
  if valid_599819 != nil:
    section.add "AWSAccountIds", valid_599819
  var valid_599833 = query.getOrDefault("Action")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_599833 != nil:
    section.add "Action", valid_599833
  var valid_599834 = query.getOrDefault("Actions")
  valid_599834 = validateParameter(valid_599834, JArray, required = true, default = nil)
  if valid_599834 != nil:
    section.add "Actions", valid_599834
  var valid_599835 = query.getOrDefault("Version")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_599835 != nil:
    section.add "Version", valid_599835
  var valid_599836 = query.getOrDefault("Label")
  valid_599836 = validateParameter(valid_599836, JString, required = true,
                                 default = nil)
  if valid_599836 != nil:
    section.add "Label", valid_599836
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
  var valid_599837 = header.getOrDefault("X-Amz-Date")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Date", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Security-Token")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Security-Token", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Content-Sha256", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Algorithm")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Algorithm", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Signature")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Signature", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-SignedHeaders", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-Credential")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-Credential", valid_599843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599866: Call_GetAddPermission_599689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_599866.validator(path, query, header, formData, body)
  let scheme = call_599866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599866.url(scheme.get, call_599866.host, call_599866.base,
                         call_599866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599866, url, valid)

proc call*(call_599937: Call_GetAddPermission_599689; AWSAccountIds: JsonNode;
          QueueName: string; Actions: JsonNode; AccountNumber: int; Label: string;
          Action: string = "AddPermission"; Version: string = "2012-11-05"): Recallable =
  ## getAddPermission
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  var path_599938 = newJObject()
  var query_599940 = newJObject()
  if AWSAccountIds != nil:
    query_599940.add "AWSAccountIds", AWSAccountIds
  add(path_599938, "QueueName", newJString(QueueName))
  add(query_599940, "Action", newJString(Action))
  if Actions != nil:
    query_599940.add "Actions", Actions
  add(path_599938, "AccountNumber", newJInt(AccountNumber))
  add(query_599940, "Version", newJString(Version))
  add(query_599940, "Label", newJString(Label))
  result = call_599937.call(path_599938, query_599940, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_599689(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_GetAddPermission_599690, base: "/",
    url: url_GetAddPermission_599691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibility_600021 = ref object of OpenApiRestCall_599352
proc url_PostChangeMessageVisibility_600023(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ChangeMessageVisibility")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostChangeMessageVisibility_600022(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600024 = path.getOrDefault("QueueName")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = nil)
  if valid_600024 != nil:
    section.add "QueueName", valid_600024
  var valid_600025 = path.getOrDefault("AccountNumber")
  valid_600025 = validateParameter(valid_600025, JInt, required = true, default = nil)
  if valid_600025 != nil:
    section.add "AccountNumber", valid_600025
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600026 = query.getOrDefault("Action")
  valid_600026 = validateParameter(valid_600026, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_600026 != nil:
    section.add "Action", valid_600026
  var valid_600027 = query.getOrDefault("Version")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600027 != nil:
    section.add "Version", valid_600027
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
  var valid_600028 = header.getOrDefault("X-Amz-Date")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Date", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Security-Token")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Security-Token", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Content-Sha256", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Algorithm")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Algorithm", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Signature")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Signature", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-SignedHeaders", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Credential")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Credential", valid_600034
  result.add "header", section
  ## parameters in `formData` object:
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `VisibilityTimeout` field"
  var valid_600035 = formData.getOrDefault("VisibilityTimeout")
  valid_600035 = validateParameter(valid_600035, JInt, required = true, default = nil)
  if valid_600035 != nil:
    section.add "VisibilityTimeout", valid_600035
  var valid_600036 = formData.getOrDefault("ReceiptHandle")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = nil)
  if valid_600036 != nil:
    section.add "ReceiptHandle", valid_600036
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600037: Call_PostChangeMessageVisibility_600021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_600037.validator(path, query, header, formData, body)
  let scheme = call_600037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600037.url(scheme.get, call_600037.host, call_600037.base,
                         call_600037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600037, url, valid)

proc call*(call_600038: Call_PostChangeMessageVisibility_600021;
          VisibilityTimeout: int; QueueName: string; AccountNumber: int;
          ReceiptHandle: string; Action: string = "ChangeMessageVisibility";
          Version: string = "2012-11-05"): Recallable =
  ## postChangeMessageVisibility
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ##   VisibilityTimeout: int (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   Version: string (required)
  var path_600039 = newJObject()
  var query_600040 = newJObject()
  var formData_600041 = newJObject()
  add(formData_600041, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(path_600039, "QueueName", newJString(QueueName))
  add(query_600040, "Action", newJString(Action))
  add(path_600039, "AccountNumber", newJInt(AccountNumber))
  add(formData_600041, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_600040, "Version", newJString(Version))
  result = call_600038.call(path_600039, query_600040, nil, formData_600041, nil)

var postChangeMessageVisibility* = Call_PostChangeMessageVisibility_600021(
    name: "postChangeMessageVisibility", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_PostChangeMessageVisibility_600022, base: "/",
    url: url_PostChangeMessageVisibility_600023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibility_600001 = ref object of OpenApiRestCall_599352
proc url_GetChangeMessageVisibility_600003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ChangeMessageVisibility")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChangeMessageVisibility_600002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600004 = path.getOrDefault("QueueName")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = nil)
  if valid_600004 != nil:
    section.add "QueueName", valid_600004
  var valid_600005 = path.getOrDefault("AccountNumber")
  valid_600005 = validateParameter(valid_600005, JInt, required = true, default = nil)
  if valid_600005 != nil:
    section.add "AccountNumber", valid_600005
  result.add "path", section
  ## parameters in `query` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ReceiptHandle` field"
  var valid_600006 = query.getOrDefault("ReceiptHandle")
  valid_600006 = validateParameter(valid_600006, JString, required = true,
                                 default = nil)
  if valid_600006 != nil:
    section.add "ReceiptHandle", valid_600006
  var valid_600007 = query.getOrDefault("Action")
  valid_600007 = validateParameter(valid_600007, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_600007 != nil:
    section.add "Action", valid_600007
  var valid_600008 = query.getOrDefault("Version")
  valid_600008 = validateParameter(valid_600008, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600008 != nil:
    section.add "Version", valid_600008
  var valid_600009 = query.getOrDefault("VisibilityTimeout")
  valid_600009 = validateParameter(valid_600009, JInt, required = true, default = nil)
  if valid_600009 != nil:
    section.add "VisibilityTimeout", valid_600009
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
  var valid_600010 = header.getOrDefault("X-Amz-Date")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Date", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Security-Token")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Security-Token", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Content-Sha256", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Algorithm")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Algorithm", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Signature")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Signature", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-SignedHeaders", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Credential")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Credential", valid_600016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600017: Call_GetChangeMessageVisibility_600001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_600017.validator(path, query, header, formData, body)
  let scheme = call_600017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600017.url(scheme.get, call_600017.host, call_600017.base,
                         call_600017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600017, url, valid)

proc call*(call_600018: Call_GetChangeMessageVisibility_600001;
          ReceiptHandle: string; QueueName: string; AccountNumber: int;
          VisibilityTimeout: int; Action: string = "ChangeMessageVisibility";
          Version: string = "2012-11-05"): Recallable =
  ## getChangeMessageVisibility
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  ##   VisibilityTimeout: int (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  var path_600019 = newJObject()
  var query_600020 = newJObject()
  add(query_600020, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_600019, "QueueName", newJString(QueueName))
  add(query_600020, "Action", newJString(Action))
  add(path_600019, "AccountNumber", newJInt(AccountNumber))
  add(query_600020, "Version", newJString(Version))
  add(query_600020, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_600018.call(path_600019, query_600020, nil, nil, nil)

var getChangeMessageVisibility* = Call_GetChangeMessageVisibility_600001(
    name: "getChangeMessageVisibility", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_GetChangeMessageVisibility_600002, base: "/",
    url: url_GetChangeMessageVisibility_600003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibilityBatch_600061 = ref object of OpenApiRestCall_599352
proc url_PostChangeMessageVisibilityBatch_600063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ChangeMessageVisibilityBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostChangeMessageVisibilityBatch_600062(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600064 = path.getOrDefault("QueueName")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "QueueName", valid_600064
  var valid_600065 = path.getOrDefault("AccountNumber")
  valid_600065 = validateParameter(valid_600065, JInt, required = true, default = nil)
  if valid_600065 != nil:
    section.add "AccountNumber", valid_600065
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600066 = query.getOrDefault("Action")
  valid_600066 = validateParameter(valid_600066, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_600066 != nil:
    section.add "Action", valid_600066
  var valid_600067 = query.getOrDefault("Version")
  valid_600067 = validateParameter(valid_600067, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600067 != nil:
    section.add "Version", valid_600067
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
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_600075 = formData.getOrDefault("Entries")
  valid_600075 = validateParameter(valid_600075, JArray, required = true, default = nil)
  if valid_600075 != nil:
    section.add "Entries", valid_600075
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_PostChangeMessageVisibilityBatch_600061;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_PostChangeMessageVisibilityBatch_600061;
          Entries: JsonNode; QueueName: string; AccountNumber: int;
          Action: string = "ChangeMessageVisibilityBatch";
          Version: string = "2012-11-05"): Recallable =
  ## postChangeMessageVisibilityBatch
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600078 = newJObject()
  var query_600079 = newJObject()
  var formData_600080 = newJObject()
  if Entries != nil:
    formData_600080.add "Entries", Entries
  add(path_600078, "QueueName", newJString(QueueName))
  add(query_600079, "Action", newJString(Action))
  add(path_600078, "AccountNumber", newJInt(AccountNumber))
  add(query_600079, "Version", newJString(Version))
  result = call_600077.call(path_600078, query_600079, nil, formData_600080, nil)

var postChangeMessageVisibilityBatch* = Call_PostChangeMessageVisibilityBatch_600061(
    name: "postChangeMessageVisibilityBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_PostChangeMessageVisibilityBatch_600062, base: "/",
    url: url_PostChangeMessageVisibilityBatch_600063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibilityBatch_600042 = ref object of OpenApiRestCall_599352
proc url_GetChangeMessageVisibilityBatch_600044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ChangeMessageVisibilityBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChangeMessageVisibilityBatch_600043(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600045 = path.getOrDefault("QueueName")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "QueueName", valid_600045
  var valid_600046 = path.getOrDefault("AccountNumber")
  valid_600046 = validateParameter(valid_600046, JInt, required = true, default = nil)
  if valid_600046 != nil:
    section.add "AccountNumber", valid_600046
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_600047 = query.getOrDefault("Entries")
  valid_600047 = validateParameter(valid_600047, JArray, required = true, default = nil)
  if valid_600047 != nil:
    section.add "Entries", valid_600047
  var valid_600048 = query.getOrDefault("Action")
  valid_600048 = validateParameter(valid_600048, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_600048 != nil:
    section.add "Action", valid_600048
  var valid_600049 = query.getOrDefault("Version")
  valid_600049 = validateParameter(valid_600049, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600049 != nil:
    section.add "Version", valid_600049
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
  var valid_600050 = header.getOrDefault("X-Amz-Date")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Date", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Security-Token")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Security-Token", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Content-Sha256", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Algorithm")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Algorithm", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Signature")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Signature", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-SignedHeaders", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Credential")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Credential", valid_600056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600057: Call_GetChangeMessageVisibilityBatch_600042;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600057.validator(path, query, header, formData, body)
  let scheme = call_600057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600057.url(scheme.get, call_600057.host, call_600057.base,
                         call_600057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600057, url, valid)

proc call*(call_600058: Call_GetChangeMessageVisibilityBatch_600042;
          QueueName: string; Entries: JsonNode; AccountNumber: int;
          Action: string = "ChangeMessageVisibilityBatch";
          Version: string = "2012-11-05"): Recallable =
  ## getChangeMessageVisibilityBatch
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600059 = newJObject()
  var query_600060 = newJObject()
  add(path_600059, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_600060.add "Entries", Entries
  add(query_600060, "Action", newJString(Action))
  add(path_600059, "AccountNumber", newJInt(AccountNumber))
  add(query_600060, "Version", newJString(Version))
  result = call_600058.call(path_600059, query_600060, nil, nil, nil)

var getChangeMessageVisibilityBatch* = Call_GetChangeMessageVisibilityBatch_600042(
    name: "getChangeMessageVisibilityBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_GetChangeMessageVisibilityBatch_600043, base: "/",
    url: url_GetChangeMessageVisibilityBatch_600044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateQueue_600109 = ref object of OpenApiRestCall_599352
proc url_PostCreateQueue_600111(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateQueue_600110(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600112 = query.getOrDefault("Action")
  valid_600112 = validateParameter(valid_600112, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_600112 != nil:
    section.add "Action", valid_600112
  var valid_600113 = query.getOrDefault("Version")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600113 != nil:
    section.add "Version", valid_600113
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
  var valid_600114 = header.getOrDefault("X-Amz-Date")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Date", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Security-Token")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Security-Token", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Content-Sha256", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Algorithm")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Algorithm", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Signature")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Signature", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-SignedHeaders", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Credential")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Credential", valid_600120
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tag.1.value: JString
  ##   Attribute.0.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.value: JString
  ##   Tag.0.key: JString
  ##   QueueName: JString (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute.1.key: JString
  ##   Tag.1.key: JString
  ##   Tag.0.value: JString
  ##   Tag.2.key: JString
  ##   Tag.2.value: JString
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  section = newJObject()
  var valid_600121 = formData.getOrDefault("Tag.1.value")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "Tag.1.value", valid_600121
  var valid_600122 = formData.getOrDefault("Attribute.0.key")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "Attribute.0.key", valid_600122
  var valid_600123 = formData.getOrDefault("Attribute.0.value")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "Attribute.0.value", valid_600123
  var valid_600124 = formData.getOrDefault("Attribute.1.value")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "Attribute.1.value", valid_600124
  var valid_600125 = formData.getOrDefault("Tag.0.key")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "Tag.0.key", valid_600125
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_600126 = formData.getOrDefault("QueueName")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = nil)
  if valid_600126 != nil:
    section.add "QueueName", valid_600126
  var valid_600127 = formData.getOrDefault("Attribute.1.key")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "Attribute.1.key", valid_600127
  var valid_600128 = formData.getOrDefault("Tag.1.key")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "Tag.1.key", valid_600128
  var valid_600129 = formData.getOrDefault("Tag.0.value")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "Tag.0.value", valid_600129
  var valid_600130 = formData.getOrDefault("Tag.2.key")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "Tag.2.key", valid_600130
  var valid_600131 = formData.getOrDefault("Tag.2.value")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "Tag.2.value", valid_600131
  var valid_600132 = formData.getOrDefault("Attribute.2.value")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "Attribute.2.value", valid_600132
  var valid_600133 = formData.getOrDefault("Attribute.2.key")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "Attribute.2.key", valid_600133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600134: Call_PostCreateQueue_600109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600134.validator(path, query, header, formData, body)
  let scheme = call_600134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600134.url(scheme.get, call_600134.host, call_600134.base,
                         call_600134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600134, url, valid)

proc call*(call_600135: Call_PostCreateQueue_600109; QueueName: string;
          Tag1Value: string = ""; Attribute0Key: string = "";
          Attribute0Value: string = ""; Attribute1Value: string = "";
          Tag0Key: string = ""; Action: string = "CreateQueue";
          Attribute1Key: string = ""; Tag1Key: string = ""; Tag0Value: string = "";
          Tag2Key: string = ""; Tag2Value: string = ""; Attribute2Value: string = "";
          Version: string = "2012-11-05"; Attribute2Key: string = ""): Recallable =
  ## postCreateQueue
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Tag1Value: string
  ##   Attribute0Key: string
  ##   Attribute0Value: string
  ##   Attribute1Value: string
  ##   Tag0Key: string
  ##   Action: string (required)
  ##   QueueName: string (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute1Key: string
  ##   Tag1Key: string
  ##   Tag0Value: string
  ##   Tag2Key: string
  ##   Tag2Value: string
  ##   Attribute2Value: string
  ##   Version: string (required)
  ##   Attribute2Key: string
  var query_600136 = newJObject()
  var formData_600137 = newJObject()
  add(formData_600137, "Tag.1.value", newJString(Tag1Value))
  add(formData_600137, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_600137, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_600137, "Attribute.1.value", newJString(Attribute1Value))
  add(formData_600137, "Tag.0.key", newJString(Tag0Key))
  add(query_600136, "Action", newJString(Action))
  add(formData_600137, "QueueName", newJString(QueueName))
  add(formData_600137, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_600137, "Tag.1.key", newJString(Tag1Key))
  add(formData_600137, "Tag.0.value", newJString(Tag0Value))
  add(formData_600137, "Tag.2.key", newJString(Tag2Key))
  add(formData_600137, "Tag.2.value", newJString(Tag2Value))
  add(formData_600137, "Attribute.2.value", newJString(Attribute2Value))
  add(query_600136, "Version", newJString(Version))
  add(formData_600137, "Attribute.2.key", newJString(Attribute2Key))
  result = call_600135.call(nil, query_600136, nil, formData_600137, nil)

var postCreateQueue* = Call_PostCreateQueue_600109(name: "postCreateQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_PostCreateQueue_600110,
    base: "/", url: url_PostCreateQueue_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateQueue_600081 = ref object of OpenApiRestCall_599352
proc url_GetCreateQueue_600083(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateQueue_600082(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attribute.2.value: JString
  ##   Tag.0.value: JString
  ##   Tag.2.value: JString
  ##   Attribute.0.key: JString
  ##   Tag.1.value: JString
  ##   Tag.2.key: JString
  ##   Attribute.1.value: JString
  ##   Attribute.1.key: JString
  ##   Tag.0.key: JString
  ##   Action: JString (required)
  ##   Attribute.2.key: JString
  ##   Tag.1.key: JString
  ##   QueueName: JString (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute.0.value: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_600084 = query.getOrDefault("Attribute.2.value")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "Attribute.2.value", valid_600084
  var valid_600085 = query.getOrDefault("Tag.0.value")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "Tag.0.value", valid_600085
  var valid_600086 = query.getOrDefault("Tag.2.value")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "Tag.2.value", valid_600086
  var valid_600087 = query.getOrDefault("Attribute.0.key")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "Attribute.0.key", valid_600087
  var valid_600088 = query.getOrDefault("Tag.1.value")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "Tag.1.value", valid_600088
  var valid_600089 = query.getOrDefault("Tag.2.key")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "Tag.2.key", valid_600089
  var valid_600090 = query.getOrDefault("Attribute.1.value")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "Attribute.1.value", valid_600090
  var valid_600091 = query.getOrDefault("Attribute.1.key")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "Attribute.1.key", valid_600091
  var valid_600092 = query.getOrDefault("Tag.0.key")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "Tag.0.key", valid_600092
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600093 = query.getOrDefault("Action")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_600093 != nil:
    section.add "Action", valid_600093
  var valid_600094 = query.getOrDefault("Attribute.2.key")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "Attribute.2.key", valid_600094
  var valid_600095 = query.getOrDefault("Tag.1.key")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "Tag.1.key", valid_600095
  var valid_600096 = query.getOrDefault("QueueName")
  valid_600096 = validateParameter(valid_600096, JString, required = true,
                                 default = nil)
  if valid_600096 != nil:
    section.add "QueueName", valid_600096
  var valid_600097 = query.getOrDefault("Attribute.0.value")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "Attribute.0.value", valid_600097
  var valid_600098 = query.getOrDefault("Version")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600098 != nil:
    section.add "Version", valid_600098
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
  var valid_600099 = header.getOrDefault("X-Amz-Date")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Date", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Security-Token")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Security-Token", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Content-Sha256", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Algorithm")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Algorithm", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Signature")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Signature", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-SignedHeaders", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Credential")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Credential", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_GetCreateQueue_600081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_GetCreateQueue_600081; QueueName: string;
          Attribute2Value: string = ""; Tag0Value: string = ""; Tag2Value: string = "";
          Attribute0Key: string = ""; Tag1Value: string = ""; Tag2Key: string = "";
          Attribute1Value: string = ""; Attribute1Key: string = "";
          Tag0Key: string = ""; Action: string = "CreateQueue";
          Attribute2Key: string = ""; Tag1Key: string = "";
          Attribute0Value: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getCreateQueue
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Attribute2Value: string
  ##   Tag0Value: string
  ##   Tag2Value: string
  ##   Attribute0Key: string
  ##   Tag1Value: string
  ##   Tag2Key: string
  ##   Attribute1Value: string
  ##   Attribute1Key: string
  ##   Tag0Key: string
  ##   Action: string (required)
  ##   Attribute2Key: string
  ##   Tag1Key: string
  ##   QueueName: string (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute0Value: string
  ##   Version: string (required)
  var query_600108 = newJObject()
  add(query_600108, "Attribute.2.value", newJString(Attribute2Value))
  add(query_600108, "Tag.0.value", newJString(Tag0Value))
  add(query_600108, "Tag.2.value", newJString(Tag2Value))
  add(query_600108, "Attribute.0.key", newJString(Attribute0Key))
  add(query_600108, "Tag.1.value", newJString(Tag1Value))
  add(query_600108, "Tag.2.key", newJString(Tag2Key))
  add(query_600108, "Attribute.1.value", newJString(Attribute1Value))
  add(query_600108, "Attribute.1.key", newJString(Attribute1Key))
  add(query_600108, "Tag.0.key", newJString(Tag0Key))
  add(query_600108, "Action", newJString(Action))
  add(query_600108, "Attribute.2.key", newJString(Attribute2Key))
  add(query_600108, "Tag.1.key", newJString(Tag1Key))
  add(query_600108, "QueueName", newJString(QueueName))
  add(query_600108, "Attribute.0.value", newJString(Attribute0Value))
  add(query_600108, "Version", newJString(Version))
  result = call_600107.call(nil, query_600108, nil, nil, nil)

var getCreateQueue* = Call_GetCreateQueue_600081(name: "getCreateQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_GetCreateQueue_600082,
    base: "/", url: url_GetCreateQueue_600083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessage_600157 = ref object of OpenApiRestCall_599352
proc url_PostDeleteMessage_600159(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostDeleteMessage_600158(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600160 = path.getOrDefault("QueueName")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "QueueName", valid_600160
  var valid_600161 = path.getOrDefault("AccountNumber")
  valid_600161 = validateParameter(valid_600161, JInt, required = true, default = nil)
  if valid_600161 != nil:
    section.add "AccountNumber", valid_600161
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600162 = query.getOrDefault("Action")
  valid_600162 = validateParameter(valid_600162, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_600162 != nil:
    section.add "Action", valid_600162
  var valid_600163 = query.getOrDefault("Version")
  valid_600163 = validateParameter(valid_600163, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600163 != nil:
    section.add "Version", valid_600163
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
  var valid_600164 = header.getOrDefault("X-Amz-Date")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Date", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Security-Token")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Security-Token", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Content-Sha256", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Algorithm")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Algorithm", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Signature")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Signature", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-SignedHeaders", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Credential")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Credential", valid_600170
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_600171 = formData.getOrDefault("ReceiptHandle")
  valid_600171 = validateParameter(valid_600171, JString, required = true,
                                 default = nil)
  if valid_600171 != nil:
    section.add "ReceiptHandle", valid_600171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_PostDeleteMessage_600157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_PostDeleteMessage_600157; QueueName: string;
          AccountNumber: int; ReceiptHandle: string;
          Action: string = "DeleteMessage"; Version: string = "2012-11-05"): Recallable =
  ## postDeleteMessage
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Version: string (required)
  var path_600174 = newJObject()
  var query_600175 = newJObject()
  var formData_600176 = newJObject()
  add(path_600174, "QueueName", newJString(QueueName))
  add(query_600175, "Action", newJString(Action))
  add(path_600174, "AccountNumber", newJInt(AccountNumber))
  add(formData_600176, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_600175, "Version", newJString(Version))
  result = call_600173.call(path_600174, query_600175, nil, formData_600176, nil)

var postDeleteMessage* = Call_PostDeleteMessage_600157(name: "postDeleteMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_PostDeleteMessage_600158, base: "/",
    url: url_PostDeleteMessage_600159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessage_600138 = ref object of OpenApiRestCall_599352
proc url_GetDeleteMessage_600140(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeleteMessage_600139(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600141 = path.getOrDefault("QueueName")
  valid_600141 = validateParameter(valid_600141, JString, required = true,
                                 default = nil)
  if valid_600141 != nil:
    section.add "QueueName", valid_600141
  var valid_600142 = path.getOrDefault("AccountNumber")
  valid_600142 = validateParameter(valid_600142, JInt, required = true, default = nil)
  if valid_600142 != nil:
    section.add "AccountNumber", valid_600142
  result.add "path", section
  ## parameters in `query` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ReceiptHandle` field"
  var valid_600143 = query.getOrDefault("ReceiptHandle")
  valid_600143 = validateParameter(valid_600143, JString, required = true,
                                 default = nil)
  if valid_600143 != nil:
    section.add "ReceiptHandle", valid_600143
  var valid_600144 = query.getOrDefault("Action")
  valid_600144 = validateParameter(valid_600144, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_600144 != nil:
    section.add "Action", valid_600144
  var valid_600145 = query.getOrDefault("Version")
  valid_600145 = validateParameter(valid_600145, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600145 != nil:
    section.add "Version", valid_600145
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
  var valid_600146 = header.getOrDefault("X-Amz-Date")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Date", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Security-Token")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Security-Token", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Content-Sha256", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Algorithm")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Algorithm", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Signature")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Signature", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-SignedHeaders", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Credential")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Credential", valid_600152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600153: Call_GetDeleteMessage_600138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_600153.validator(path, query, header, formData, body)
  let scheme = call_600153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600153.url(scheme.get, call_600153.host, call_600153.base,
                         call_600153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600153, url, valid)

proc call*(call_600154: Call_GetDeleteMessage_600138; ReceiptHandle: string;
          QueueName: string; AccountNumber: int; Action: string = "DeleteMessage";
          Version: string = "2012-11-05"): Recallable =
  ## getDeleteMessage
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message to delete.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600155 = newJObject()
  var query_600156 = newJObject()
  add(query_600156, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_600155, "QueueName", newJString(QueueName))
  add(query_600156, "Action", newJString(Action))
  add(path_600155, "AccountNumber", newJInt(AccountNumber))
  add(query_600156, "Version", newJString(Version))
  result = call_600154.call(path_600155, query_600156, nil, nil, nil)

var getDeleteMessage* = Call_GetDeleteMessage_600138(name: "getDeleteMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_GetDeleteMessage_600139, base: "/",
    url: url_GetDeleteMessage_600140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessageBatch_600196 = ref object of OpenApiRestCall_599352
proc url_PostDeleteMessageBatch_600198(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteMessageBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostDeleteMessageBatch_600197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600199 = path.getOrDefault("QueueName")
  valid_600199 = validateParameter(valid_600199, JString, required = true,
                                 default = nil)
  if valid_600199 != nil:
    section.add "QueueName", valid_600199
  var valid_600200 = path.getOrDefault("AccountNumber")
  valid_600200 = validateParameter(valid_600200, JInt, required = true, default = nil)
  if valid_600200 != nil:
    section.add "AccountNumber", valid_600200
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600201 = query.getOrDefault("Action")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_600201 != nil:
    section.add "Action", valid_600201
  var valid_600202 = query.getOrDefault("Version")
  valid_600202 = validateParameter(valid_600202, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600202 != nil:
    section.add "Version", valid_600202
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
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_600210 = formData.getOrDefault("Entries")
  valid_600210 = validateParameter(valid_600210, JArray, required = true, default = nil)
  if valid_600210 != nil:
    section.add "Entries", valid_600210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_PostDeleteMessageBatch_600196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_PostDeleteMessageBatch_600196; Entries: JsonNode;
          QueueName: string; AccountNumber: int;
          Action: string = "DeleteMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## postDeleteMessageBatch
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600213 = newJObject()
  var query_600214 = newJObject()
  var formData_600215 = newJObject()
  if Entries != nil:
    formData_600215.add "Entries", Entries
  add(path_600213, "QueueName", newJString(QueueName))
  add(query_600214, "Action", newJString(Action))
  add(path_600213, "AccountNumber", newJInt(AccountNumber))
  add(query_600214, "Version", newJString(Version))
  result = call_600212.call(path_600213, query_600214, nil, formData_600215, nil)

var postDeleteMessageBatch* = Call_PostDeleteMessageBatch_600196(
    name: "postDeleteMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_PostDeleteMessageBatch_600197, base: "/",
    url: url_PostDeleteMessageBatch_600198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessageBatch_600177 = ref object of OpenApiRestCall_599352
proc url_GetDeleteMessageBatch_600179(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteMessageBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeleteMessageBatch_600178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600180 = path.getOrDefault("QueueName")
  valid_600180 = validateParameter(valid_600180, JString, required = true,
                                 default = nil)
  if valid_600180 != nil:
    section.add "QueueName", valid_600180
  var valid_600181 = path.getOrDefault("AccountNumber")
  valid_600181 = validateParameter(valid_600181, JInt, required = true, default = nil)
  if valid_600181 != nil:
    section.add "AccountNumber", valid_600181
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_600182 = query.getOrDefault("Entries")
  valid_600182 = validateParameter(valid_600182, JArray, required = true, default = nil)
  if valid_600182 != nil:
    section.add "Entries", valid_600182
  var valid_600183 = query.getOrDefault("Action")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_600183 != nil:
    section.add "Action", valid_600183
  var valid_600184 = query.getOrDefault("Version")
  valid_600184 = validateParameter(valid_600184, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600184 != nil:
    section.add "Version", valid_600184
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
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Content-Sha256", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Algorithm")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Algorithm", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Signature")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Signature", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-SignedHeaders", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Credential")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Credential", valid_600191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600192: Call_GetDeleteMessageBatch_600177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600192.validator(path, query, header, formData, body)
  let scheme = call_600192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600192.url(scheme.get, call_600192.host, call_600192.base,
                         call_600192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600192, url, valid)

proc call*(call_600193: Call_GetDeleteMessageBatch_600177; QueueName: string;
          Entries: JsonNode; AccountNumber: int;
          Action: string = "DeleteMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## getDeleteMessageBatch
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600194 = newJObject()
  var query_600195 = newJObject()
  add(path_600194, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_600195.add "Entries", Entries
  add(query_600195, "Action", newJString(Action))
  add(path_600194, "AccountNumber", newJInt(AccountNumber))
  add(query_600195, "Version", newJString(Version))
  result = call_600193.call(path_600194, query_600195, nil, nil, nil)

var getDeleteMessageBatch* = Call_GetDeleteMessageBatch_600177(
    name: "getDeleteMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_GetDeleteMessageBatch_600178, base: "/",
    url: url_GetDeleteMessageBatch_600179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteQueue_600234 = ref object of OpenApiRestCall_599352
proc url_PostDeleteQueue_600236(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostDeleteQueue_600235(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600237 = path.getOrDefault("QueueName")
  valid_600237 = validateParameter(valid_600237, JString, required = true,
                                 default = nil)
  if valid_600237 != nil:
    section.add "QueueName", valid_600237
  var valid_600238 = path.getOrDefault("AccountNumber")
  valid_600238 = validateParameter(valid_600238, JInt, required = true, default = nil)
  if valid_600238 != nil:
    section.add "AccountNumber", valid_600238
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600239 = query.getOrDefault("Action")
  valid_600239 = validateParameter(valid_600239, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_600239 != nil:
    section.add "Action", valid_600239
  var valid_600240 = query.getOrDefault("Version")
  valid_600240 = validateParameter(valid_600240, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600240 != nil:
    section.add "Version", valid_600240
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
  var valid_600241 = header.getOrDefault("X-Amz-Date")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Date", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Security-Token")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Security-Token", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Content-Sha256", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Algorithm")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Algorithm", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Signature")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Signature", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-SignedHeaders", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Credential")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Credential", valid_600247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600248: Call_PostDeleteQueue_600234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600248.validator(path, query, header, formData, body)
  let scheme = call_600248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600248.url(scheme.get, call_600248.host, call_600248.base,
                         call_600248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600248, url, valid)

proc call*(call_600249: Call_PostDeleteQueue_600234; QueueName: string;
          AccountNumber: int; Action: string = "DeleteQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postDeleteQueue
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600250 = newJObject()
  var query_600251 = newJObject()
  add(path_600250, "QueueName", newJString(QueueName))
  add(query_600251, "Action", newJString(Action))
  add(path_600250, "AccountNumber", newJInt(AccountNumber))
  add(query_600251, "Version", newJString(Version))
  result = call_600249.call(path_600250, query_600251, nil, nil, nil)

var postDeleteQueue* = Call_PostDeleteQueue_600234(name: "postDeleteQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_PostDeleteQueue_600235, base: "/", url: url_PostDeleteQueue_600236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteQueue_600216 = ref object of OpenApiRestCall_599352
proc url_GetDeleteQueue_600218(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=DeleteQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeleteQueue_600217(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600219 = path.getOrDefault("QueueName")
  valid_600219 = validateParameter(valid_600219, JString, required = true,
                                 default = nil)
  if valid_600219 != nil:
    section.add "QueueName", valid_600219
  var valid_600220 = path.getOrDefault("AccountNumber")
  valid_600220 = validateParameter(valid_600220, JInt, required = true, default = nil)
  if valid_600220 != nil:
    section.add "AccountNumber", valid_600220
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600221 = query.getOrDefault("Action")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_600221 != nil:
    section.add "Action", valid_600221
  var valid_600222 = query.getOrDefault("Version")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600222 != nil:
    section.add "Version", valid_600222
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
  var valid_600223 = header.getOrDefault("X-Amz-Date")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Date", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Security-Token")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Security-Token", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Content-Sha256", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Algorithm")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Algorithm", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Signature")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Signature", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-SignedHeaders", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Credential")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Credential", valid_600229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600230: Call_GetDeleteQueue_600216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600230.validator(path, query, header, formData, body)
  let scheme = call_600230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600230.url(scheme.get, call_600230.host, call_600230.base,
                         call_600230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600230, url, valid)

proc call*(call_600231: Call_GetDeleteQueue_600216; QueueName: string;
          AccountNumber: int; Action: string = "DeleteQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getDeleteQueue
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600232 = newJObject()
  var query_600233 = newJObject()
  add(path_600232, "QueueName", newJString(QueueName))
  add(query_600233, "Action", newJString(Action))
  add(path_600232, "AccountNumber", newJInt(AccountNumber))
  add(query_600233, "Version", newJString(Version))
  result = call_600231.call(path_600232, query_600233, nil, nil, nil)

var getDeleteQueue* = Call_GetDeleteQueue_600216(name: "getDeleteQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_GetDeleteQueue_600217, base: "/", url: url_GetDeleteQueue_600218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueAttributes_600271 = ref object of OpenApiRestCall_599352
proc url_PostGetQueueAttributes_600273(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=GetQueueAttributes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostGetQueueAttributes_600272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600274 = path.getOrDefault("QueueName")
  valid_600274 = validateParameter(valid_600274, JString, required = true,
                                 default = nil)
  if valid_600274 != nil:
    section.add "QueueName", valid_600274
  var valid_600275 = path.getOrDefault("AccountNumber")
  valid_600275 = validateParameter(valid_600275, JInt, required = true, default = nil)
  if valid_600275 != nil:
    section.add "AccountNumber", valid_600275
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600276 = query.getOrDefault("Action")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_600276 != nil:
    section.add "Action", valid_600276
  var valid_600277 = query.getOrDefault("Version")
  valid_600277 = validateParameter(valid_600277, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600277 != nil:
    section.add "Version", valid_600277
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
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes for which to retrieve information.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note> <p>The following attributes are supported:</p> <ul> <li> <p> <code>All</code> - Returns all values. </p> </li> <li> <p> <code>ApproximateNumberOfMessages</code> - Returns the approximate number of messages available for retrieval from the queue.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesDelayed</code> - Returns the approximate number of messages in the queue that are delayed and not available for reading immediately. This can happen when the queue is configured as a delay queue or when a message has been sent with a delay parameter.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesNotVisible</code> - Returns the approximate number of messages that are in flight. Messages are considered to be <i>in flight</i> if they have been sent to a client but have not yet been deleted or have not yet reached the end of their visibility window. </p> </li> <li> <p> <code>CreatedTimestamp</code> - Returns the time when the queue was created in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>DelaySeconds</code> - Returns the default delay on the queue in seconds.</p> </li> <li> <p> <code>LastModifiedTimestamp</code> - Returns the time when the queue was last changed in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>MaximumMessageSize</code> - Returns the limit of how many bytes a message can contain before Amazon SQS rejects it.</p> </li> <li> <p> <code>MessageRetentionPeriod</code> - Returns the length of time, in seconds, for which Amazon SQS retains a message.</p> </li> <li> <p> <code>Policy</code> - Returns the policy of the queue.</p> </li> <li> <p> <code>QueueArn</code> - Returns the Amazon resource name (ARN) of the queue.</p> </li> <li> <p> <code>ReceiveMessageWaitTimeSeconds</code> - Returns the length of time, in seconds, for which the <code>ReceiveMessage</code> action waits for a message to arrive. </p> </li> <li> <p> <code>RedrivePolicy</code> - Returns the string that includes the parameters for dead-letter queue functionality of the source queue. For more information about the redrive policy and dead-letter queues, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <ul> <li> <p> <code>deadLetterTargetArn</code> - The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of <code>maxReceiveCount</code> is exceeded.</p> </li> <li> <p> <code>maxReceiveCount</code> - The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the <code>ReceiveCount</code> for a message exceeds the <code>maxReceiveCount</code> for a queue, Amazon SQS moves the message to the dead-letter-queue.</p> </li> </ul> </li> <li> <p> <code>VisibilityTimeout</code> - Returns the visibility timeout for the queue. For more information about the visibility timeout, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - Returns the ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms">Key Terms</a>. </p> </li> <li> <p> <code>KmsDataKeyReusePeriodSeconds</code> - Returns the length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work">How Does the Data Key Reuse Period Work?</a>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO (first-in-first-out) queues</a>:</p> <ul> <li> <p> <code>FifoQueue</code> - Returns whether the queue is FIFO. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-understanding-logic">FIFO Queue Logic</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>To determine whether a queue is <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> </li> <li> <p> <code>ContentBasedDeduplication</code> - Returns whether content-based deduplication is enabled for the queue. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing">Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul>
  section = newJObject()
  var valid_600285 = formData.getOrDefault("AttributeNames")
  valid_600285 = validateParameter(valid_600285, JArray, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "AttributeNames", valid_600285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_PostGetQueueAttributes_600271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_PostGetQueueAttributes_600271; QueueName: string;
          AccountNumber: int; Action: string = "GetQueueAttributes";
          AttributeNames: JsonNode = nil; Version: string = "2012-11-05"): Recallable =
  ## postGetQueueAttributes
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes for which to retrieve information.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note> <p>The following attributes are supported:</p> <ul> <li> <p> <code>All</code> - Returns all values. </p> </li> <li> <p> <code>ApproximateNumberOfMessages</code> - Returns the approximate number of messages available for retrieval from the queue.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesDelayed</code> - Returns the approximate number of messages in the queue that are delayed and not available for reading immediately. This can happen when the queue is configured as a delay queue or when a message has been sent with a delay parameter.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesNotVisible</code> - Returns the approximate number of messages that are in flight. Messages are considered to be <i>in flight</i> if they have been sent to a client but have not yet been deleted or have not yet reached the end of their visibility window. </p> </li> <li> <p> <code>CreatedTimestamp</code> - Returns the time when the queue was created in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>DelaySeconds</code> - Returns the default delay on the queue in seconds.</p> </li> <li> <p> <code>LastModifiedTimestamp</code> - Returns the time when the queue was last changed in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>MaximumMessageSize</code> - Returns the limit of how many bytes a message can contain before Amazon SQS rejects it.</p> </li> <li> <p> <code>MessageRetentionPeriod</code> - Returns the length of time, in seconds, for which Amazon SQS retains a message.</p> </li> <li> <p> <code>Policy</code> - Returns the policy of the queue.</p> </li> <li> <p> <code>QueueArn</code> - Returns the Amazon resource name (ARN) of the queue.</p> </li> <li> <p> <code>ReceiveMessageWaitTimeSeconds</code> - Returns the length of time, in seconds, for which the <code>ReceiveMessage</code> action waits for a message to arrive. </p> </li> <li> <p> <code>RedrivePolicy</code> - Returns the string that includes the parameters for dead-letter queue functionality of the source queue. For more information about the redrive policy and dead-letter queues, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <ul> <li> <p> <code>deadLetterTargetArn</code> - The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of <code>maxReceiveCount</code> is exceeded.</p> </li> <li> <p> <code>maxReceiveCount</code> - The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the <code>ReceiveCount</code> for a message exceeds the <code>maxReceiveCount</code> for a queue, Amazon SQS moves the message to the dead-letter-queue.</p> </li> </ul> </li> <li> <p> <code>VisibilityTimeout</code> - Returns the visibility timeout for the queue. For more information about the visibility timeout, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - Returns the ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms">Key Terms</a>. </p> </li> <li> <p> <code>KmsDataKeyReusePeriodSeconds</code> - Returns the length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work">How Does the Data Key Reuse Period Work?</a>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO (first-in-first-out) queues</a>:</p> <ul> <li> <p> <code>FifoQueue</code> - Returns whether the queue is FIFO. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-understanding-logic">FIFO Queue Logic</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>To determine whether a queue is <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> </li> <li> <p> <code>ContentBasedDeduplication</code> - Returns whether content-based deduplication is enabled for the queue. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing">Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul>
  ##   Version: string (required)
  var path_600288 = newJObject()
  var query_600289 = newJObject()
  var formData_600290 = newJObject()
  add(path_600288, "QueueName", newJString(QueueName))
  add(query_600289, "Action", newJString(Action))
  add(path_600288, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_600290.add "AttributeNames", AttributeNames
  add(query_600289, "Version", newJString(Version))
  result = call_600287.call(path_600288, query_600289, nil, formData_600290, nil)

var postGetQueueAttributes* = Call_PostGetQueueAttributes_600271(
    name: "postGetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_PostGetQueueAttributes_600272, base: "/",
    url: url_PostGetQueueAttributes_600273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueAttributes_600252 = ref object of OpenApiRestCall_599352
proc url_GetGetQueueAttributes_600254(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=GetQueueAttributes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGetQueueAttributes_600253(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600255 = path.getOrDefault("QueueName")
  valid_600255 = validateParameter(valid_600255, JString, required = true,
                                 default = nil)
  if valid_600255 != nil:
    section.add "QueueName", valid_600255
  var valid_600256 = path.getOrDefault("AccountNumber")
  valid_600256 = validateParameter(valid_600256, JInt, required = true, default = nil)
  if valid_600256 != nil:
    section.add "AccountNumber", valid_600256
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes for which to retrieve information.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note> <p>The following attributes are supported:</p> <ul> <li> <p> <code>All</code> - Returns all values. </p> </li> <li> <p> <code>ApproximateNumberOfMessages</code> - Returns the approximate number of messages available for retrieval from the queue.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesDelayed</code> - Returns the approximate number of messages in the queue that are delayed and not available for reading immediately. This can happen when the queue is configured as a delay queue or when a message has been sent with a delay parameter.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesNotVisible</code> - Returns the approximate number of messages that are in flight. Messages are considered to be <i>in flight</i> if they have been sent to a client but have not yet been deleted or have not yet reached the end of their visibility window. </p> </li> <li> <p> <code>CreatedTimestamp</code> - Returns the time when the queue was created in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>DelaySeconds</code> - Returns the default delay on the queue in seconds.</p> </li> <li> <p> <code>LastModifiedTimestamp</code> - Returns the time when the queue was last changed in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>MaximumMessageSize</code> - Returns the limit of how many bytes a message can contain before Amazon SQS rejects it.</p> </li> <li> <p> <code>MessageRetentionPeriod</code> - Returns the length of time, in seconds, for which Amazon SQS retains a message.</p> </li> <li> <p> <code>Policy</code> - Returns the policy of the queue.</p> </li> <li> <p> <code>QueueArn</code> - Returns the Amazon resource name (ARN) of the queue.</p> </li> <li> <p> <code>ReceiveMessageWaitTimeSeconds</code> - Returns the length of time, in seconds, for which the <code>ReceiveMessage</code> action waits for a message to arrive. </p> </li> <li> <p> <code>RedrivePolicy</code> - Returns the string that includes the parameters for dead-letter queue functionality of the source queue. For more information about the redrive policy and dead-letter queues, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <ul> <li> <p> <code>deadLetterTargetArn</code> - The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of <code>maxReceiveCount</code> is exceeded.</p> </li> <li> <p> <code>maxReceiveCount</code> - The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the <code>ReceiveCount</code> for a message exceeds the <code>maxReceiveCount</code> for a queue, Amazon SQS moves the message to the dead-letter-queue.</p> </li> </ul> </li> <li> <p> <code>VisibilityTimeout</code> - Returns the visibility timeout for the queue. For more information about the visibility timeout, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - Returns the ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms">Key Terms</a>. </p> </li> <li> <p> <code>KmsDataKeyReusePeriodSeconds</code> - Returns the length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work">How Does the Data Key Reuse Period Work?</a>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO (first-in-first-out) queues</a>:</p> <ul> <li> <p> <code>FifoQueue</code> - Returns whether the queue is FIFO. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-understanding-logic">FIFO Queue Logic</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>To determine whether a queue is <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> </li> <li> <p> <code>ContentBasedDeduplication</code> - Returns whether content-based deduplication is enabled for the queue. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing">Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_600257 = query.getOrDefault("AttributeNames")
  valid_600257 = validateParameter(valid_600257, JArray, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "AttributeNames", valid_600257
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600258 = query.getOrDefault("Action")
  valid_600258 = validateParameter(valid_600258, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_600258 != nil:
    section.add "Action", valid_600258
  var valid_600259 = query.getOrDefault("Version")
  valid_600259 = validateParameter(valid_600259, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600259 != nil:
    section.add "Version", valid_600259
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
  var valid_600260 = header.getOrDefault("X-Amz-Date")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Date", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Security-Token")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Security-Token", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Content-Sha256", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Algorithm")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Algorithm", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Signature")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Signature", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-SignedHeaders", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Credential")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Credential", valid_600266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600267: Call_GetGetQueueAttributes_600252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600267.validator(path, query, header, formData, body)
  let scheme = call_600267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600267.url(scheme.get, call_600267.host, call_600267.base,
                         call_600267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600267, url, valid)

proc call*(call_600268: Call_GetGetQueueAttributes_600252; QueueName: string;
          AccountNumber: int; AttributeNames: JsonNode = nil;
          Action: string = "GetQueueAttributes"; Version: string = "2012-11-05"): Recallable =
  ## getGetQueueAttributes
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes for which to retrieve information.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note> <p>The following attributes are supported:</p> <ul> <li> <p> <code>All</code> - Returns all values. </p> </li> <li> <p> <code>ApproximateNumberOfMessages</code> - Returns the approximate number of messages available for retrieval from the queue.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesDelayed</code> - Returns the approximate number of messages in the queue that are delayed and not available for reading immediately. This can happen when the queue is configured as a delay queue or when a message has been sent with a delay parameter.</p> </li> <li> <p> <code>ApproximateNumberOfMessagesNotVisible</code> - Returns the approximate number of messages that are in flight. Messages are considered to be <i>in flight</i> if they have been sent to a client but have not yet been deleted or have not yet reached the end of their visibility window. </p> </li> <li> <p> <code>CreatedTimestamp</code> - Returns the time when the queue was created in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>DelaySeconds</code> - Returns the default delay on the queue in seconds.</p> </li> <li> <p> <code>LastModifiedTimestamp</code> - Returns the time when the queue was last changed in seconds (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a>).</p> </li> <li> <p> <code>MaximumMessageSize</code> - Returns the limit of how many bytes a message can contain before Amazon SQS rejects it.</p> </li> <li> <p> <code>MessageRetentionPeriod</code> - Returns the length of time, in seconds, for which Amazon SQS retains a message.</p> </li> <li> <p> <code>Policy</code> - Returns the policy of the queue.</p> </li> <li> <p> <code>QueueArn</code> - Returns the Amazon resource name (ARN) of the queue.</p> </li> <li> <p> <code>ReceiveMessageWaitTimeSeconds</code> - Returns the length of time, in seconds, for which the <code>ReceiveMessage</code> action waits for a message to arrive. </p> </li> <li> <p> <code>RedrivePolicy</code> - Returns the string that includes the parameters for dead-letter queue functionality of the source queue. For more information about the redrive policy and dead-letter queues, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <ul> <li> <p> <code>deadLetterTargetArn</code> - The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of <code>maxReceiveCount</code> is exceeded.</p> </li> <li> <p> <code>maxReceiveCount</code> - The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the <code>ReceiveCount</code> for a message exceeds the <code>maxReceiveCount</code> for a queue, Amazon SQS moves the message to the dead-letter-queue.</p> </li> </ul> </li> <li> <p> <code>VisibilityTimeout</code> - Returns the visibility timeout for the queue. For more information about the visibility timeout, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - Returns the ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms">Key Terms</a>. </p> </li> <li> <p> <code>KmsDataKeyReusePeriodSeconds</code> - Returns the length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work">How Does the Data Key Reuse Period Work?</a>. </p> </li> </ul> <p>The following attributes apply only to <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO (first-in-first-out) queues</a>:</p> <ul> <li> <p> <code>FifoQueue</code> - Returns whether the queue is FIFO. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-understanding-logic">FIFO Queue Logic</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>To determine whether a queue is <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> </li> <li> <p> <code>ContentBasedDeduplication</code> - Returns whether content-based deduplication is enabled for the queue. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing">Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </li> </ul>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600269 = newJObject()
  var query_600270 = newJObject()
  if AttributeNames != nil:
    query_600270.add "AttributeNames", AttributeNames
  add(path_600269, "QueueName", newJString(QueueName))
  add(query_600270, "Action", newJString(Action))
  add(path_600269, "AccountNumber", newJInt(AccountNumber))
  add(query_600270, "Version", newJString(Version))
  result = call_600268.call(path_600269, query_600270, nil, nil, nil)

var getGetQueueAttributes* = Call_GetGetQueueAttributes_600252(
    name: "getGetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_GetGetQueueAttributes_600253, base: "/",
    url: url_GetGetQueueAttributes_600254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueUrl_600308 = ref object of OpenApiRestCall_599352
proc url_PostGetQueueUrl_600310(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetQueueUrl_600309(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600311 = query.getOrDefault("Action")
  valid_600311 = validateParameter(valid_600311, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_600311 != nil:
    section.add "Action", valid_600311
  var valid_600312 = query.getOrDefault("Version")
  valid_600312 = validateParameter(valid_600312, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600312 != nil:
    section.add "Version", valid_600312
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
  var valid_600313 = header.getOrDefault("X-Amz-Date")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Date", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Security-Token")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Security-Token", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Content-Sha256", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Algorithm")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Algorithm", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Signature")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Signature", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-SignedHeaders", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Credential")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Credential", valid_600319
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_600320 = formData.getOrDefault("QueueOwnerAWSAccountId")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "QueueOwnerAWSAccountId", valid_600320
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_600321 = formData.getOrDefault("QueueName")
  valid_600321 = validateParameter(valid_600321, JString, required = true,
                                 default = nil)
  if valid_600321 != nil:
    section.add "QueueName", valid_600321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600322: Call_PostGetQueueUrl_600308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_600322.validator(path, query, header, formData, body)
  let scheme = call_600322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600322.url(scheme.get, call_600322.host, call_600322.base,
                         call_600322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600322, url, valid)

proc call*(call_600323: Call_PostGetQueueUrl_600308; QueueName: string;
          QueueOwnerAWSAccountId: string = ""; Action: string = "GetQueueUrl";
          Version: string = "2012-11-05"): Recallable =
  ## postGetQueueUrl
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ##   QueueOwnerAWSAccountId: string
  ##                         : The AWS account ID of the account that created the queue.
  ##   Action: string (required)
  ##   QueueName: string (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_600324 = newJObject()
  var formData_600325 = newJObject()
  add(formData_600325, "QueueOwnerAWSAccountId",
      newJString(QueueOwnerAWSAccountId))
  add(query_600324, "Action", newJString(Action))
  add(formData_600325, "QueueName", newJString(QueueName))
  add(query_600324, "Version", newJString(Version))
  result = call_600323.call(nil, query_600324, nil, formData_600325, nil)

var postGetQueueUrl* = Call_PostGetQueueUrl_600308(name: "postGetQueueUrl",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_PostGetQueueUrl_600309,
    base: "/", url: url_PostGetQueueUrl_600310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueUrl_600291 = ref object of OpenApiRestCall_599352
proc url_GetGetQueueUrl_600293(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetQueueUrl_600292(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600294 = query.getOrDefault("Action")
  valid_600294 = validateParameter(valid_600294, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_600294 != nil:
    section.add "Action", valid_600294
  var valid_600295 = query.getOrDefault("QueueOwnerAWSAccountId")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "QueueOwnerAWSAccountId", valid_600295
  var valid_600296 = query.getOrDefault("QueueName")
  valid_600296 = validateParameter(valid_600296, JString, required = true,
                                 default = nil)
  if valid_600296 != nil:
    section.add "QueueName", valid_600296
  var valid_600297 = query.getOrDefault("Version")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600297 != nil:
    section.add "Version", valid_600297
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
  var valid_600298 = header.getOrDefault("X-Amz-Date")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Date", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Security-Token")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Security-Token", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Content-Sha256", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Algorithm")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Algorithm", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Signature")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Signature", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-SignedHeaders", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Credential")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Credential", valid_600304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600305: Call_GetGetQueueUrl_600291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_600305.validator(path, query, header, formData, body)
  let scheme = call_600305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600305.url(scheme.get, call_600305.host, call_600305.base,
                         call_600305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600305, url, valid)

proc call*(call_600306: Call_GetGetQueueUrl_600291; QueueName: string;
          Action: string = "GetQueueUrl"; QueueOwnerAWSAccountId: string = "";
          Version: string = "2012-11-05"): Recallable =
  ## getGetQueueUrl
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ##   Action: string (required)
  ##   QueueOwnerAWSAccountId: string
  ##                         : The AWS account ID of the account that created the queue.
  ##   QueueName: string (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_600307 = newJObject()
  add(query_600307, "Action", newJString(Action))
  add(query_600307, "QueueOwnerAWSAccountId", newJString(QueueOwnerAWSAccountId))
  add(query_600307, "QueueName", newJString(QueueName))
  add(query_600307, "Version", newJString(Version))
  result = call_600306.call(nil, query_600307, nil, nil, nil)

var getGetQueueUrl* = Call_GetGetQueueUrl_600291(name: "getGetQueueUrl",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_GetGetQueueUrl_600292,
    base: "/", url: url_GetGetQueueUrl_600293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDeadLetterSourceQueues_600344 = ref object of OpenApiRestCall_599352
proc url_PostListDeadLetterSourceQueues_600346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ListDeadLetterSourceQueues")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostListDeadLetterSourceQueues_600345(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600347 = path.getOrDefault("QueueName")
  valid_600347 = validateParameter(valid_600347, JString, required = true,
                                 default = nil)
  if valid_600347 != nil:
    section.add "QueueName", valid_600347
  var valid_600348 = path.getOrDefault("AccountNumber")
  valid_600348 = validateParameter(valid_600348, JInt, required = true, default = nil)
  if valid_600348 != nil:
    section.add "AccountNumber", valid_600348
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600349 = query.getOrDefault("Action")
  valid_600349 = validateParameter(valid_600349, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_600349 != nil:
    section.add "Action", valid_600349
  var valid_600350 = query.getOrDefault("Version")
  valid_600350 = validateParameter(valid_600350, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600350 != nil:
    section.add "Version", valid_600350
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
  var valid_600351 = header.getOrDefault("X-Amz-Date")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Date", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Security-Token")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Security-Token", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Content-Sha256", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Algorithm")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Algorithm", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Signature")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Signature", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-SignedHeaders", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Credential")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Credential", valid_600357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600358: Call_PostListDeadLetterSourceQueues_600344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_600358.validator(path, query, header, formData, body)
  let scheme = call_600358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600358.url(scheme.get, call_600358.host, call_600358.base,
                         call_600358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600358, url, valid)

proc call*(call_600359: Call_PostListDeadLetterSourceQueues_600344;
          QueueName: string; AccountNumber: int;
          Action: string = "ListDeadLetterSourceQueues";
          Version: string = "2012-11-05"): Recallable =
  ## postListDeadLetterSourceQueues
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600360 = newJObject()
  var query_600361 = newJObject()
  add(path_600360, "QueueName", newJString(QueueName))
  add(query_600361, "Action", newJString(Action))
  add(path_600360, "AccountNumber", newJInt(AccountNumber))
  add(query_600361, "Version", newJString(Version))
  result = call_600359.call(path_600360, query_600361, nil, nil, nil)

var postListDeadLetterSourceQueues* = Call_PostListDeadLetterSourceQueues_600344(
    name: "postListDeadLetterSourceQueues", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_PostListDeadLetterSourceQueues_600345, base: "/",
    url: url_PostListDeadLetterSourceQueues_600346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDeadLetterSourceQueues_600326 = ref object of OpenApiRestCall_599352
proc url_GetListDeadLetterSourceQueues_600328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"), (kind: ConstantSegment,
        value: "/#Action=ListDeadLetterSourceQueues")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetListDeadLetterSourceQueues_600327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600329 = path.getOrDefault("QueueName")
  valid_600329 = validateParameter(valid_600329, JString, required = true,
                                 default = nil)
  if valid_600329 != nil:
    section.add "QueueName", valid_600329
  var valid_600330 = path.getOrDefault("AccountNumber")
  valid_600330 = validateParameter(valid_600330, JInt, required = true, default = nil)
  if valid_600330 != nil:
    section.add "AccountNumber", valid_600330
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600331 = query.getOrDefault("Action")
  valid_600331 = validateParameter(valid_600331, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_600331 != nil:
    section.add "Action", valid_600331
  var valid_600332 = query.getOrDefault("Version")
  valid_600332 = validateParameter(valid_600332, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600332 != nil:
    section.add "Version", valid_600332
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
  var valid_600333 = header.getOrDefault("X-Amz-Date")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Date", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Security-Token")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Security-Token", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Content-Sha256", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Algorithm")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Algorithm", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Signature")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Signature", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-SignedHeaders", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Credential")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Credential", valid_600339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_GetListDeadLetterSourceQueues_600326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_GetListDeadLetterSourceQueues_600326;
          QueueName: string; AccountNumber: int;
          Action: string = "ListDeadLetterSourceQueues";
          Version: string = "2012-11-05"): Recallable =
  ## getListDeadLetterSourceQueues
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600342 = newJObject()
  var query_600343 = newJObject()
  add(path_600342, "QueueName", newJString(QueueName))
  add(query_600343, "Action", newJString(Action))
  add(path_600342, "AccountNumber", newJInt(AccountNumber))
  add(query_600343, "Version", newJString(Version))
  result = call_600341.call(path_600342, query_600343, nil, nil, nil)

var getListDeadLetterSourceQueues* = Call_GetListDeadLetterSourceQueues_600326(
    name: "getListDeadLetterSourceQueues", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_GetListDeadLetterSourceQueues_600327, base: "/",
    url: url_GetListDeadLetterSourceQueues_600328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueueTags_600380 = ref object of OpenApiRestCall_599352
proc url_PostListQueueTags_600382(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=ListQueueTags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostListQueueTags_600381(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600383 = path.getOrDefault("QueueName")
  valid_600383 = validateParameter(valid_600383, JString, required = true,
                                 default = nil)
  if valid_600383 != nil:
    section.add "QueueName", valid_600383
  var valid_600384 = path.getOrDefault("AccountNumber")
  valid_600384 = validateParameter(valid_600384, JInt, required = true, default = nil)
  if valid_600384 != nil:
    section.add "AccountNumber", valid_600384
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600385 = query.getOrDefault("Action")
  valid_600385 = validateParameter(valid_600385, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_600385 != nil:
    section.add "Action", valid_600385
  var valid_600386 = query.getOrDefault("Version")
  valid_600386 = validateParameter(valid_600386, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600386 != nil:
    section.add "Version", valid_600386
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
  var valid_600387 = header.getOrDefault("X-Amz-Date")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Date", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Security-Token")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Security-Token", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Content-Sha256", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Algorithm")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Algorithm", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Signature")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Signature", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-SignedHeaders", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Credential")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Credential", valid_600393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600394: Call_PostListQueueTags_600380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600394.validator(path, query, header, formData, body)
  let scheme = call_600394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600394.url(scheme.get, call_600394.host, call_600394.base,
                         call_600394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600394, url, valid)

proc call*(call_600395: Call_PostListQueueTags_600380; QueueName: string;
          AccountNumber: int; Action: string = "ListQueueTags";
          Version: string = "2012-11-05"): Recallable =
  ## postListQueueTags
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600396 = newJObject()
  var query_600397 = newJObject()
  add(path_600396, "QueueName", newJString(QueueName))
  add(query_600397, "Action", newJString(Action))
  add(path_600396, "AccountNumber", newJInt(AccountNumber))
  add(query_600397, "Version", newJString(Version))
  result = call_600395.call(path_600396, query_600397, nil, nil, nil)

var postListQueueTags* = Call_PostListQueueTags_600380(name: "postListQueueTags",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_PostListQueueTags_600381, base: "/",
    url: url_PostListQueueTags_600382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueueTags_600362 = ref object of OpenApiRestCall_599352
proc url_GetListQueueTags_600364(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=ListQueueTags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetListQueueTags_600363(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600365 = path.getOrDefault("QueueName")
  valid_600365 = validateParameter(valid_600365, JString, required = true,
                                 default = nil)
  if valid_600365 != nil:
    section.add "QueueName", valid_600365
  var valid_600366 = path.getOrDefault("AccountNumber")
  valid_600366 = validateParameter(valid_600366, JInt, required = true, default = nil)
  if valid_600366 != nil:
    section.add "AccountNumber", valid_600366
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600367 = query.getOrDefault("Action")
  valid_600367 = validateParameter(valid_600367, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_600367 != nil:
    section.add "Action", valid_600367
  var valid_600368 = query.getOrDefault("Version")
  valid_600368 = validateParameter(valid_600368, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600368 != nil:
    section.add "Version", valid_600368
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
  var valid_600369 = header.getOrDefault("X-Amz-Date")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Date", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Security-Token")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Security-Token", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Content-Sha256", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Algorithm")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Algorithm", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Signature")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Signature", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-SignedHeaders", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Credential")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Credential", valid_600375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_GetListQueueTags_600362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_GetListQueueTags_600362; QueueName: string;
          AccountNumber: int; Action: string = "ListQueueTags";
          Version: string = "2012-11-05"): Recallable =
  ## getListQueueTags
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600378 = newJObject()
  var query_600379 = newJObject()
  add(path_600378, "QueueName", newJString(QueueName))
  add(query_600379, "Action", newJString(Action))
  add(path_600378, "AccountNumber", newJInt(AccountNumber))
  add(query_600379, "Version", newJString(Version))
  result = call_600377.call(path_600378, query_600379, nil, nil, nil)

var getListQueueTags* = Call_GetListQueueTags_600362(name: "getListQueueTags",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_GetListQueueTags_600363, base: "/",
    url: url_GetListQueueTags_600364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueues_600414 = ref object of OpenApiRestCall_599352
proc url_PostListQueues_600416(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListQueues_600415(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600417 = query.getOrDefault("Action")
  valid_600417 = validateParameter(valid_600417, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_600417 != nil:
    section.add "Action", valid_600417
  var valid_600418 = query.getOrDefault("Version")
  valid_600418 = validateParameter(valid_600418, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600418 != nil:
    section.add "Version", valid_600418
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
  var valid_600419 = header.getOrDefault("X-Amz-Date")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Date", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Security-Token")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Security-Token", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Content-Sha256", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Algorithm")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Algorithm", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Signature")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Signature", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-SignedHeaders", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Credential")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Credential", valid_600425
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_600426 = formData.getOrDefault("QueueNamePrefix")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "QueueNamePrefix", valid_600426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600427: Call_PostListQueues_600414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600427.validator(path, query, header, formData, body)
  let scheme = call_600427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600427.url(scheme.get, call_600427.host, call_600427.base,
                         call_600427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600427, url, valid)

proc call*(call_600428: Call_PostListQueues_600414; QueueNamePrefix: string = "";
          Action: string = "ListQueues"; Version: string = "2012-11-05"): Recallable =
  ## postListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600429 = newJObject()
  var formData_600430 = newJObject()
  add(formData_600430, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_600429, "Action", newJString(Action))
  add(query_600429, "Version", newJString(Version))
  result = call_600428.call(nil, query_600429, nil, formData_600430, nil)

var postListQueues* = Call_PostListQueues_600414(name: "postListQueues",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_PostListQueues_600415,
    base: "/", url: url_PostListQueues_600416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueues_600398 = ref object of OpenApiRestCall_599352
proc url_GetListQueues_600400(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListQueues_600399(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600401 = query.getOrDefault("Action")
  valid_600401 = validateParameter(valid_600401, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_600401 != nil:
    section.add "Action", valid_600401
  var valid_600402 = query.getOrDefault("QueueNamePrefix")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "QueueNamePrefix", valid_600402
  var valid_600403 = query.getOrDefault("Version")
  valid_600403 = validateParameter(valid_600403, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600403 != nil:
    section.add "Version", valid_600403
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
  var valid_600404 = header.getOrDefault("X-Amz-Date")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Date", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Security-Token")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Security-Token", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Content-Sha256", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Algorithm")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Algorithm", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Signature")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Signature", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-SignedHeaders", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-Credential")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Credential", valid_600410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600411: Call_GetListQueues_600398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600411.validator(path, query, header, formData, body)
  let scheme = call_600411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600411.url(scheme.get, call_600411.host, call_600411.base,
                         call_600411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600411, url, valid)

proc call*(call_600412: Call_GetListQueues_600398; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_600413 = newJObject()
  add(query_600413, "Action", newJString(Action))
  add(query_600413, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_600413, "Version", newJString(Version))
  result = call_600412.call(nil, query_600413, nil, nil, nil)

var getListQueues* = Call_GetListQueues_600398(name: "getListQueues",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_GetListQueues_600399,
    base: "/", url: url_GetListQueues_600400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurgeQueue_600449 = ref object of OpenApiRestCall_599352
proc url_PostPurgeQueue_600451(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=PurgeQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostPurgeQueue_600450(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600452 = path.getOrDefault("QueueName")
  valid_600452 = validateParameter(valid_600452, JString, required = true,
                                 default = nil)
  if valid_600452 != nil:
    section.add "QueueName", valid_600452
  var valid_600453 = path.getOrDefault("AccountNumber")
  valid_600453 = validateParameter(valid_600453, JInt, required = true, default = nil)
  if valid_600453 != nil:
    section.add "AccountNumber", valid_600453
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600454 = query.getOrDefault("Action")
  valid_600454 = validateParameter(valid_600454, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_600454 != nil:
    section.add "Action", valid_600454
  var valid_600455 = query.getOrDefault("Version")
  valid_600455 = validateParameter(valid_600455, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600455 != nil:
    section.add "Version", valid_600455
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
  var valid_600456 = header.getOrDefault("X-Amz-Date")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Date", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Security-Token")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Security-Token", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Content-Sha256", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Algorithm")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Algorithm", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Signature")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Signature", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-SignedHeaders", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Credential")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Credential", valid_600462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600463: Call_PostPurgeQueue_600449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_600463.validator(path, query, header, formData, body)
  let scheme = call_600463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600463.url(scheme.get, call_600463.host, call_600463.base,
                         call_600463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600463, url, valid)

proc call*(call_600464: Call_PostPurgeQueue_600449; QueueName: string;
          AccountNumber: int; Action: string = "PurgeQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postPurgeQueue
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600465 = newJObject()
  var query_600466 = newJObject()
  add(path_600465, "QueueName", newJString(QueueName))
  add(query_600466, "Action", newJString(Action))
  add(path_600465, "AccountNumber", newJInt(AccountNumber))
  add(query_600466, "Version", newJString(Version))
  result = call_600464.call(path_600465, query_600466, nil, nil, nil)

var postPurgeQueue* = Call_PostPurgeQueue_600449(name: "postPurgeQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_PostPurgeQueue_600450, base: "/", url: url_PostPurgeQueue_600451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurgeQueue_600431 = ref object of OpenApiRestCall_599352
proc url_GetPurgeQueue_600433(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=PurgeQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPurgeQueue_600432(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600434 = path.getOrDefault("QueueName")
  valid_600434 = validateParameter(valid_600434, JString, required = true,
                                 default = nil)
  if valid_600434 != nil:
    section.add "QueueName", valid_600434
  var valid_600435 = path.getOrDefault("AccountNumber")
  valid_600435 = validateParameter(valid_600435, JInt, required = true, default = nil)
  if valid_600435 != nil:
    section.add "AccountNumber", valid_600435
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600436 = query.getOrDefault("Action")
  valid_600436 = validateParameter(valid_600436, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_600436 != nil:
    section.add "Action", valid_600436
  var valid_600437 = query.getOrDefault("Version")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600437 != nil:
    section.add "Version", valid_600437
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
  var valid_600438 = header.getOrDefault("X-Amz-Date")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Date", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Security-Token")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Security-Token", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Content-Sha256", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Algorithm")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Algorithm", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Signature")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Signature", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-SignedHeaders", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Credential")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Credential", valid_600444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600445: Call_GetPurgeQueue_600431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_600445.validator(path, query, header, formData, body)
  let scheme = call_600445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600445.url(scheme.get, call_600445.host, call_600445.base,
                         call_600445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600445, url, valid)

proc call*(call_600446: Call_GetPurgeQueue_600431; QueueName: string;
          AccountNumber: int; Action: string = "PurgeQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getPurgeQueue
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600447 = newJObject()
  var query_600448 = newJObject()
  add(path_600447, "QueueName", newJString(QueueName))
  add(query_600448, "Action", newJString(Action))
  add(path_600447, "AccountNumber", newJInt(AccountNumber))
  add(query_600448, "Version", newJString(Version))
  result = call_600446.call(path_600447, query_600448, nil, nil, nil)

var getPurgeQueue* = Call_GetPurgeQueue_600431(name: "getPurgeQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_GetPurgeQueue_600432, base: "/", url: url_GetPurgeQueue_600433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostReceiveMessage_600491 = ref object of OpenApiRestCall_599352
proc url_PostReceiveMessage_600493(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=ReceiveMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostReceiveMessage_600492(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600494 = path.getOrDefault("QueueName")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = nil)
  if valid_600494 != nil:
    section.add "QueueName", valid_600494
  var valid_600495 = path.getOrDefault("AccountNumber")
  valid_600495 = validateParameter(valid_600495, JInt, required = true, default = nil)
  if valid_600495 != nil:
    section.add "AccountNumber", valid_600495
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600496 = query.getOrDefault("Action")
  valid_600496 = validateParameter(valid_600496, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_600496 != nil:
    section.add "Action", valid_600496
  var valid_600497 = query.getOrDefault("Version")
  valid_600497 = validateParameter(valid_600497, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600497 != nil:
    section.add "Version", valid_600497
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
  var valid_600498 = header.getOrDefault("X-Amz-Date")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Date", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Security-Token")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Security-Token", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Content-Sha256", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Algorithm")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Algorithm", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Signature")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Signature", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-SignedHeaders", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Credential")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Credential", valid_600504
  result.add "header", section
  ## parameters in `formData` object:
  ##   VisibilityTimeout: JInt
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  ##   MaxNumberOfMessages: JInt
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   ReceiveRequestAttemptId: JString
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   WaitTimeSeconds: JInt
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  section = newJObject()
  var valid_600505 = formData.getOrDefault("VisibilityTimeout")
  valid_600505 = validateParameter(valid_600505, JInt, required = false, default = nil)
  if valid_600505 != nil:
    section.add "VisibilityTimeout", valid_600505
  var valid_600506 = formData.getOrDefault("MaxNumberOfMessages")
  valid_600506 = validateParameter(valid_600506, JInt, required = false, default = nil)
  if valid_600506 != nil:
    section.add "MaxNumberOfMessages", valid_600506
  var valid_600507 = formData.getOrDefault("ReceiveRequestAttemptId")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "ReceiveRequestAttemptId", valid_600507
  var valid_600508 = formData.getOrDefault("MessageAttributeNames")
  valid_600508 = validateParameter(valid_600508, JArray, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "MessageAttributeNames", valid_600508
  var valid_600509 = formData.getOrDefault("AttributeNames")
  valid_600509 = validateParameter(valid_600509, JArray, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "AttributeNames", valid_600509
  var valid_600510 = formData.getOrDefault("WaitTimeSeconds")
  valid_600510 = validateParameter(valid_600510, JInt, required = false, default = nil)
  if valid_600510 != nil:
    section.add "WaitTimeSeconds", valid_600510
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_PostReceiveMessage_600491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_PostReceiveMessage_600491; QueueName: string;
          AccountNumber: int; VisibilityTimeout: int = 0;
          MaxNumberOfMessages: int = 0; ReceiveRequestAttemptId: string = "";
          Action: string = "ReceiveMessage"; MessageAttributeNames: JsonNode = nil;
          AttributeNames: JsonNode = nil; Version: string = "2012-11-05";
          WaitTimeSeconds: int = 0): Recallable =
  ## postReceiveMessage
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ##   VisibilityTimeout: int
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  ##   MaxNumberOfMessages: int
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   ReceiveRequestAttemptId: string
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   Version: string (required)
  ##   WaitTimeSeconds: int
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  var path_600513 = newJObject()
  var query_600514 = newJObject()
  var formData_600515 = newJObject()
  add(formData_600515, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(formData_600515, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(formData_600515, "ReceiveRequestAttemptId",
      newJString(ReceiveRequestAttemptId))
  add(path_600513, "QueueName", newJString(QueueName))
  add(query_600514, "Action", newJString(Action))
  if MessageAttributeNames != nil:
    formData_600515.add "MessageAttributeNames", MessageAttributeNames
  add(path_600513, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_600515.add "AttributeNames", AttributeNames
  add(query_600514, "Version", newJString(Version))
  add(formData_600515, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  result = call_600512.call(path_600513, query_600514, nil, formData_600515, nil)

var postReceiveMessage* = Call_PostReceiveMessage_600491(
    name: "postReceiveMessage", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_PostReceiveMessage_600492, base: "/",
    url: url_PostReceiveMessage_600493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReceiveMessage_600467 = ref object of OpenApiRestCall_599352
proc url_GetReceiveMessage_600469(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=ReceiveMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReceiveMessage_600468(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600470 = path.getOrDefault("QueueName")
  valid_600470 = validateParameter(valid_600470, JString, required = true,
                                 default = nil)
  if valid_600470 != nil:
    section.add "QueueName", valid_600470
  var valid_600471 = path.getOrDefault("AccountNumber")
  valid_600471 = validateParameter(valid_600471, JInt, required = true, default = nil)
  if valid_600471 != nil:
    section.add "AccountNumber", valid_600471
  result.add "path", section
  ## parameters in `query` object:
  ##   ReceiveRequestAttemptId: JString
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   WaitTimeSeconds: JInt
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   Action: JString (required)
  ##   MaxNumberOfMessages: JInt
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   Version: JString (required)
  ##   VisibilityTimeout: JInt
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  section = newJObject()
  var valid_600472 = query.getOrDefault("ReceiveRequestAttemptId")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "ReceiveRequestAttemptId", valid_600472
  var valid_600473 = query.getOrDefault("AttributeNames")
  valid_600473 = validateParameter(valid_600473, JArray, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "AttributeNames", valid_600473
  var valid_600474 = query.getOrDefault("WaitTimeSeconds")
  valid_600474 = validateParameter(valid_600474, JInt, required = false, default = nil)
  if valid_600474 != nil:
    section.add "WaitTimeSeconds", valid_600474
  var valid_600475 = query.getOrDefault("MessageAttributeNames")
  valid_600475 = validateParameter(valid_600475, JArray, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "MessageAttributeNames", valid_600475
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600476 = query.getOrDefault("Action")
  valid_600476 = validateParameter(valid_600476, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_600476 != nil:
    section.add "Action", valid_600476
  var valid_600477 = query.getOrDefault("MaxNumberOfMessages")
  valid_600477 = validateParameter(valid_600477, JInt, required = false, default = nil)
  if valid_600477 != nil:
    section.add "MaxNumberOfMessages", valid_600477
  var valid_600478 = query.getOrDefault("Version")
  valid_600478 = validateParameter(valid_600478, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600478 != nil:
    section.add "Version", valid_600478
  var valid_600479 = query.getOrDefault("VisibilityTimeout")
  valid_600479 = validateParameter(valid_600479, JInt, required = false, default = nil)
  if valid_600479 != nil:
    section.add "VisibilityTimeout", valid_600479
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
  var valid_600480 = header.getOrDefault("X-Amz-Date")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Date", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Security-Token")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Security-Token", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Content-Sha256", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Algorithm")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Algorithm", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Signature")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Signature", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-SignedHeaders", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Credential")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Credential", valid_600486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600487: Call_GetReceiveMessage_600467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_600487.validator(path, query, header, formData, body)
  let scheme = call_600487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600487.url(scheme.get, call_600487.host, call_600487.base,
                         call_600487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600487, url, valid)

proc call*(call_600488: Call_GetReceiveMessage_600467; QueueName: string;
          AccountNumber: int; ReceiveRequestAttemptId: string = "";
          AttributeNames: JsonNode = nil; WaitTimeSeconds: int = 0;
          MessageAttributeNames: JsonNode = nil; Action: string = "ReceiveMessage";
          MaxNumberOfMessages: int = 0; Version: string = "2012-11-05";
          VisibilityTimeout: int = 0): Recallable =
  ## getReceiveMessage
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ##   ReceiveRequestAttemptId: string
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   WaitTimeSeconds: int
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   MaxNumberOfMessages: int
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   Version: string (required)
  ##   VisibilityTimeout: int
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  var path_600489 = newJObject()
  var query_600490 = newJObject()
  add(query_600490, "ReceiveRequestAttemptId", newJString(ReceiveRequestAttemptId))
  if AttributeNames != nil:
    query_600490.add "AttributeNames", AttributeNames
  add(path_600489, "QueueName", newJString(QueueName))
  add(query_600490, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  if MessageAttributeNames != nil:
    query_600490.add "MessageAttributeNames", MessageAttributeNames
  add(query_600490, "Action", newJString(Action))
  add(path_600489, "AccountNumber", newJInt(AccountNumber))
  add(query_600490, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(query_600490, "Version", newJString(Version))
  add(query_600490, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_600488.call(path_600489, query_600490, nil, nil, nil)

var getReceiveMessage* = Call_GetReceiveMessage_600467(name: "getReceiveMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_GetReceiveMessage_600468, base: "/",
    url: url_GetReceiveMessage_600469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_600535 = ref object of OpenApiRestCall_599352
proc url_PostRemovePermission_600537(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=RemovePermission")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostRemovePermission_600536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600538 = path.getOrDefault("QueueName")
  valid_600538 = validateParameter(valid_600538, JString, required = true,
                                 default = nil)
  if valid_600538 != nil:
    section.add "QueueName", valid_600538
  var valid_600539 = path.getOrDefault("AccountNumber")
  valid_600539 = validateParameter(valid_600539, JInt, required = true, default = nil)
  if valid_600539 != nil:
    section.add "AccountNumber", valid_600539
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600540 = query.getOrDefault("Action")
  valid_600540 = validateParameter(valid_600540, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_600540 != nil:
    section.add "Action", valid_600540
  var valid_600541 = query.getOrDefault("Version")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600541 != nil:
    section.add "Version", valid_600541
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
  var valid_600542 = header.getOrDefault("X-Amz-Date")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Date", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Security-Token")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Security-Token", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Content-Sha256", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Algorithm")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Algorithm", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Signature")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Signature", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-SignedHeaders", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Credential")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Credential", valid_600548
  result.add "header", section
  ## parameters in `formData` object:
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Label` field"
  var valid_600549 = formData.getOrDefault("Label")
  valid_600549 = validateParameter(valid_600549, JString, required = true,
                                 default = nil)
  if valid_600549 != nil:
    section.add "Label", valid_600549
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600550: Call_PostRemovePermission_600535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_600550.validator(path, query, header, formData, body)
  let scheme = call_600550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600550.url(scheme.get, call_600550.host, call_600550.base,
                         call_600550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600550, url, valid)

proc call*(call_600551: Call_PostRemovePermission_600535; Label: string;
          QueueName: string; AccountNumber: int;
          Action: string = "RemovePermission"; Version: string = "2012-11-05"): Recallable =
  ## postRemovePermission
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   Label: string (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600552 = newJObject()
  var query_600553 = newJObject()
  var formData_600554 = newJObject()
  add(formData_600554, "Label", newJString(Label))
  add(path_600552, "QueueName", newJString(QueueName))
  add(query_600553, "Action", newJString(Action))
  add(path_600552, "AccountNumber", newJInt(AccountNumber))
  add(query_600553, "Version", newJString(Version))
  result = call_600551.call(path_600552, query_600553, nil, formData_600554, nil)

var postRemovePermission* = Call_PostRemovePermission_600535(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_PostRemovePermission_600536, base: "/",
    url: url_PostRemovePermission_600537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_600516 = ref object of OpenApiRestCall_599352
proc url_GetRemovePermission_600518(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=RemovePermission")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRemovePermission_600517(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600519 = path.getOrDefault("QueueName")
  valid_600519 = validateParameter(valid_600519, JString, required = true,
                                 default = nil)
  if valid_600519 != nil:
    section.add "QueueName", valid_600519
  var valid_600520 = path.getOrDefault("AccountNumber")
  valid_600520 = validateParameter(valid_600520, JInt, required = true, default = nil)
  if valid_600520 != nil:
    section.add "AccountNumber", valid_600520
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600521 = query.getOrDefault("Action")
  valid_600521 = validateParameter(valid_600521, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_600521 != nil:
    section.add "Action", valid_600521
  var valid_600522 = query.getOrDefault("Version")
  valid_600522 = validateParameter(valid_600522, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600522 != nil:
    section.add "Version", valid_600522
  var valid_600523 = query.getOrDefault("Label")
  valid_600523 = validateParameter(valid_600523, JString, required = true,
                                 default = nil)
  if valid_600523 != nil:
    section.add "Label", valid_600523
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
  var valid_600524 = header.getOrDefault("X-Amz-Date")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Date", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Security-Token")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Security-Token", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Content-Sha256", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Algorithm")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Algorithm", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Signature")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Signature", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-SignedHeaders", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Credential")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Credential", valid_600530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600531: Call_GetRemovePermission_600516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_600531.validator(path, query, header, formData, body)
  let scheme = call_600531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600531.url(scheme.get, call_600531.host, call_600531.base,
                         call_600531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600531, url, valid)

proc call*(call_600532: Call_GetRemovePermission_600516; QueueName: string;
          AccountNumber: int; Label: string; Action: string = "RemovePermission";
          Version: string = "2012-11-05"): Recallable =
  ## getRemovePermission
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  var path_600533 = newJObject()
  var query_600534 = newJObject()
  add(path_600533, "QueueName", newJString(QueueName))
  add(query_600534, "Action", newJString(Action))
  add(path_600533, "AccountNumber", newJInt(AccountNumber))
  add(query_600534, "Version", newJString(Version))
  add(query_600534, "Label", newJString(Label))
  result = call_600532.call(path_600533, query_600534, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_600516(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_GetRemovePermission_600517, base: "/",
    url: url_GetRemovePermission_600518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessage_600589 = ref object of OpenApiRestCall_599352
proc url_PostSendMessage_600591(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SendMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostSendMessage_600590(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600592 = path.getOrDefault("QueueName")
  valid_600592 = validateParameter(valid_600592, JString, required = true,
                                 default = nil)
  if valid_600592 != nil:
    section.add "QueueName", valid_600592
  var valid_600593 = path.getOrDefault("AccountNumber")
  valid_600593 = validateParameter(valid_600593, JInt, required = true, default = nil)
  if valid_600593 != nil:
    section.add "AccountNumber", valid_600593
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600594 = query.getOrDefault("Action")
  valid_600594 = validateParameter(valid_600594, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_600594 != nil:
    section.add "Action", valid_600594
  var valid_600595 = query.getOrDefault("Version")
  valid_600595 = validateParameter(valid_600595, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600595 != nil:
    section.add "Version", valid_600595
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
  var valid_600596 = header.getOrDefault("X-Amz-Date")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Date", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Security-Token")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Security-Token", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Content-Sha256", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Algorithm")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Algorithm", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Signature")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Signature", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-SignedHeaders", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Credential")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Credential", valid_600602
  result.add "header", section
  ## parameters in `formData` object:
  ##   MessageSystemAttribute.1.value: JString
  ##   MessageAttribute.1.key: JString
  ##   DelaySeconds: JInt
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageGroupId: JString
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageAttribute.0.value: JString
  ##   MessageSystemAttribute.2.key: JString
  ##   MessageDeduplicationId: JString
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   MessageAttribute.2.key: JString
  ##   MessageSystemAttribute.0.key: JString
  ##   MessageBody: JString (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageAttribute.0.key: JString
  ##   MessageSystemAttribute.2.value: JString
  ##   MessageAttribute.1.value: JString
  ##   MessageSystemAttribute.0.value: JString
  ##   MessageAttribute.2.value: JString
  ##   MessageSystemAttribute.1.key: JString
  section = newJObject()
  var valid_600603 = formData.getOrDefault("MessageSystemAttribute.1.value")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "MessageSystemAttribute.1.value", valid_600603
  var valid_600604 = formData.getOrDefault("MessageAttribute.1.key")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "MessageAttribute.1.key", valid_600604
  var valid_600605 = formData.getOrDefault("DelaySeconds")
  valid_600605 = validateParameter(valid_600605, JInt, required = false, default = nil)
  if valid_600605 != nil:
    section.add "DelaySeconds", valid_600605
  var valid_600606 = formData.getOrDefault("MessageGroupId")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "MessageGroupId", valid_600606
  var valid_600607 = formData.getOrDefault("MessageAttribute.0.value")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "MessageAttribute.0.value", valid_600607
  var valid_600608 = formData.getOrDefault("MessageSystemAttribute.2.key")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "MessageSystemAttribute.2.key", valid_600608
  var valid_600609 = formData.getOrDefault("MessageDeduplicationId")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "MessageDeduplicationId", valid_600609
  var valid_600610 = formData.getOrDefault("MessageAttribute.2.key")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "MessageAttribute.2.key", valid_600610
  var valid_600611 = formData.getOrDefault("MessageSystemAttribute.0.key")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "MessageSystemAttribute.0.key", valid_600611
  assert formData != nil,
        "formData argument is necessary due to required `MessageBody` field"
  var valid_600612 = formData.getOrDefault("MessageBody")
  valid_600612 = validateParameter(valid_600612, JString, required = true,
                                 default = nil)
  if valid_600612 != nil:
    section.add "MessageBody", valid_600612
  var valid_600613 = formData.getOrDefault("MessageAttribute.0.key")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "MessageAttribute.0.key", valid_600613
  var valid_600614 = formData.getOrDefault("MessageSystemAttribute.2.value")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "MessageSystemAttribute.2.value", valid_600614
  var valid_600615 = formData.getOrDefault("MessageAttribute.1.value")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "MessageAttribute.1.value", valid_600615
  var valid_600616 = formData.getOrDefault("MessageSystemAttribute.0.value")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "MessageSystemAttribute.0.value", valid_600616
  var valid_600617 = formData.getOrDefault("MessageAttribute.2.value")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "MessageAttribute.2.value", valid_600617
  var valid_600618 = formData.getOrDefault("MessageSystemAttribute.1.key")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "MessageSystemAttribute.1.key", valid_600618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600619: Call_PostSendMessage_600589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_600619.validator(path, query, header, formData, body)
  let scheme = call_600619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600619.url(scheme.get, call_600619.host, call_600619.base,
                         call_600619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600619, url, valid)

proc call*(call_600620: Call_PostSendMessage_600589; QueueName: string;
          MessageBody: string; AccountNumber: int;
          MessageSystemAttribute1Value: string = "";
          MessageAttribute1Key: string = ""; DelaySeconds: int = 0;
          MessageGroupId: string = ""; MessageAttribute0Value: string = "";
          MessageSystemAttribute2Key: string = "";
          MessageDeduplicationId: string = ""; MessageAttribute2Key: string = "";
          MessageSystemAttribute0Key: string = ""; Action: string = "SendMessage";
          MessageAttribute0Key: string = "";
          MessageSystemAttribute2Value: string = "";
          MessageAttribute1Value: string = "";
          MessageSystemAttribute0Value: string = "";
          MessageAttribute2Value: string = ""; Version: string = "2012-11-05";
          MessageSystemAttribute1Key: string = ""): Recallable =
  ## postSendMessage
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageSystemAttribute1Value: string
  ##   MessageAttribute1Key: string
  ##   DelaySeconds: int
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageGroupId: string
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageAttribute0Value: string
  ##   MessageSystemAttribute2Key: string
  ##   MessageDeduplicationId: string
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   MessageAttribute2Key: string
  ##   MessageSystemAttribute0Key: string
  ##   MessageBody: string (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   Action: string (required)
  ##   MessageAttribute0Key: string
  ##   MessageSystemAttribute2Value: string
  ##   MessageAttribute1Value: string
  ##   MessageSystemAttribute0Value: string
  ##   MessageAttribute2Value: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  ##   MessageSystemAttribute1Key: string
  var path_600621 = newJObject()
  var query_600622 = newJObject()
  var formData_600623 = newJObject()
  add(formData_600623, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(formData_600623, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(formData_600623, "DelaySeconds", newJInt(DelaySeconds))
  add(formData_600623, "MessageGroupId", newJString(MessageGroupId))
  add(formData_600623, "MessageAttribute.0.value",
      newJString(MessageAttribute0Value))
  add(formData_600623, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(formData_600623, "MessageDeduplicationId",
      newJString(MessageDeduplicationId))
  add(path_600621, "QueueName", newJString(QueueName))
  add(formData_600623, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(formData_600623, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(formData_600623, "MessageBody", newJString(MessageBody))
  add(query_600622, "Action", newJString(Action))
  add(formData_600623, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(formData_600623, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(formData_600623, "MessageAttribute.1.value",
      newJString(MessageAttribute1Value))
  add(formData_600623, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(formData_600623, "MessageAttribute.2.value",
      newJString(MessageAttribute2Value))
  add(path_600621, "AccountNumber", newJInt(AccountNumber))
  add(query_600622, "Version", newJString(Version))
  add(formData_600623, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  result = call_600620.call(path_600621, query_600622, nil, formData_600623, nil)

var postSendMessage* = Call_PostSendMessage_600589(name: "postSendMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_PostSendMessage_600590, base: "/", url: url_PostSendMessage_600591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessage_600555 = ref object of OpenApiRestCall_599352
proc url_GetSendMessage_600557(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SendMessage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSendMessage_600556(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600558 = path.getOrDefault("QueueName")
  valid_600558 = validateParameter(valid_600558, JString, required = true,
                                 default = nil)
  if valid_600558 != nil:
    section.add "QueueName", valid_600558
  var valid_600559 = path.getOrDefault("AccountNumber")
  valid_600559 = validateParameter(valid_600559, JInt, required = true, default = nil)
  if valid_600559 != nil:
    section.add "AccountNumber", valid_600559
  result.add "path", section
  ## parameters in `query` object:
  ##   MessageAttribute.0.key: JString
  ##   MessageSystemAttribute.1.key: JString
  ##   MessageSystemAttribute.0.value: JString
  ##   MessageGroupId: JString
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageSystemAttribute.2.value: JString
  ##   MessageAttribute.2.key: JString
  ##   MessageSystemAttribute.2.key: JString
  ##   MessageDeduplicationId: JString
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   MessageAttribute.2.value: JString
  ##   MessageSystemAttribute.1.value: JString
  ##   MessageSystemAttribute.0.key: JString
  ##   Action: JString (required)
  ##   MessageAttribute.1.value: JString
  ##   DelaySeconds: JInt
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageAttribute.0.value: JString
  ##   MessageBody: JString (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   Version: JString (required)
  ##   MessageAttribute.1.key: JString
  section = newJObject()
  var valid_600560 = query.getOrDefault("MessageAttribute.0.key")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "MessageAttribute.0.key", valid_600560
  var valid_600561 = query.getOrDefault("MessageSystemAttribute.1.key")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "MessageSystemAttribute.1.key", valid_600561
  var valid_600562 = query.getOrDefault("MessageSystemAttribute.0.value")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "MessageSystemAttribute.0.value", valid_600562
  var valid_600563 = query.getOrDefault("MessageGroupId")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "MessageGroupId", valid_600563
  var valid_600564 = query.getOrDefault("MessageSystemAttribute.2.value")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "MessageSystemAttribute.2.value", valid_600564
  var valid_600565 = query.getOrDefault("MessageAttribute.2.key")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "MessageAttribute.2.key", valid_600565
  var valid_600566 = query.getOrDefault("MessageSystemAttribute.2.key")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "MessageSystemAttribute.2.key", valid_600566
  var valid_600567 = query.getOrDefault("MessageDeduplicationId")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "MessageDeduplicationId", valid_600567
  var valid_600568 = query.getOrDefault("MessageAttribute.2.value")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "MessageAttribute.2.value", valid_600568
  var valid_600569 = query.getOrDefault("MessageSystemAttribute.1.value")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "MessageSystemAttribute.1.value", valid_600569
  var valid_600570 = query.getOrDefault("MessageSystemAttribute.0.key")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "MessageSystemAttribute.0.key", valid_600570
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600571 = query.getOrDefault("Action")
  valid_600571 = validateParameter(valid_600571, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_600571 != nil:
    section.add "Action", valid_600571
  var valid_600572 = query.getOrDefault("MessageAttribute.1.value")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "MessageAttribute.1.value", valid_600572
  var valid_600573 = query.getOrDefault("DelaySeconds")
  valid_600573 = validateParameter(valid_600573, JInt, required = false, default = nil)
  if valid_600573 != nil:
    section.add "DelaySeconds", valid_600573
  var valid_600574 = query.getOrDefault("MessageAttribute.0.value")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "MessageAttribute.0.value", valid_600574
  var valid_600575 = query.getOrDefault("MessageBody")
  valid_600575 = validateParameter(valid_600575, JString, required = true,
                                 default = nil)
  if valid_600575 != nil:
    section.add "MessageBody", valid_600575
  var valid_600576 = query.getOrDefault("Version")
  valid_600576 = validateParameter(valid_600576, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600576 != nil:
    section.add "Version", valid_600576
  var valid_600577 = query.getOrDefault("MessageAttribute.1.key")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "MessageAttribute.1.key", valid_600577
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
  var valid_600578 = header.getOrDefault("X-Amz-Date")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Date", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Security-Token")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Security-Token", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Content-Sha256", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Algorithm")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Algorithm", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Signature")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Signature", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-SignedHeaders", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Credential")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Credential", valid_600584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600585: Call_GetSendMessage_600555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_600585.validator(path, query, header, formData, body)
  let scheme = call_600585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600585.url(scheme.get, call_600585.host, call_600585.base,
                         call_600585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600585, url, valid)

proc call*(call_600586: Call_GetSendMessage_600555; QueueName: string;
          AccountNumber: int; MessageBody: string;
          MessageAttribute0Key: string = "";
          MessageSystemAttribute1Key: string = "";
          MessageSystemAttribute0Value: string = ""; MessageGroupId: string = "";
          MessageSystemAttribute2Value: string = "";
          MessageAttribute2Key: string = "";
          MessageSystemAttribute2Key: string = "";
          MessageDeduplicationId: string = ""; MessageAttribute2Value: string = "";
          MessageSystemAttribute1Value: string = "";
          MessageSystemAttribute0Key: string = ""; Action: string = "SendMessage";
          MessageAttribute1Value: string = ""; DelaySeconds: int = 0;
          MessageAttribute0Value: string = ""; Version: string = "2012-11-05";
          MessageAttribute1Key: string = ""): Recallable =
  ## getSendMessage
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageAttribute0Key: string
  ##   MessageSystemAttribute1Key: string
  ##   MessageSystemAttribute0Value: string
  ##   MessageGroupId: string
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageSystemAttribute2Value: string
  ##   MessageAttribute2Key: string
  ##   MessageSystemAttribute2Key: string
  ##   MessageDeduplicationId: string
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   MessageAttribute2Value: string
  ##   MessageSystemAttribute1Value: string
  ##   MessageSystemAttribute0Key: string
  ##   Action: string (required)
  ##   MessageAttribute1Value: string
  ##   DelaySeconds: int
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   MessageAttribute0Value: string
  ##   MessageBody: string (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   Version: string (required)
  ##   MessageAttribute1Key: string
  var path_600587 = newJObject()
  var query_600588 = newJObject()
  add(query_600588, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(query_600588, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_600588, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(query_600588, "MessageGroupId", newJString(MessageGroupId))
  add(query_600588, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(query_600588, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(query_600588, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(query_600588, "MessageDeduplicationId", newJString(MessageDeduplicationId))
  add(path_600587, "QueueName", newJString(QueueName))
  add(query_600588, "MessageAttribute.2.value", newJString(MessageAttribute2Value))
  add(query_600588, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(query_600588, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(query_600588, "Action", newJString(Action))
  add(query_600588, "MessageAttribute.1.value", newJString(MessageAttribute1Value))
  add(query_600588, "DelaySeconds", newJInt(DelaySeconds))
  add(path_600587, "AccountNumber", newJInt(AccountNumber))
  add(query_600588, "MessageAttribute.0.value", newJString(MessageAttribute0Value))
  add(query_600588, "MessageBody", newJString(MessageBody))
  add(query_600588, "Version", newJString(Version))
  add(query_600588, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  result = call_600586.call(path_600587, query_600588, nil, nil, nil)

var getSendMessage* = Call_GetSendMessage_600555(name: "getSendMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_GetSendMessage_600556, base: "/", url: url_GetSendMessage_600557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessageBatch_600643 = ref object of OpenApiRestCall_599352
proc url_PostSendMessageBatch_600645(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SendMessageBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostSendMessageBatch_600644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600646 = path.getOrDefault("QueueName")
  valid_600646 = validateParameter(valid_600646, JString, required = true,
                                 default = nil)
  if valid_600646 != nil:
    section.add "QueueName", valid_600646
  var valid_600647 = path.getOrDefault("AccountNumber")
  valid_600647 = validateParameter(valid_600647, JInt, required = true, default = nil)
  if valid_600647 != nil:
    section.add "AccountNumber", valid_600647
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600648 = query.getOrDefault("Action")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_600648 != nil:
    section.add "Action", valid_600648
  var valid_600649 = query.getOrDefault("Version")
  valid_600649 = validateParameter(valid_600649, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600649 != nil:
    section.add "Version", valid_600649
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
  var valid_600650 = header.getOrDefault("X-Amz-Date")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Date", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Security-Token")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Security-Token", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Content-Sha256", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Algorithm")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Algorithm", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Signature")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Signature", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-SignedHeaders", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Credential")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Credential", valid_600656
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_600657 = formData.getOrDefault("Entries")
  valid_600657 = validateParameter(valid_600657, JArray, required = true, default = nil)
  if valid_600657 != nil:
    section.add "Entries", valid_600657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600658: Call_PostSendMessageBatch_600643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600658.validator(path, query, header, formData, body)
  let scheme = call_600658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600658.url(scheme.get, call_600658.host, call_600658.base,
                         call_600658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600658, url, valid)

proc call*(call_600659: Call_PostSendMessageBatch_600643; Entries: JsonNode;
          QueueName: string; AccountNumber: int;
          Action: string = "SendMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## postSendMessageBatch
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600660 = newJObject()
  var query_600661 = newJObject()
  var formData_600662 = newJObject()
  if Entries != nil:
    formData_600662.add "Entries", Entries
  add(path_600660, "QueueName", newJString(QueueName))
  add(query_600661, "Action", newJString(Action))
  add(path_600660, "AccountNumber", newJInt(AccountNumber))
  add(query_600661, "Version", newJString(Version))
  result = call_600659.call(path_600660, query_600661, nil, formData_600662, nil)

var postSendMessageBatch* = Call_PostSendMessageBatch_600643(
    name: "postSendMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_PostSendMessageBatch_600644, base: "/",
    url: url_PostSendMessageBatch_600645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessageBatch_600624 = ref object of OpenApiRestCall_599352
proc url_GetSendMessageBatch_600626(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SendMessageBatch")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSendMessageBatch_600625(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600627 = path.getOrDefault("QueueName")
  valid_600627 = validateParameter(valid_600627, JString, required = true,
                                 default = nil)
  if valid_600627 != nil:
    section.add "QueueName", valid_600627
  var valid_600628 = path.getOrDefault("AccountNumber")
  valid_600628 = validateParameter(valid_600628, JInt, required = true, default = nil)
  if valid_600628 != nil:
    section.add "AccountNumber", valid_600628
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_600629 = query.getOrDefault("Entries")
  valid_600629 = validateParameter(valid_600629, JArray, required = true, default = nil)
  if valid_600629 != nil:
    section.add "Entries", valid_600629
  var valid_600630 = query.getOrDefault("Action")
  valid_600630 = validateParameter(valid_600630, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_600630 != nil:
    section.add "Action", valid_600630
  var valid_600631 = query.getOrDefault("Version")
  valid_600631 = validateParameter(valid_600631, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600631 != nil:
    section.add "Version", valid_600631
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
  var valid_600632 = header.getOrDefault("X-Amz-Date")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Date", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Security-Token")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Security-Token", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Content-Sha256", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Algorithm")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Algorithm", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Signature")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Signature", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-SignedHeaders", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Credential")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Credential", valid_600638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600639: Call_GetSendMessageBatch_600624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_600639.validator(path, query, header, formData, body)
  let scheme = call_600639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600639.url(scheme.get, call_600639.host, call_600639.base,
                         call_600639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600639, url, valid)

proc call*(call_600640: Call_GetSendMessageBatch_600624; QueueName: string;
          Entries: JsonNode; AccountNumber: int;
          Action: string = "SendMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## getSendMessageBatch
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600641 = newJObject()
  var query_600642 = newJObject()
  add(path_600641, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_600642.add "Entries", Entries
  add(query_600642, "Action", newJString(Action))
  add(path_600641, "AccountNumber", newJInt(AccountNumber))
  add(query_600642, "Version", newJString(Version))
  result = call_600640.call(path_600641, query_600642, nil, nil, nil)

var getSendMessageBatch* = Call_GetSendMessageBatch_600624(
    name: "getSendMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_GetSendMessageBatch_600625, base: "/",
    url: url_GetSendMessageBatch_600626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetQueueAttributes_600687 = ref object of OpenApiRestCall_599352
proc url_PostSetQueueAttributes_600689(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SetQueueAttributes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostSetQueueAttributes_600688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600690 = path.getOrDefault("QueueName")
  valid_600690 = validateParameter(valid_600690, JString, required = true,
                                 default = nil)
  if valid_600690 != nil:
    section.add "QueueName", valid_600690
  var valid_600691 = path.getOrDefault("AccountNumber")
  valid_600691 = validateParameter(valid_600691, JInt, required = true, default = nil)
  if valid_600691 != nil:
    section.add "AccountNumber", valid_600691
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600692 = query.getOrDefault("Action")
  valid_600692 = validateParameter(valid_600692, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_600692 != nil:
    section.add "Action", valid_600692
  var valid_600693 = query.getOrDefault("Version")
  valid_600693 = validateParameter(valid_600693, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600693 != nil:
    section.add "Version", valid_600693
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
  var valid_600694 = header.getOrDefault("X-Amz-Date")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Date", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Security-Token")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Security-Token", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Content-Sha256", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Algorithm")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Algorithm", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Signature")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Signature", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-SignedHeaders", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Credential")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Credential", valid_600700
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attribute.0.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.value: JString
  ##   Attribute.1.key: JString
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  section = newJObject()
  var valid_600701 = formData.getOrDefault("Attribute.0.key")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "Attribute.0.key", valid_600701
  var valid_600702 = formData.getOrDefault("Attribute.0.value")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "Attribute.0.value", valid_600702
  var valid_600703 = formData.getOrDefault("Attribute.1.value")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "Attribute.1.value", valid_600703
  var valid_600704 = formData.getOrDefault("Attribute.1.key")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "Attribute.1.key", valid_600704
  var valid_600705 = formData.getOrDefault("Attribute.2.value")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "Attribute.2.value", valid_600705
  var valid_600706 = formData.getOrDefault("Attribute.2.key")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "Attribute.2.key", valid_600706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600707: Call_PostSetQueueAttributes_600687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_600707.validator(path, query, header, formData, body)
  let scheme = call_600707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600707.url(scheme.get, call_600707.host, call_600707.base,
                         call_600707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600707, url, valid)

proc call*(call_600708: Call_PostSetQueueAttributes_600687; QueueName: string;
          AccountNumber: int; Attribute0Key: string = "";
          Attribute0Value: string = ""; Attribute1Value: string = "";
          Action: string = "SetQueueAttributes"; Attribute1Key: string = "";
          Attribute2Value: string = ""; Version: string = "2012-11-05";
          Attribute2Key: string = ""): Recallable =
  ## postSetQueueAttributes
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   Attribute0Key: string
  ##   Attribute0Value: string
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Attribute1Value: string
  ##   Action: string (required)
  ##   Attribute1Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Attribute2Value: string
  ##   Version: string (required)
  ##   Attribute2Key: string
  var path_600709 = newJObject()
  var query_600710 = newJObject()
  var formData_600711 = newJObject()
  add(formData_600711, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_600711, "Attribute.0.value", newJString(Attribute0Value))
  add(path_600709, "QueueName", newJString(QueueName))
  add(formData_600711, "Attribute.1.value", newJString(Attribute1Value))
  add(query_600710, "Action", newJString(Action))
  add(formData_600711, "Attribute.1.key", newJString(Attribute1Key))
  add(path_600709, "AccountNumber", newJInt(AccountNumber))
  add(formData_600711, "Attribute.2.value", newJString(Attribute2Value))
  add(query_600710, "Version", newJString(Version))
  add(formData_600711, "Attribute.2.key", newJString(Attribute2Key))
  result = call_600708.call(path_600709, query_600710, nil, formData_600711, nil)

var postSetQueueAttributes* = Call_PostSetQueueAttributes_600687(
    name: "postSetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_PostSetQueueAttributes_600688, base: "/",
    url: url_PostSetQueueAttributes_600689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetQueueAttributes_600663 = ref object of OpenApiRestCall_599352
proc url_GetSetQueueAttributes_600665(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=SetQueueAttributes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSetQueueAttributes_600664(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600666 = path.getOrDefault("QueueName")
  valid_600666 = validateParameter(valid_600666, JString, required = true,
                                 default = nil)
  if valid_600666 != nil:
    section.add "QueueName", valid_600666
  var valid_600667 = path.getOrDefault("AccountNumber")
  valid_600667 = validateParameter(valid_600667, JInt, required = true, default = nil)
  if valid_600667 != nil:
    section.add "AccountNumber", valid_600667
  result.add "path", section
  ## parameters in `query` object:
  ##   Attribute.2.value: JString
  ##   Attribute.0.key: JString
  ##   Attribute.1.value: JString
  ##   Attribute.1.key: JString
  ##   Action: JString (required)
  ##   Attribute.2.key: JString
  ##   Attribute.0.value: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_600668 = query.getOrDefault("Attribute.2.value")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "Attribute.2.value", valid_600668
  var valid_600669 = query.getOrDefault("Attribute.0.key")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "Attribute.0.key", valid_600669
  var valid_600670 = query.getOrDefault("Attribute.1.value")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "Attribute.1.value", valid_600670
  var valid_600671 = query.getOrDefault("Attribute.1.key")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "Attribute.1.key", valid_600671
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600672 = query.getOrDefault("Action")
  valid_600672 = validateParameter(valid_600672, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_600672 != nil:
    section.add "Action", valid_600672
  var valid_600673 = query.getOrDefault("Attribute.2.key")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "Attribute.2.key", valid_600673
  var valid_600674 = query.getOrDefault("Attribute.0.value")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "Attribute.0.value", valid_600674
  var valid_600675 = query.getOrDefault("Version")
  valid_600675 = validateParameter(valid_600675, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600675 != nil:
    section.add "Version", valid_600675
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
  var valid_600676 = header.getOrDefault("X-Amz-Date")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Date", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Security-Token")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Security-Token", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Content-Sha256", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Algorithm")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Algorithm", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Signature")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Signature", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-SignedHeaders", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Credential")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Credential", valid_600682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600683: Call_GetSetQueueAttributes_600663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_GetSetQueueAttributes_600663; QueueName: string;
          AccountNumber: int; Attribute2Value: string = "";
          Attribute0Key: string = ""; Attribute1Value: string = "";
          Attribute1Key: string = ""; Action: string = "SetQueueAttributes";
          Attribute2Key: string = ""; Attribute0Value: string = "";
          Version: string = "2012-11-05"): Recallable =
  ## getSetQueueAttributes
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   Attribute2Value: string
  ##   Attribute0Key: string
  ##   Attribute1Value: string
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Attribute1Key: string
  ##   Action: string (required)
  ##   Attribute2Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Attribute0Value: string
  ##   Version: string (required)
  var path_600685 = newJObject()
  var query_600686 = newJObject()
  add(query_600686, "Attribute.2.value", newJString(Attribute2Value))
  add(query_600686, "Attribute.0.key", newJString(Attribute0Key))
  add(query_600686, "Attribute.1.value", newJString(Attribute1Value))
  add(path_600685, "QueueName", newJString(QueueName))
  add(query_600686, "Attribute.1.key", newJString(Attribute1Key))
  add(query_600686, "Action", newJString(Action))
  add(query_600686, "Attribute.2.key", newJString(Attribute2Key))
  add(path_600685, "AccountNumber", newJInt(AccountNumber))
  add(query_600686, "Attribute.0.value", newJString(Attribute0Value))
  add(query_600686, "Version", newJString(Version))
  result = call_600684.call(path_600685, query_600686, nil, nil, nil)

var getSetQueueAttributes* = Call_GetSetQueueAttributes_600663(
    name: "getSetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_GetSetQueueAttributes_600664, base: "/",
    url: url_GetSetQueueAttributes_600665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagQueue_600736 = ref object of OpenApiRestCall_599352
proc url_PostTagQueue_600738(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=TagQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostTagQueue_600737(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600739 = path.getOrDefault("QueueName")
  valid_600739 = validateParameter(valid_600739, JString, required = true,
                                 default = nil)
  if valid_600739 != nil:
    section.add "QueueName", valid_600739
  var valid_600740 = path.getOrDefault("AccountNumber")
  valid_600740 = validateParameter(valid_600740, JInt, required = true, default = nil)
  if valid_600740 != nil:
    section.add "AccountNumber", valid_600740
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600741 = query.getOrDefault("Action")
  valid_600741 = validateParameter(valid_600741, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_600741 != nil:
    section.add "Action", valid_600741
  var valid_600742 = query.getOrDefault("Version")
  valid_600742 = validateParameter(valid_600742, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600742 != nil:
    section.add "Version", valid_600742
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
  var valid_600743 = header.getOrDefault("X-Amz-Date")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Date", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-Security-Token")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-Security-Token", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Content-Sha256", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Algorithm")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Algorithm", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Signature")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Signature", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-SignedHeaders", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Credential")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Credential", valid_600749
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.2.value: JString
  ##   Tags.1.value: JString
  ##   Tags.2.key: JString
  ##   Tags.0.value: JString
  section = newJObject()
  var valid_600750 = formData.getOrDefault("Tags.0.key")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "Tags.0.key", valid_600750
  var valid_600751 = formData.getOrDefault("Tags.1.key")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "Tags.1.key", valid_600751
  var valid_600752 = formData.getOrDefault("Tags.2.value")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "Tags.2.value", valid_600752
  var valid_600753 = formData.getOrDefault("Tags.1.value")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "Tags.1.value", valid_600753
  var valid_600754 = formData.getOrDefault("Tags.2.key")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "Tags.2.key", valid_600754
  var valid_600755 = formData.getOrDefault("Tags.0.value")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "Tags.0.value", valid_600755
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600756: Call_PostTagQueue_600736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600756.validator(path, query, header, formData, body)
  let scheme = call_600756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600756.url(scheme.get, call_600756.host, call_600756.base,
                         call_600756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600756, url, valid)

proc call*(call_600757: Call_PostTagQueue_600736; QueueName: string;
          AccountNumber: int; Tags0Key: string = ""; Tags1Key: string = "";
          Tags2Value: string = ""; Action: string = "TagQueue"; Tags1Value: string = "";
          Tags2Key: string = ""; Version: string = "2012-11-05"; Tags0Value: string = ""): Recallable =
  ## postTagQueue
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Tags0Key: string
  ##   Tags1Key: string
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Tags2Value: string
  ##   Action: string (required)
  ##   Tags1Value: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Tags2Key: string
  ##   Version: string (required)
  ##   Tags0Value: string
  var path_600758 = newJObject()
  var query_600759 = newJObject()
  var formData_600760 = newJObject()
  add(formData_600760, "Tags.0.key", newJString(Tags0Key))
  add(formData_600760, "Tags.1.key", newJString(Tags1Key))
  add(path_600758, "QueueName", newJString(QueueName))
  add(formData_600760, "Tags.2.value", newJString(Tags2Value))
  add(query_600759, "Action", newJString(Action))
  add(formData_600760, "Tags.1.value", newJString(Tags1Value))
  add(path_600758, "AccountNumber", newJInt(AccountNumber))
  add(formData_600760, "Tags.2.key", newJString(Tags2Key))
  add(query_600759, "Version", newJString(Version))
  add(formData_600760, "Tags.0.value", newJString(Tags0Value))
  result = call_600757.call(path_600758, query_600759, nil, formData_600760, nil)

var postTagQueue* = Call_PostTagQueue_600736(name: "postTagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
    validator: validate_PostTagQueue_600737, base: "/", url: url_PostTagQueue_600738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagQueue_600712 = ref object of OpenApiRestCall_599352
proc url_GetTagQueue_600714(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=TagQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTagQueue_600713(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600715 = path.getOrDefault("QueueName")
  valid_600715 = validateParameter(valid_600715, JString, required = true,
                                 default = nil)
  if valid_600715 != nil:
    section.add "QueueName", valid_600715
  var valid_600716 = path.getOrDefault("AccountNumber")
  valid_600716 = validateParameter(valid_600716, JInt, required = true, default = nil)
  if valid_600716 != nil:
    section.add "AccountNumber", valid_600716
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags.2.value: JString
  ##   Tags.2.key: JString
  ##   Tags.1.value: JString
  ##   Action: JString (required)
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.0.value: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_600717 = query.getOrDefault("Tags.2.value")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "Tags.2.value", valid_600717
  var valid_600718 = query.getOrDefault("Tags.2.key")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "Tags.2.key", valid_600718
  var valid_600719 = query.getOrDefault("Tags.1.value")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "Tags.1.value", valid_600719
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600720 = query.getOrDefault("Action")
  valid_600720 = validateParameter(valid_600720, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_600720 != nil:
    section.add "Action", valid_600720
  var valid_600721 = query.getOrDefault("Tags.0.key")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "Tags.0.key", valid_600721
  var valid_600722 = query.getOrDefault("Tags.1.key")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "Tags.1.key", valid_600722
  var valid_600723 = query.getOrDefault("Tags.0.value")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "Tags.0.value", valid_600723
  var valid_600724 = query.getOrDefault("Version")
  valid_600724 = validateParameter(valid_600724, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600724 != nil:
    section.add "Version", valid_600724
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
  var valid_600725 = header.getOrDefault("X-Amz-Date")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Date", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Security-Token")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Security-Token", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Content-Sha256", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Algorithm")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Algorithm", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Signature")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Signature", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-SignedHeaders", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Credential")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Credential", valid_600731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600732: Call_GetTagQueue_600712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600732.validator(path, query, header, formData, body)
  let scheme = call_600732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600732.url(scheme.get, call_600732.host, call_600732.base,
                         call_600732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600732, url, valid)

proc call*(call_600733: Call_GetTagQueue_600712; QueueName: string;
          AccountNumber: int; Tags2Value: string = ""; Tags2Key: string = "";
          Tags1Value: string = ""; Action: string = "TagQueue"; Tags0Key: string = "";
          Tags1Key: string = ""; Tags0Value: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getTagQueue
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Tags2Value: string
  ##   Tags2Key: string
  ##   Tags1Value: string
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Tags0Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Tags1Key: string
  ##   Tags0Value: string
  ##   Version: string (required)
  var path_600734 = newJObject()
  var query_600735 = newJObject()
  add(query_600735, "Tags.2.value", newJString(Tags2Value))
  add(query_600735, "Tags.2.key", newJString(Tags2Key))
  add(query_600735, "Tags.1.value", newJString(Tags1Value))
  add(path_600734, "QueueName", newJString(QueueName))
  add(query_600735, "Action", newJString(Action))
  add(query_600735, "Tags.0.key", newJString(Tags0Key))
  add(path_600734, "AccountNumber", newJInt(AccountNumber))
  add(query_600735, "Tags.1.key", newJString(Tags1Key))
  add(query_600735, "Tags.0.value", newJString(Tags0Value))
  add(query_600735, "Version", newJString(Version))
  result = call_600733.call(path_600734, query_600735, nil, nil, nil)

var getTagQueue* = Call_GetTagQueue_600712(name: "getTagQueue",
                                        meth: HttpMethod.HttpGet,
                                        host: "sqs.amazonaws.com", route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
                                        validator: validate_GetTagQueue_600713,
                                        base: "/", url: url_GetTagQueue_600714,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagQueue_600780 = ref object of OpenApiRestCall_599352
proc url_PostUntagQueue_600782(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=UntagQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostUntagQueue_600781(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600783 = path.getOrDefault("QueueName")
  valid_600783 = validateParameter(valid_600783, JString, required = true,
                                 default = nil)
  if valid_600783 != nil:
    section.add "QueueName", valid_600783
  var valid_600784 = path.getOrDefault("AccountNumber")
  valid_600784 = validateParameter(valid_600784, JInt, required = true, default = nil)
  if valid_600784 != nil:
    section.add "AccountNumber", valid_600784
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600785 = query.getOrDefault("Action")
  valid_600785 = validateParameter(valid_600785, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_600785 != nil:
    section.add "Action", valid_600785
  var valid_600786 = query.getOrDefault("Version")
  valid_600786 = validateParameter(valid_600786, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600786 != nil:
    section.add "Version", valid_600786
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
  var valid_600787 = header.getOrDefault("X-Amz-Date")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Date", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Security-Token")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Security-Token", valid_600788
  var valid_600789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "X-Amz-Content-Sha256", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Algorithm")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Algorithm", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-Signature")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Signature", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-SignedHeaders", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-Credential")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-Credential", valid_600793
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_600794 = formData.getOrDefault("TagKeys")
  valid_600794 = validateParameter(valid_600794, JArray, required = true, default = nil)
  if valid_600794 != nil:
    section.add "TagKeys", valid_600794
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600795: Call_PostUntagQueue_600780; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600795.validator(path, query, header, formData, body)
  let scheme = call_600795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600795.url(scheme.get, call_600795.host, call_600795.base,
                         call_600795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600795, url, valid)

proc call*(call_600796: Call_PostUntagQueue_600780; QueueName: string;
          TagKeys: JsonNode; AccountNumber: int; Action: string = "UntagQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postUntagQueue
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Version: string (required)
  var path_600797 = newJObject()
  var query_600798 = newJObject()
  var formData_600799 = newJObject()
  add(path_600797, "QueueName", newJString(QueueName))
  add(query_600798, "Action", newJString(Action))
  if TagKeys != nil:
    formData_600799.add "TagKeys", TagKeys
  add(path_600797, "AccountNumber", newJInt(AccountNumber))
  add(query_600798, "Version", newJString(Version))
  result = call_600796.call(path_600797, query_600798, nil, formData_600799, nil)

var postUntagQueue* = Call_PostUntagQueue_600780(name: "postUntagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_PostUntagQueue_600781, base: "/", url: url_PostUntagQueue_600782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagQueue_600761 = ref object of OpenApiRestCall_599352
proc url_GetUntagQueue_600763(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AccountNumber" in path, "`AccountNumber` is a required path parameter"
  assert "QueueName" in path, "`QueueName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "AccountNumber"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "QueueName"),
               (kind: ConstantSegment, value: "/#Action=UntagQueue")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUntagQueue_600762(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   QueueName: JString (required)
  ##            : The name of the queue
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `QueueName` field"
  var valid_600764 = path.getOrDefault("QueueName")
  valid_600764 = validateParameter(valid_600764, JString, required = true,
                                 default = nil)
  if valid_600764 != nil:
    section.add "QueueName", valid_600764
  var valid_600765 = path.getOrDefault("AccountNumber")
  valid_600765 = validateParameter(valid_600765, JInt, required = true, default = nil)
  if valid_600765 != nil:
    section.add "AccountNumber", valid_600765
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600766 = query.getOrDefault("Action")
  valid_600766 = validateParameter(valid_600766, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_600766 != nil:
    section.add "Action", valid_600766
  var valid_600767 = query.getOrDefault("TagKeys")
  valid_600767 = validateParameter(valid_600767, JArray, required = true, default = nil)
  if valid_600767 != nil:
    section.add "TagKeys", valid_600767
  var valid_600768 = query.getOrDefault("Version")
  valid_600768 = validateParameter(valid_600768, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_600768 != nil:
    section.add "Version", valid_600768
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
  var valid_600769 = header.getOrDefault("X-Amz-Date")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Date", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Security-Token")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Security-Token", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Content-Sha256", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-Algorithm")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Algorithm", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Signature")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Signature", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-SignedHeaders", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Credential")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Credential", valid_600775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600776: Call_GetUntagQueue_600761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600776.validator(path, query, header, formData, body)
  let scheme = call_600776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600776.url(scheme.get, call_600776.host, call_600776.base,
                         call_600776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600776, url, valid)

proc call*(call_600777: Call_GetUntagQueue_600761; QueueName: string;
          AccountNumber: int; TagKeys: JsonNode; Action: string = "UntagQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getUntagQueue
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Version: string (required)
  var path_600778 = newJObject()
  var query_600779 = newJObject()
  add(path_600778, "QueueName", newJString(QueueName))
  add(query_600779, "Action", newJString(Action))
  add(path_600778, "AccountNumber", newJInt(AccountNumber))
  if TagKeys != nil:
    query_600779.add "TagKeys", TagKeys
  add(query_600779, "Version", newJString(Version))
  result = call_600777.call(path_600778, query_600779, nil, nil, nil)

var getUntagQueue* = Call_GetUntagQueue_600761(name: "getUntagQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_GetUntagQueue_600762, base: "/", url: url_GetUntagQueue_600763,
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
