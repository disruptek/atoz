
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_PostAddPermission_606201 = ref object of OpenApiRestCall_605573
proc url_PostAddPermission_606203(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_606202(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606204 = path.getOrDefault("AccountNumber")
  valid_606204 = validateParameter(valid_606204, JInt, required = true, default = nil)
  if valid_606204 != nil:
    section.add "AccountNumber", valid_606204
  var valid_606205 = path.getOrDefault("QueueName")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "QueueName", valid_606205
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606206 = query.getOrDefault("Action")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_606206 != nil:
    section.add "Action", valid_606206
  var valid_606207 = query.getOrDefault("Version")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606207 != nil:
    section.add "Version", valid_606207
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
  var valid_606208 = header.getOrDefault("X-Amz-Signature")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Signature", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Content-Sha256", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Date")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Date", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Credential")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Credential", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Security-Token")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Security-Token", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Algorithm")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Algorithm", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-SignedHeaders", valid_606214
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
  var valid_606215 = formData.getOrDefault("Actions")
  valid_606215 = validateParameter(valid_606215, JArray, required = true, default = nil)
  if valid_606215 != nil:
    section.add "Actions", valid_606215
  var valid_606216 = formData.getOrDefault("Label")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "Label", valid_606216
  var valid_606217 = formData.getOrDefault("AWSAccountIds")
  valid_606217 = validateParameter(valid_606217, JArray, required = true, default = nil)
  if valid_606217 != nil:
    section.add "AWSAccountIds", valid_606217
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606218: Call_PostAddPermission_606201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606218.validator(path, query, header, formData, body)
  let scheme = call_606218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606218.url(scheme.get, call_606218.host, call_606218.base,
                         call_606218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606218, url, valid)

proc call*(call_606219: Call_PostAddPermission_606201; Actions: JsonNode;
          AccountNumber: int; QueueName: string; Label: string;
          AWSAccountIds: JsonNode; Action: string = "AddPermission";
          Version: string = "2012-11-05"): Recallable =
  ## postAddPermission
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Label: string (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  ##   Version: string (required)
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  var path_606220 = newJObject()
  var query_606221 = newJObject()
  var formData_606222 = newJObject()
  if Actions != nil:
    formData_606222.add "Actions", Actions
  add(path_606220, "AccountNumber", newJInt(AccountNumber))
  add(path_606220, "QueueName", newJString(QueueName))
  add(query_606221, "Action", newJString(Action))
  add(formData_606222, "Label", newJString(Label))
  add(query_606221, "Version", newJString(Version))
  if AWSAccountIds != nil:
    formData_606222.add "AWSAccountIds", AWSAccountIds
  result = call_606219.call(path_606220, query_606221, nil, formData_606222, nil)

var postAddPermission* = Call_PostAddPermission_606201(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_PostAddPermission_606202, base: "/",
    url: url_PostAddPermission_606203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_605911 = ref object of OpenApiRestCall_605573
proc url_GetAddPermission_605913(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_605912(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606039 = path.getOrDefault("AccountNumber")
  valid_606039 = validateParameter(valid_606039, JInt, required = true, default = nil)
  if valid_606039 != nil:
    section.add "AccountNumber", valid_606039
  var valid_606040 = path.getOrDefault("QueueName")
  valid_606040 = validateParameter(valid_606040, JString, required = true,
                                 default = nil)
  if valid_606040 != nil:
    section.add "QueueName", valid_606040
  result.add "path", section
  ## parameters in `query` object:
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Actions` field"
  var valid_606041 = query.getOrDefault("Actions")
  valid_606041 = validateParameter(valid_606041, JArray, required = true, default = nil)
  if valid_606041 != nil:
    section.add "Actions", valid_606041
  var valid_606042 = query.getOrDefault("AWSAccountIds")
  valid_606042 = validateParameter(valid_606042, JArray, required = true, default = nil)
  if valid_606042 != nil:
    section.add "AWSAccountIds", valid_606042
  var valid_606056 = query.getOrDefault("Action")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_606056 != nil:
    section.add "Action", valid_606056
  var valid_606057 = query.getOrDefault("Version")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606057 != nil:
    section.add "Version", valid_606057
  var valid_606058 = query.getOrDefault("Label")
  valid_606058 = validateParameter(valid_606058, JString, required = true,
                                 default = nil)
  if valid_606058 != nil:
    section.add "Label", valid_606058
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
  var valid_606059 = header.getOrDefault("X-Amz-Signature")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Signature", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Content-Sha256", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Date")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Date", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Credential")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Credential", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Security-Token")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Security-Token", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Algorithm")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Algorithm", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-SignedHeaders", valid_606065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606088: Call_GetAddPermission_605911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606088.validator(path, query, header, formData, body)
  let scheme = call_606088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606088.url(scheme.get, call_606088.host, call_606088.base,
                         call_606088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606088, url, valid)

proc call*(call_606159: Call_GetAddPermission_605911; Actions: JsonNode;
          AccountNumber: int; QueueName: string; AWSAccountIds: JsonNode;
          Label: string; Action: string = "AddPermission";
          Version: string = "2012-11-05"): Recallable =
  ## getAddPermission
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Actions: JArray (required)
  ##          : <p>The action the client wants to allow for the specified principal. Valid values: the name of any action or <code>*</code>.</p> <p>For more information about these actions, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html">Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>Specifying <code>SendMessage</code>, <code>DeleteMessage</code>, or <code>ChangeMessageVisibility</code> for <code>ActionName.n</code> also grants permissions for the corresponding batch versions of those actions: <code>SendMessageBatch</code>, <code>DeleteMessageBatch</code>, and <code>ChangeMessageVisibilityBatch</code>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   AWSAccountIds: JArray (required)
  ##                : The AWS account number of the <a 
  ## href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a> who is given permission. The principal must have an AWS account, but does not need to be signed up for Amazon SQS. For information about locating the AWS account identification, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication">Your AWS Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique identification of the permission you're setting (for example, <code>AliceSendMessage</code>). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).
  var path_606160 = newJObject()
  var query_606162 = newJObject()
  if Actions != nil:
    query_606162.add "Actions", Actions
  add(path_606160, "AccountNumber", newJInt(AccountNumber))
  add(path_606160, "QueueName", newJString(QueueName))
  if AWSAccountIds != nil:
    query_606162.add "AWSAccountIds", AWSAccountIds
  add(query_606162, "Action", newJString(Action))
  add(query_606162, "Version", newJString(Version))
  add(query_606162, "Label", newJString(Label))
  result = call_606159.call(path_606160, query_606162, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_605911(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_GetAddPermission_605912, base: "/",
    url: url_GetAddPermission_605913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibility_606243 = ref object of OpenApiRestCall_605573
proc url_PostChangeMessageVisibility_606245(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibility_606244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606246 = path.getOrDefault("AccountNumber")
  valid_606246 = validateParameter(valid_606246, JInt, required = true, default = nil)
  if valid_606246 != nil:
    section.add "AccountNumber", valid_606246
  var valid_606247 = path.getOrDefault("QueueName")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "QueueName", valid_606247
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606248 = query.getOrDefault("Action")
  valid_606248 = validateParameter(valid_606248, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_606248 != nil:
    section.add "Action", valid_606248
  var valid_606249 = query.getOrDefault("Version")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606249 != nil:
    section.add "Version", valid_606249
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
  var valid_606250 = header.getOrDefault("X-Amz-Signature")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Signature", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Content-Sha256", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Date")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Date", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Credential")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Credential", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Security-Token")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Security-Token", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Algorithm")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Algorithm", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-SignedHeaders", valid_606256
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_606257 = formData.getOrDefault("ReceiptHandle")
  valid_606257 = validateParameter(valid_606257, JString, required = true,
                                 default = nil)
  if valid_606257 != nil:
    section.add "ReceiptHandle", valid_606257
  var valid_606258 = formData.getOrDefault("VisibilityTimeout")
  valid_606258 = validateParameter(valid_606258, JInt, required = true, default = nil)
  if valid_606258 != nil:
    section.add "VisibilityTimeout", valid_606258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606259: Call_PostChangeMessageVisibility_606243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_606259.validator(path, query, header, formData, body)
  let scheme = call_606259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606259.url(scheme.get, call_606259.host, call_606259.base,
                         call_606259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606259, url, valid)

proc call*(call_606260: Call_PostChangeMessageVisibility_606243;
          ReceiptHandle: string; AccountNumber: int; QueueName: string;
          VisibilityTimeout: int; Action: string = "ChangeMessageVisibility";
          Version: string = "2012-11-05"): Recallable =
  ## postChangeMessageVisibility
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   VisibilityTimeout: int (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606261 = newJObject()
  var query_606262 = newJObject()
  var formData_606263 = newJObject()
  add(formData_606263, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_606261, "AccountNumber", newJInt(AccountNumber))
  add(path_606261, "QueueName", newJString(QueueName))
  add(formData_606263, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(query_606262, "Action", newJString(Action))
  add(query_606262, "Version", newJString(Version))
  result = call_606260.call(path_606261, query_606262, nil, formData_606263, nil)

var postChangeMessageVisibility* = Call_PostChangeMessageVisibility_606243(
    name: "postChangeMessageVisibility", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_PostChangeMessageVisibility_606244, base: "/",
    url: url_PostChangeMessageVisibility_606245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibility_606223 = ref object of OpenApiRestCall_605573
proc url_GetChangeMessageVisibility_606225(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibility_606224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606226 = path.getOrDefault("AccountNumber")
  valid_606226 = validateParameter(valid_606226, JInt, required = true, default = nil)
  if valid_606226 != nil:
    section.add "AccountNumber", valid_606226
  var valid_606227 = path.getOrDefault("QueueName")
  valid_606227 = validateParameter(valid_606227, JString, required = true,
                                 default = nil)
  if valid_606227 != nil:
    section.add "QueueName", valid_606227
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   Version: JString (required)
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  section = newJObject()
  var valid_606228 = query.getOrDefault("Action")
  valid_606228 = validateParameter(valid_606228, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_606228 != nil:
    section.add "Action", valid_606228
  var valid_606229 = query.getOrDefault("ReceiptHandle")
  valid_606229 = validateParameter(valid_606229, JString, required = true,
                                 default = nil)
  if valid_606229 != nil:
    section.add "ReceiptHandle", valid_606229
  var valid_606230 = query.getOrDefault("Version")
  valid_606230 = validateParameter(valid_606230, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606230 != nil:
    section.add "Version", valid_606230
  var valid_606231 = query.getOrDefault("VisibilityTimeout")
  valid_606231 = validateParameter(valid_606231, JInt, required = true, default = nil)
  if valid_606231 != nil:
    section.add "VisibilityTimeout", valid_606231
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
  var valid_606232 = header.getOrDefault("X-Amz-Signature")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Signature", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Content-Sha256", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Date")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Date", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Credential")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Credential", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Security-Token")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Security-Token", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Algorithm")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Algorithm", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-SignedHeaders", valid_606238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_GetChangeMessageVisibility_606223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_GetChangeMessageVisibility_606223; AccountNumber: int;
          QueueName: string; ReceiptHandle: string; VisibilityTimeout: int;
          Action: string = "ChangeMessageVisibility"; Version: string = "2012-11-05"): Recallable =
  ## getChangeMessageVisibility
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   Version: string (required)
  ##   VisibilityTimeout: int (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  var path_606241 = newJObject()
  var query_606242 = newJObject()
  add(path_606241, "AccountNumber", newJInt(AccountNumber))
  add(path_606241, "QueueName", newJString(QueueName))
  add(query_606242, "Action", newJString(Action))
  add(query_606242, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_606242, "Version", newJString(Version))
  add(query_606242, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_606240.call(path_606241, query_606242, nil, nil, nil)

var getChangeMessageVisibility* = Call_GetChangeMessageVisibility_606223(
    name: "getChangeMessageVisibility", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_GetChangeMessageVisibility_606224, base: "/",
    url: url_GetChangeMessageVisibility_606225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibilityBatch_606283 = ref object of OpenApiRestCall_605573
proc url_PostChangeMessageVisibilityBatch_606285(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibilityBatch_606284(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606286 = path.getOrDefault("AccountNumber")
  valid_606286 = validateParameter(valid_606286, JInt, required = true, default = nil)
  if valid_606286 != nil:
    section.add "AccountNumber", valid_606286
  var valid_606287 = path.getOrDefault("QueueName")
  valid_606287 = validateParameter(valid_606287, JString, required = true,
                                 default = nil)
  if valid_606287 != nil:
    section.add "QueueName", valid_606287
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606288 = query.getOrDefault("Action")
  valid_606288 = validateParameter(valid_606288, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_606288 != nil:
    section.add "Action", valid_606288
  var valid_606289 = query.getOrDefault("Version")
  valid_606289 = validateParameter(valid_606289, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606289 != nil:
    section.add "Version", valid_606289
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
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_606297 = formData.getOrDefault("Entries")
  valid_606297 = validateParameter(valid_606297, JArray, required = true, default = nil)
  if valid_606297 != nil:
    section.add "Entries", valid_606297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_PostChangeMessageVisibilityBatch_606283;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_PostChangeMessageVisibilityBatch_606283;
          AccountNumber: int; QueueName: string; Entries: JsonNode;
          Action: string = "ChangeMessageVisibilityBatch";
          Version: string = "2012-11-05"): Recallable =
  ## postChangeMessageVisibilityBatch
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606300 = newJObject()
  var query_606301 = newJObject()
  var formData_606302 = newJObject()
  add(path_606300, "AccountNumber", newJInt(AccountNumber))
  add(path_606300, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_606302.add "Entries", Entries
  add(query_606301, "Action", newJString(Action))
  add(query_606301, "Version", newJString(Version))
  result = call_606299.call(path_606300, query_606301, nil, formData_606302, nil)

var postChangeMessageVisibilityBatch* = Call_PostChangeMessageVisibilityBatch_606283(
    name: "postChangeMessageVisibilityBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_PostChangeMessageVisibilityBatch_606284, base: "/",
    url: url_PostChangeMessageVisibilityBatch_606285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibilityBatch_606264 = ref object of OpenApiRestCall_605573
proc url_GetChangeMessageVisibilityBatch_606266(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibilityBatch_606265(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606267 = path.getOrDefault("AccountNumber")
  valid_606267 = validateParameter(valid_606267, JInt, required = true, default = nil)
  if valid_606267 != nil:
    section.add "AccountNumber", valid_606267
  var valid_606268 = path.getOrDefault("QueueName")
  valid_606268 = validateParameter(valid_606268, JString, required = true,
                                 default = nil)
  if valid_606268 != nil:
    section.add "QueueName", valid_606268
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_606269 = query.getOrDefault("Entries")
  valid_606269 = validateParameter(valid_606269, JArray, required = true, default = nil)
  if valid_606269 != nil:
    section.add "Entries", valid_606269
  var valid_606270 = query.getOrDefault("Action")
  valid_606270 = validateParameter(valid_606270, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_606270 != nil:
    section.add "Action", valid_606270
  var valid_606271 = query.getOrDefault("Version")
  valid_606271 = validateParameter(valid_606271, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606271 != nil:
    section.add "Version", valid_606271
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
  var valid_606272 = header.getOrDefault("X-Amz-Signature")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Signature", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Content-Sha256", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Date")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Date", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Credential")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Credential", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Security-Token")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Security-Token", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Algorithm")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Algorithm", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-SignedHeaders", valid_606278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606279: Call_GetChangeMessageVisibilityBatch_606264;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606279.validator(path, query, header, formData, body)
  let scheme = call_606279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606279.url(scheme.get, call_606279.host, call_606279.base,
                         call_606279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606279, url, valid)

proc call*(call_606280: Call_GetChangeMessageVisibilityBatch_606264;
          Entries: JsonNode; AccountNumber: int; QueueName: string;
          Action: string = "ChangeMessageVisibilityBatch";
          Version: string = "2012-11-05"): Recallable =
  ## getChangeMessageVisibilityBatch
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606281 = newJObject()
  var query_606282 = newJObject()
  if Entries != nil:
    query_606282.add "Entries", Entries
  add(path_606281, "AccountNumber", newJInt(AccountNumber))
  add(path_606281, "QueueName", newJString(QueueName))
  add(query_606282, "Action", newJString(Action))
  add(query_606282, "Version", newJString(Version))
  result = call_606280.call(path_606281, query_606282, nil, nil, nil)

var getChangeMessageVisibilityBatch* = Call_GetChangeMessageVisibilityBatch_606264(
    name: "getChangeMessageVisibilityBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_GetChangeMessageVisibilityBatch_606265, base: "/",
    url: url_GetChangeMessageVisibilityBatch_606266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateQueue_606331 = ref object of OpenApiRestCall_605573
proc url_PostCreateQueue_606333(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateQueue_606332(path: JsonNode; query: JsonNode;
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
  var valid_606334 = query.getOrDefault("Action")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_606334 != nil:
    section.add "Action", valid_606334
  var valid_606335 = query.getOrDefault("Version")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606335 != nil:
    section.add "Version", valid_606335
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
  var valid_606336 = header.getOrDefault("X-Amz-Signature")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Signature", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Content-Sha256", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Date")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Date", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Credential")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Credential", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Security-Token")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Security-Token", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Algorithm")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Algorithm", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-SignedHeaders", valid_606342
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tag.1.value: JString
  ##   Tag.2.key: JString
  ##   Attribute.2.key: JString
  ##   Attribute.2.value: JString
  ##   Tag.1.key: JString
  ##   Tag.2.value: JString
  ##   Attribute.0.value: JString
  ##   Tag.0.value: JString
  ##   Attribute.1.key: JString
  ##   Tag.0.key: JString
  ##   QueueName: JString (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute.1.value: JString
  ##   Attribute.0.key: JString
  section = newJObject()
  var valid_606343 = formData.getOrDefault("Tag.1.value")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "Tag.1.value", valid_606343
  var valid_606344 = formData.getOrDefault("Tag.2.key")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "Tag.2.key", valid_606344
  var valid_606345 = formData.getOrDefault("Attribute.2.key")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "Attribute.2.key", valid_606345
  var valid_606346 = formData.getOrDefault("Attribute.2.value")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "Attribute.2.value", valid_606346
  var valid_606347 = formData.getOrDefault("Tag.1.key")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "Tag.1.key", valid_606347
  var valid_606348 = formData.getOrDefault("Tag.2.value")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "Tag.2.value", valid_606348
  var valid_606349 = formData.getOrDefault("Attribute.0.value")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "Attribute.0.value", valid_606349
  var valid_606350 = formData.getOrDefault("Tag.0.value")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "Tag.0.value", valid_606350
  var valid_606351 = formData.getOrDefault("Attribute.1.key")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "Attribute.1.key", valid_606351
  var valid_606352 = formData.getOrDefault("Tag.0.key")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "Tag.0.key", valid_606352
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_606353 = formData.getOrDefault("QueueName")
  valid_606353 = validateParameter(valid_606353, JString, required = true,
                                 default = nil)
  if valid_606353 != nil:
    section.add "QueueName", valid_606353
  var valid_606354 = formData.getOrDefault("Attribute.1.value")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "Attribute.1.value", valid_606354
  var valid_606355 = formData.getOrDefault("Attribute.0.key")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "Attribute.0.key", valid_606355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606356: Call_PostCreateQueue_606331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606356.validator(path, query, header, formData, body)
  let scheme = call_606356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606356.url(scheme.get, call_606356.host, call_606356.base,
                         call_606356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606356, url, valid)

proc call*(call_606357: Call_PostCreateQueue_606331; QueueName: string;
          Tag1Value: string = ""; Tag2Key: string = ""; Attribute2Key: string = "";
          Attribute2Value: string = ""; Tag1Key: string = ""; Tag2Value: string = "";
          Attribute0Value: string = ""; Tag0Value: string = "";
          Attribute1Key: string = ""; Tag0Key: string = "";
          Attribute1Value: string = ""; Action: string = "CreateQueue";
          Version: string = "2012-11-05"; Attribute0Key: string = ""): Recallable =
  ## postCreateQueue
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Tag1Value: string
  ##   Tag2Key: string
  ##   Attribute2Key: string
  ##   Attribute2Value: string
  ##   Tag1Key: string
  ##   Tag2Value: string
  ##   Attribute0Value: string
  ##   Tag0Value: string
  ##   Attribute1Key: string
  ##   Tag0Key: string
  ##   QueueName: string (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute1Value: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attribute0Key: string
  var query_606358 = newJObject()
  var formData_606359 = newJObject()
  add(formData_606359, "Tag.1.value", newJString(Tag1Value))
  add(formData_606359, "Tag.2.key", newJString(Tag2Key))
  add(formData_606359, "Attribute.2.key", newJString(Attribute2Key))
  add(formData_606359, "Attribute.2.value", newJString(Attribute2Value))
  add(formData_606359, "Tag.1.key", newJString(Tag1Key))
  add(formData_606359, "Tag.2.value", newJString(Tag2Value))
  add(formData_606359, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_606359, "Tag.0.value", newJString(Tag0Value))
  add(formData_606359, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_606359, "Tag.0.key", newJString(Tag0Key))
  add(formData_606359, "QueueName", newJString(QueueName))
  add(formData_606359, "Attribute.1.value", newJString(Attribute1Value))
  add(query_606358, "Action", newJString(Action))
  add(query_606358, "Version", newJString(Version))
  add(formData_606359, "Attribute.0.key", newJString(Attribute0Key))
  result = call_606357.call(nil, query_606358, nil, formData_606359, nil)

var postCreateQueue* = Call_PostCreateQueue_606331(name: "postCreateQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_PostCreateQueue_606332,
    base: "/", url: url_PostCreateQueue_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateQueue_606303 = ref object of OpenApiRestCall_605573
proc url_GetCreateQueue_606305(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateQueue_606304(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attribute.2.key: JString
  ##   QueueName: JString (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute.1.key: JString
  ##   Attribute.2.value: JString
  ##   Attribute.1.value: JString
  ##   Tag.0.value: JString
  ##   Tag.1.key: JString
  ##   Tag.1.value: JString
  ##   Tag.0.key: JString
  ##   Action: JString (required)
  ##   Tag.2.key: JString
  ##   Attribute.0.key: JString
  ##   Version: JString (required)
  ##   Tag.2.value: JString
  ##   Attribute.0.value: JString
  section = newJObject()
  var valid_606306 = query.getOrDefault("Attribute.2.key")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "Attribute.2.key", valid_606306
  assert query != nil,
        "query argument is necessary due to required `QueueName` field"
  var valid_606307 = query.getOrDefault("QueueName")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = nil)
  if valid_606307 != nil:
    section.add "QueueName", valid_606307
  var valid_606308 = query.getOrDefault("Attribute.1.key")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "Attribute.1.key", valid_606308
  var valid_606309 = query.getOrDefault("Attribute.2.value")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "Attribute.2.value", valid_606309
  var valid_606310 = query.getOrDefault("Attribute.1.value")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "Attribute.1.value", valid_606310
  var valid_606311 = query.getOrDefault("Tag.0.value")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "Tag.0.value", valid_606311
  var valid_606312 = query.getOrDefault("Tag.1.key")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "Tag.1.key", valid_606312
  var valid_606313 = query.getOrDefault("Tag.1.value")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "Tag.1.value", valid_606313
  var valid_606314 = query.getOrDefault("Tag.0.key")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "Tag.0.key", valid_606314
  var valid_606315 = query.getOrDefault("Action")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_606315 != nil:
    section.add "Action", valid_606315
  var valid_606316 = query.getOrDefault("Tag.2.key")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "Tag.2.key", valid_606316
  var valid_606317 = query.getOrDefault("Attribute.0.key")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "Attribute.0.key", valid_606317
  var valid_606318 = query.getOrDefault("Version")
  valid_606318 = validateParameter(valid_606318, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606318 != nil:
    section.add "Version", valid_606318
  var valid_606319 = query.getOrDefault("Tag.2.value")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "Tag.2.value", valid_606319
  var valid_606320 = query.getOrDefault("Attribute.0.value")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "Attribute.0.value", valid_606320
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
  var valid_606321 = header.getOrDefault("X-Amz-Signature")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Signature", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Content-Sha256", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Date")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Date", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Credential")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Credential", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Security-Token")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Security-Token", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_GetCreateQueue_606303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_GetCreateQueue_606303; QueueName: string;
          Attribute2Key: string = ""; Attribute1Key: string = "";
          Attribute2Value: string = ""; Attribute1Value: string = "";
          Tag0Value: string = ""; Tag1Key: string = ""; Tag1Value: string = "";
          Tag0Key: string = ""; Action: string = "CreateQueue"; Tag2Key: string = "";
          Attribute0Key: string = ""; Version: string = "2012-11-05";
          Tag2Value: string = ""; Attribute0Value: string = ""): Recallable =
  ## getCreateQueue
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Attribute2Key: string
  ##   QueueName: string (required)
  ##            : <p>The name of the new queue. The following limits apply to this name:</p> <ul> <li> <p>A queue name can have up to 80 characters.</p> </li> <li> <p>Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> </li> <li> <p>A FIFO queue name must end with the <code>.fifo</code> suffix.</p> </li> </ul> <p>Queue URLs and names are case-sensitive.</p>
  ##   Attribute1Key: string
  ##   Attribute2Value: string
  ##   Attribute1Value: string
  ##   Tag0Value: string
  ##   Tag1Key: string
  ##   Tag1Value: string
  ##   Tag0Key: string
  ##   Action: string (required)
  ##   Tag2Key: string
  ##   Attribute0Key: string
  ##   Version: string (required)
  ##   Tag2Value: string
  ##   Attribute0Value: string
  var query_606330 = newJObject()
  add(query_606330, "Attribute.2.key", newJString(Attribute2Key))
  add(query_606330, "QueueName", newJString(QueueName))
  add(query_606330, "Attribute.1.key", newJString(Attribute1Key))
  add(query_606330, "Attribute.2.value", newJString(Attribute2Value))
  add(query_606330, "Attribute.1.value", newJString(Attribute1Value))
  add(query_606330, "Tag.0.value", newJString(Tag0Value))
  add(query_606330, "Tag.1.key", newJString(Tag1Key))
  add(query_606330, "Tag.1.value", newJString(Tag1Value))
  add(query_606330, "Tag.0.key", newJString(Tag0Key))
  add(query_606330, "Action", newJString(Action))
  add(query_606330, "Tag.2.key", newJString(Tag2Key))
  add(query_606330, "Attribute.0.key", newJString(Attribute0Key))
  add(query_606330, "Version", newJString(Version))
  add(query_606330, "Tag.2.value", newJString(Tag2Value))
  add(query_606330, "Attribute.0.value", newJString(Attribute0Value))
  result = call_606329.call(nil, query_606330, nil, nil, nil)

var getCreateQueue* = Call_GetCreateQueue_606303(name: "getCreateQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_GetCreateQueue_606304,
    base: "/", url: url_GetCreateQueue_606305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessage_606379 = ref object of OpenApiRestCall_605573
proc url_PostDeleteMessage_606381(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessage_606380(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606382 = path.getOrDefault("AccountNumber")
  valid_606382 = validateParameter(valid_606382, JInt, required = true, default = nil)
  if valid_606382 != nil:
    section.add "AccountNumber", valid_606382
  var valid_606383 = path.getOrDefault("QueueName")
  valid_606383 = validateParameter(valid_606383, JString, required = true,
                                 default = nil)
  if valid_606383 != nil:
    section.add "QueueName", valid_606383
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606384 = query.getOrDefault("Action")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_606384 != nil:
    section.add "Action", valid_606384
  var valid_606385 = query.getOrDefault("Version")
  valid_606385 = validateParameter(valid_606385, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606385 != nil:
    section.add "Version", valid_606385
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
  var valid_606386 = header.getOrDefault("X-Amz-Signature")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Signature", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Content-Sha256", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Date")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Date", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Credential")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Credential", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Security-Token")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Security-Token", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Algorithm")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Algorithm", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-SignedHeaders", valid_606392
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_606393 = formData.getOrDefault("ReceiptHandle")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "ReceiptHandle", valid_606393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606394: Call_PostDeleteMessage_606379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_606394.validator(path, query, header, formData, body)
  let scheme = call_606394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606394.url(scheme.get, call_606394.host, call_606394.base,
                         call_606394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606394, url, valid)

proc call*(call_606395: Call_PostDeleteMessage_606379; ReceiptHandle: string;
          AccountNumber: int; QueueName: string; Action: string = "DeleteMessage";
          Version: string = "2012-11-05"): Recallable =
  ## postDeleteMessage
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message to delete.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606396 = newJObject()
  var query_606397 = newJObject()
  var formData_606398 = newJObject()
  add(formData_606398, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_606396, "AccountNumber", newJInt(AccountNumber))
  add(path_606396, "QueueName", newJString(QueueName))
  add(query_606397, "Action", newJString(Action))
  add(query_606397, "Version", newJString(Version))
  result = call_606395.call(path_606396, query_606397, nil, formData_606398, nil)

var postDeleteMessage* = Call_PostDeleteMessage_606379(name: "postDeleteMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_PostDeleteMessage_606380, base: "/",
    url: url_PostDeleteMessage_606381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessage_606360 = ref object of OpenApiRestCall_605573
proc url_GetDeleteMessage_606362(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessage_606361(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606363 = path.getOrDefault("AccountNumber")
  valid_606363 = validateParameter(valid_606363, JInt, required = true, default = nil)
  if valid_606363 != nil:
    section.add "AccountNumber", valid_606363
  var valid_606364 = path.getOrDefault("QueueName")
  valid_606364 = validateParameter(valid_606364, JString, required = true,
                                 default = nil)
  if valid_606364 != nil:
    section.add "QueueName", valid_606364
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Version: JString (required)
  section = newJObject()
  var valid_606365 = query.getOrDefault("Action")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_606365 != nil:
    section.add "Action", valid_606365
  var valid_606366 = query.getOrDefault("ReceiptHandle")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = nil)
  if valid_606366 != nil:
    section.add "ReceiptHandle", valid_606366
  var valid_606367 = query.getOrDefault("Version")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606367 != nil:
    section.add "Version", valid_606367
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
  var valid_606368 = header.getOrDefault("X-Amz-Signature")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Signature", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Content-Sha256", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Date")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Date", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Credential")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Credential", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Security-Token")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Security-Token", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Algorithm")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Algorithm", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-SignedHeaders", valid_606374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606375: Call_GetDeleteMessage_606360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_606375.validator(path, query, header, formData, body)
  let scheme = call_606375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606375.url(scheme.get, call_606375.host, call_606375.base,
                         call_606375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606375, url, valid)

proc call*(call_606376: Call_GetDeleteMessage_606360; AccountNumber: int;
          QueueName: string; ReceiptHandle: string;
          Action: string = "DeleteMessage"; Version: string = "2012-11-05"): Recallable =
  ## getDeleteMessage
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   ReceiptHandle: string (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Version: string (required)
  var path_606377 = newJObject()
  var query_606378 = newJObject()
  add(path_606377, "AccountNumber", newJInt(AccountNumber))
  add(path_606377, "QueueName", newJString(QueueName))
  add(query_606378, "Action", newJString(Action))
  add(query_606378, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_606378, "Version", newJString(Version))
  result = call_606376.call(path_606377, query_606378, nil, nil, nil)

var getDeleteMessage* = Call_GetDeleteMessage_606360(name: "getDeleteMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_GetDeleteMessage_606361, base: "/",
    url: url_GetDeleteMessage_606362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessageBatch_606418 = ref object of OpenApiRestCall_605573
proc url_PostDeleteMessageBatch_606420(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessageBatch_606419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606421 = path.getOrDefault("AccountNumber")
  valid_606421 = validateParameter(valid_606421, JInt, required = true, default = nil)
  if valid_606421 != nil:
    section.add "AccountNumber", valid_606421
  var valid_606422 = path.getOrDefault("QueueName")
  valid_606422 = validateParameter(valid_606422, JString, required = true,
                                 default = nil)
  if valid_606422 != nil:
    section.add "QueueName", valid_606422
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606423 = query.getOrDefault("Action")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_606423 != nil:
    section.add "Action", valid_606423
  var valid_606424 = query.getOrDefault("Version")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606424 != nil:
    section.add "Version", valid_606424
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
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_606432 = formData.getOrDefault("Entries")
  valid_606432 = validateParameter(valid_606432, JArray, required = true, default = nil)
  if valid_606432 != nil:
    section.add "Entries", valid_606432
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_PostDeleteMessageBatch_606418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_PostDeleteMessageBatch_606418; AccountNumber: int;
          QueueName: string; Entries: JsonNode;
          Action: string = "DeleteMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## postDeleteMessageBatch
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606435 = newJObject()
  var query_606436 = newJObject()
  var formData_606437 = newJObject()
  add(path_606435, "AccountNumber", newJInt(AccountNumber))
  add(path_606435, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_606437.add "Entries", Entries
  add(query_606436, "Action", newJString(Action))
  add(query_606436, "Version", newJString(Version))
  result = call_606434.call(path_606435, query_606436, nil, formData_606437, nil)

var postDeleteMessageBatch* = Call_PostDeleteMessageBatch_606418(
    name: "postDeleteMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_PostDeleteMessageBatch_606419, base: "/",
    url: url_PostDeleteMessageBatch_606420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessageBatch_606399 = ref object of OpenApiRestCall_605573
proc url_GetDeleteMessageBatch_606401(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessageBatch_606400(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606402 = path.getOrDefault("AccountNumber")
  valid_606402 = validateParameter(valid_606402, JInt, required = true, default = nil)
  if valid_606402 != nil:
    section.add "AccountNumber", valid_606402
  var valid_606403 = path.getOrDefault("QueueName")
  valid_606403 = validateParameter(valid_606403, JString, required = true,
                                 default = nil)
  if valid_606403 != nil:
    section.add "QueueName", valid_606403
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_606404 = query.getOrDefault("Entries")
  valid_606404 = validateParameter(valid_606404, JArray, required = true, default = nil)
  if valid_606404 != nil:
    section.add "Entries", valid_606404
  var valid_606405 = query.getOrDefault("Action")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_606405 != nil:
    section.add "Action", valid_606405
  var valid_606406 = query.getOrDefault("Version")
  valid_606406 = validateParameter(valid_606406, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606406 != nil:
    section.add "Version", valid_606406
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
  var valid_606407 = header.getOrDefault("X-Amz-Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Signature", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Content-Sha256", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Date")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Date", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Credential")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Credential", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Security-Token")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Security-Token", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Algorithm")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Algorithm", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-SignedHeaders", valid_606413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606414: Call_GetDeleteMessageBatch_606399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606414.validator(path, query, header, formData, body)
  let scheme = call_606414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606414.url(scheme.get, call_606414.host, call_606414.base,
                         call_606414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606414, url, valid)

proc call*(call_606415: Call_GetDeleteMessageBatch_606399; Entries: JsonNode;
          AccountNumber: int; QueueName: string;
          Action: string = "DeleteMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## getDeleteMessageBatch
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606416 = newJObject()
  var query_606417 = newJObject()
  if Entries != nil:
    query_606417.add "Entries", Entries
  add(path_606416, "AccountNumber", newJInt(AccountNumber))
  add(path_606416, "QueueName", newJString(QueueName))
  add(query_606417, "Action", newJString(Action))
  add(query_606417, "Version", newJString(Version))
  result = call_606415.call(path_606416, query_606417, nil, nil, nil)

var getDeleteMessageBatch* = Call_GetDeleteMessageBatch_606399(
    name: "getDeleteMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_GetDeleteMessageBatch_606400, base: "/",
    url: url_GetDeleteMessageBatch_606401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteQueue_606456 = ref object of OpenApiRestCall_605573
proc url_PostDeleteQueue_606458(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteQueue_606457(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606459 = path.getOrDefault("AccountNumber")
  valid_606459 = validateParameter(valid_606459, JInt, required = true, default = nil)
  if valid_606459 != nil:
    section.add "AccountNumber", valid_606459
  var valid_606460 = path.getOrDefault("QueueName")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = nil)
  if valid_606460 != nil:
    section.add "QueueName", valid_606460
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606461 = query.getOrDefault("Action")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_606461 != nil:
    section.add "Action", valid_606461
  var valid_606462 = query.getOrDefault("Version")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606462 != nil:
    section.add "Version", valid_606462
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
  var valid_606463 = header.getOrDefault("X-Amz-Signature")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Signature", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Content-Sha256", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Date")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Date", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Credential")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Credential", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_PostDeleteQueue_606456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_PostDeleteQueue_606456; AccountNumber: int;
          QueueName: string; Action: string = "DeleteQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postDeleteQueue
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606472 = newJObject()
  var query_606473 = newJObject()
  add(path_606472, "AccountNumber", newJInt(AccountNumber))
  add(path_606472, "QueueName", newJString(QueueName))
  add(query_606473, "Action", newJString(Action))
  add(query_606473, "Version", newJString(Version))
  result = call_606471.call(path_606472, query_606473, nil, nil, nil)

var postDeleteQueue* = Call_PostDeleteQueue_606456(name: "postDeleteQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_PostDeleteQueue_606457, base: "/", url: url_PostDeleteQueue_606458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteQueue_606438 = ref object of OpenApiRestCall_605573
proc url_GetDeleteQueue_606440(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteQueue_606439(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606441 = path.getOrDefault("AccountNumber")
  valid_606441 = validateParameter(valid_606441, JInt, required = true, default = nil)
  if valid_606441 != nil:
    section.add "AccountNumber", valid_606441
  var valid_606442 = path.getOrDefault("QueueName")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "QueueName", valid_606442
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606443 = query.getOrDefault("Action")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_606443 != nil:
    section.add "Action", valid_606443
  var valid_606444 = query.getOrDefault("Version")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606444 != nil:
    section.add "Version", valid_606444
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
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_GetDeleteQueue_606438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_GetDeleteQueue_606438; AccountNumber: int;
          QueueName: string; Action: string = "DeleteQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getDeleteQueue
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606454 = newJObject()
  var query_606455 = newJObject()
  add(path_606454, "AccountNumber", newJInt(AccountNumber))
  add(path_606454, "QueueName", newJString(QueueName))
  add(query_606455, "Action", newJString(Action))
  add(query_606455, "Version", newJString(Version))
  result = call_606453.call(path_606454, query_606455, nil, nil, nil)

var getDeleteQueue* = Call_GetDeleteQueue_606438(name: "getDeleteQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_GetDeleteQueue_606439, base: "/", url: url_GetDeleteQueue_606440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueAttributes_606493 = ref object of OpenApiRestCall_605573
proc url_PostGetQueueAttributes_606495(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetQueueAttributes_606494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606496 = path.getOrDefault("AccountNumber")
  valid_606496 = validateParameter(valid_606496, JInt, required = true, default = nil)
  if valid_606496 != nil:
    section.add "AccountNumber", valid_606496
  var valid_606497 = path.getOrDefault("QueueName")
  valid_606497 = validateParameter(valid_606497, JString, required = true,
                                 default = nil)
  if valid_606497 != nil:
    section.add "QueueName", valid_606497
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606498 = query.getOrDefault("Action")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_606498 != nil:
    section.add "Action", valid_606498
  var valid_606499 = query.getOrDefault("Version")
  valid_606499 = validateParameter(valid_606499, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606499 != nil:
    section.add "Version", valid_606499
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
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
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
  var valid_606507 = formData.getOrDefault("AttributeNames")
  valid_606507 = validateParameter(valid_606507, JArray, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "AttributeNames", valid_606507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_PostGetQueueAttributes_606493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_PostGetQueueAttributes_606493; AccountNumber: int;
          QueueName: string; AttributeNames: JsonNode = nil;
          Action: string = "GetQueueAttributes"; Version: string = "2012-11-05"): Recallable =
  ## postGetQueueAttributes
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
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
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606510 = newJObject()
  var query_606511 = newJObject()
  var formData_606512 = newJObject()
  add(path_606510, "AccountNumber", newJInt(AccountNumber))
  add(path_606510, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    formData_606512.add "AttributeNames", AttributeNames
  add(query_606511, "Action", newJString(Action))
  add(query_606511, "Version", newJString(Version))
  result = call_606509.call(path_606510, query_606511, nil, formData_606512, nil)

var postGetQueueAttributes* = Call_PostGetQueueAttributes_606493(
    name: "postGetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_PostGetQueueAttributes_606494, base: "/",
    url: url_PostGetQueueAttributes_606495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueAttributes_606474 = ref object of OpenApiRestCall_605573
proc url_GetGetQueueAttributes_606476(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetQueueAttributes_606475(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606477 = path.getOrDefault("AccountNumber")
  valid_606477 = validateParameter(valid_606477, JInt, required = true, default = nil)
  if valid_606477 != nil:
    section.add "AccountNumber", valid_606477
  var valid_606478 = path.getOrDefault("QueueName")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "QueueName", valid_606478
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
  var valid_606479 = query.getOrDefault("AttributeNames")
  valid_606479 = validateParameter(valid_606479, JArray, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "AttributeNames", valid_606479
  var valid_606480 = query.getOrDefault("Action")
  valid_606480 = validateParameter(valid_606480, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_606480 != nil:
    section.add "Action", valid_606480
  var valid_606481 = query.getOrDefault("Version")
  valid_606481 = validateParameter(valid_606481, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606481 != nil:
    section.add "Version", valid_606481
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
  var valid_606482 = header.getOrDefault("X-Amz-Signature")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Signature", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Content-Sha256", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Date")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Date", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Credential")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Credential", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Security-Token")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Security-Token", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Algorithm")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Algorithm", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-SignedHeaders", valid_606488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606489: Call_GetGetQueueAttributes_606474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606489.validator(path, query, header, formData, body)
  let scheme = call_606489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606489.url(scheme.get, call_606489.host, call_606489.base,
                         call_606489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606489, url, valid)

proc call*(call_606490: Call_GetGetQueueAttributes_606474; AccountNumber: int;
          QueueName: string; AttributeNames: JsonNode = nil;
          Action: string = "GetQueueAttributes"; Version: string = "2012-11-05"): Recallable =
  ## getGetQueueAttributes
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
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
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606491 = newJObject()
  var query_606492 = newJObject()
  add(path_606491, "AccountNumber", newJInt(AccountNumber))
  add(path_606491, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    query_606492.add "AttributeNames", AttributeNames
  add(query_606492, "Action", newJString(Action))
  add(query_606492, "Version", newJString(Version))
  result = call_606490.call(path_606491, query_606492, nil, nil, nil)

var getGetQueueAttributes* = Call_GetGetQueueAttributes_606474(
    name: "getGetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_GetGetQueueAttributes_606475, base: "/",
    url: url_GetGetQueueAttributes_606476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueUrl_606530 = ref object of OpenApiRestCall_605573
proc url_PostGetQueueUrl_606532(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetQueueUrl_606531(path: JsonNode; query: JsonNode;
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
  var valid_606533 = query.getOrDefault("Action")
  valid_606533 = validateParameter(valid_606533, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_606533 != nil:
    section.add "Action", valid_606533
  var valid_606534 = query.getOrDefault("Version")
  valid_606534 = validateParameter(valid_606534, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606534 != nil:
    section.add "Version", valid_606534
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
  var valid_606535 = header.getOrDefault("X-Amz-Signature")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Signature", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Content-Sha256", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Date")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Date", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Credential")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Credential", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Security-Token")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Security-Token", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Algorithm")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Algorithm", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-SignedHeaders", valid_606541
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_606542 = formData.getOrDefault("QueueName")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = nil)
  if valid_606542 != nil:
    section.add "QueueName", valid_606542
  var valid_606543 = formData.getOrDefault("QueueOwnerAWSAccountId")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "QueueOwnerAWSAccountId", valid_606543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606544: Call_PostGetQueueUrl_606530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_606544.validator(path, query, header, formData, body)
  let scheme = call_606544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606544.url(scheme.get, call_606544.host, call_606544.base,
                         call_606544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606544, url, valid)

proc call*(call_606545: Call_PostGetQueueUrl_606530; QueueName: string;
          QueueOwnerAWSAccountId: string = ""; Action: string = "GetQueueUrl";
          Version: string = "2012-11-05"): Recallable =
  ## postGetQueueUrl
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ##   QueueName: string (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   QueueOwnerAWSAccountId: string
  ##                         : The AWS account ID of the account that created the queue.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606546 = newJObject()
  var formData_606547 = newJObject()
  add(formData_606547, "QueueName", newJString(QueueName))
  add(formData_606547, "QueueOwnerAWSAccountId",
      newJString(QueueOwnerAWSAccountId))
  add(query_606546, "Action", newJString(Action))
  add(query_606546, "Version", newJString(Version))
  result = call_606545.call(nil, query_606546, nil, formData_606547, nil)

var postGetQueueUrl* = Call_PostGetQueueUrl_606530(name: "postGetQueueUrl",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_PostGetQueueUrl_606531,
    base: "/", url: url_PostGetQueueUrl_606532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueUrl_606513 = ref object of OpenApiRestCall_605573
proc url_GetGetQueueUrl_606515(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetQueueUrl_606514(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `QueueName` field"
  var valid_606516 = query.getOrDefault("QueueName")
  valid_606516 = validateParameter(valid_606516, JString, required = true,
                                 default = nil)
  if valid_606516 != nil:
    section.add "QueueName", valid_606516
  var valid_606517 = query.getOrDefault("QueueOwnerAWSAccountId")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "QueueOwnerAWSAccountId", valid_606517
  var valid_606518 = query.getOrDefault("Action")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_606518 != nil:
    section.add "Action", valid_606518
  var valid_606519 = query.getOrDefault("Version")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606519 != nil:
    section.add "Version", valid_606519
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
  var valid_606520 = header.getOrDefault("X-Amz-Signature")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Signature", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Content-Sha256", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Date")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Date", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Credential")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Credential", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Security-Token")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Security-Token", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Algorithm")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Algorithm", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-SignedHeaders", valid_606526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606527: Call_GetGetQueueUrl_606513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_606527.validator(path, query, header, formData, body)
  let scheme = call_606527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606527.url(scheme.get, call_606527.host, call_606527.base,
                         call_606527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606527, url, valid)

proc call*(call_606528: Call_GetGetQueueUrl_606513; QueueName: string;
          QueueOwnerAWSAccountId: string = ""; Action: string = "GetQueueUrl";
          Version: string = "2012-11-05"): Recallable =
  ## getGetQueueUrl
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ##   QueueName: string (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   QueueOwnerAWSAccountId: string
  ##                         : The AWS account ID of the account that created the queue.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606529 = newJObject()
  add(query_606529, "QueueName", newJString(QueueName))
  add(query_606529, "QueueOwnerAWSAccountId", newJString(QueueOwnerAWSAccountId))
  add(query_606529, "Action", newJString(Action))
  add(query_606529, "Version", newJString(Version))
  result = call_606528.call(nil, query_606529, nil, nil, nil)

var getGetQueueUrl* = Call_GetGetQueueUrl_606513(name: "getGetQueueUrl",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_GetGetQueueUrl_606514,
    base: "/", url: url_GetGetQueueUrl_606515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDeadLetterSourceQueues_606566 = ref object of OpenApiRestCall_605573
proc url_PostListDeadLetterSourceQueues_606568(protocol: Scheme; host: string;
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

proc validate_PostListDeadLetterSourceQueues_606567(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606569 = path.getOrDefault("AccountNumber")
  valid_606569 = validateParameter(valid_606569, JInt, required = true, default = nil)
  if valid_606569 != nil:
    section.add "AccountNumber", valid_606569
  var valid_606570 = path.getOrDefault("QueueName")
  valid_606570 = validateParameter(valid_606570, JString, required = true,
                                 default = nil)
  if valid_606570 != nil:
    section.add "QueueName", valid_606570
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606571 = query.getOrDefault("Action")
  valid_606571 = validateParameter(valid_606571, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_606571 != nil:
    section.add "Action", valid_606571
  var valid_606572 = query.getOrDefault("Version")
  valid_606572 = validateParameter(valid_606572, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606572 != nil:
    section.add "Version", valid_606572
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
  var valid_606573 = header.getOrDefault("X-Amz-Signature")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Signature", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Content-Sha256", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Date")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Date", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Credential")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Credential", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Security-Token")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Security-Token", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Algorithm")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Algorithm", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-SignedHeaders", valid_606579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606580: Call_PostListDeadLetterSourceQueues_606566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_606580.validator(path, query, header, formData, body)
  let scheme = call_606580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606580.url(scheme.get, call_606580.host, call_606580.base,
                         call_606580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606580, url, valid)

proc call*(call_606581: Call_PostListDeadLetterSourceQueues_606566;
          AccountNumber: int; QueueName: string;
          Action: string = "ListDeadLetterSourceQueues";
          Version: string = "2012-11-05"): Recallable =
  ## postListDeadLetterSourceQueues
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606582 = newJObject()
  var query_606583 = newJObject()
  add(path_606582, "AccountNumber", newJInt(AccountNumber))
  add(path_606582, "QueueName", newJString(QueueName))
  add(query_606583, "Action", newJString(Action))
  add(query_606583, "Version", newJString(Version))
  result = call_606581.call(path_606582, query_606583, nil, nil, nil)

var postListDeadLetterSourceQueues* = Call_PostListDeadLetterSourceQueues_606566(
    name: "postListDeadLetterSourceQueues", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_PostListDeadLetterSourceQueues_606567, base: "/",
    url: url_PostListDeadLetterSourceQueues_606568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDeadLetterSourceQueues_606548 = ref object of OpenApiRestCall_605573
proc url_GetListDeadLetterSourceQueues_606550(protocol: Scheme; host: string;
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

proc validate_GetListDeadLetterSourceQueues_606549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606551 = path.getOrDefault("AccountNumber")
  valid_606551 = validateParameter(valid_606551, JInt, required = true, default = nil)
  if valid_606551 != nil:
    section.add "AccountNumber", valid_606551
  var valid_606552 = path.getOrDefault("QueueName")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "QueueName", valid_606552
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606553 = query.getOrDefault("Action")
  valid_606553 = validateParameter(valid_606553, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_606553 != nil:
    section.add "Action", valid_606553
  var valid_606554 = query.getOrDefault("Version")
  valid_606554 = validateParameter(valid_606554, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606554 != nil:
    section.add "Version", valid_606554
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
  var valid_606555 = header.getOrDefault("X-Amz-Signature")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Signature", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Content-Sha256", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Date")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Date", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Credential")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Credential", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Security-Token")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Security-Token", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Algorithm")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Algorithm", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-SignedHeaders", valid_606561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606562: Call_GetListDeadLetterSourceQueues_606548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_606562.validator(path, query, header, formData, body)
  let scheme = call_606562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606562.url(scheme.get, call_606562.host, call_606562.base,
                         call_606562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606562, url, valid)

proc call*(call_606563: Call_GetListDeadLetterSourceQueues_606548;
          AccountNumber: int; QueueName: string;
          Action: string = "ListDeadLetterSourceQueues";
          Version: string = "2012-11-05"): Recallable =
  ## getListDeadLetterSourceQueues
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606564 = newJObject()
  var query_606565 = newJObject()
  add(path_606564, "AccountNumber", newJInt(AccountNumber))
  add(path_606564, "QueueName", newJString(QueueName))
  add(query_606565, "Action", newJString(Action))
  add(query_606565, "Version", newJString(Version))
  result = call_606563.call(path_606564, query_606565, nil, nil, nil)

var getListDeadLetterSourceQueues* = Call_GetListDeadLetterSourceQueues_606548(
    name: "getListDeadLetterSourceQueues", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_GetListDeadLetterSourceQueues_606549, base: "/",
    url: url_GetListDeadLetterSourceQueues_606550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueueTags_606602 = ref object of OpenApiRestCall_605573
proc url_PostListQueueTags_606604(protocol: Scheme; host: string; base: string;
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

proc validate_PostListQueueTags_606603(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606605 = path.getOrDefault("AccountNumber")
  valid_606605 = validateParameter(valid_606605, JInt, required = true, default = nil)
  if valid_606605 != nil:
    section.add "AccountNumber", valid_606605
  var valid_606606 = path.getOrDefault("QueueName")
  valid_606606 = validateParameter(valid_606606, JString, required = true,
                                 default = nil)
  if valid_606606 != nil:
    section.add "QueueName", valid_606606
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606607 = query.getOrDefault("Action")
  valid_606607 = validateParameter(valid_606607, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_606607 != nil:
    section.add "Action", valid_606607
  var valid_606608 = query.getOrDefault("Version")
  valid_606608 = validateParameter(valid_606608, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606608 != nil:
    section.add "Version", valid_606608
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
  var valid_606609 = header.getOrDefault("X-Amz-Signature")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Signature", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Content-Sha256", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Date")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Date", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Credential")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Credential", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Security-Token")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Security-Token", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Algorithm")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Algorithm", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-SignedHeaders", valid_606615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606616: Call_PostListQueueTags_606602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606616.validator(path, query, header, formData, body)
  let scheme = call_606616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606616.url(scheme.get, call_606616.host, call_606616.base,
                         call_606616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606616, url, valid)

proc call*(call_606617: Call_PostListQueueTags_606602; AccountNumber: int;
          QueueName: string; Action: string = "ListQueueTags";
          Version: string = "2012-11-05"): Recallable =
  ## postListQueueTags
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606618 = newJObject()
  var query_606619 = newJObject()
  add(path_606618, "AccountNumber", newJInt(AccountNumber))
  add(path_606618, "QueueName", newJString(QueueName))
  add(query_606619, "Action", newJString(Action))
  add(query_606619, "Version", newJString(Version))
  result = call_606617.call(path_606618, query_606619, nil, nil, nil)

var postListQueueTags* = Call_PostListQueueTags_606602(name: "postListQueueTags",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_PostListQueueTags_606603, base: "/",
    url: url_PostListQueueTags_606604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueueTags_606584 = ref object of OpenApiRestCall_605573
proc url_GetListQueueTags_606586(protocol: Scheme; host: string; base: string;
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

proc validate_GetListQueueTags_606585(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606587 = path.getOrDefault("AccountNumber")
  valid_606587 = validateParameter(valid_606587, JInt, required = true, default = nil)
  if valid_606587 != nil:
    section.add "AccountNumber", valid_606587
  var valid_606588 = path.getOrDefault("QueueName")
  valid_606588 = validateParameter(valid_606588, JString, required = true,
                                 default = nil)
  if valid_606588 != nil:
    section.add "QueueName", valid_606588
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606589 = query.getOrDefault("Action")
  valid_606589 = validateParameter(valid_606589, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_606589 != nil:
    section.add "Action", valid_606589
  var valid_606590 = query.getOrDefault("Version")
  valid_606590 = validateParameter(valid_606590, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606590 != nil:
    section.add "Version", valid_606590
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
  var valid_606591 = header.getOrDefault("X-Amz-Signature")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Signature", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Content-Sha256", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Date")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Date", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Credential")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Credential", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Security-Token")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Security-Token", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Algorithm")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Algorithm", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-SignedHeaders", valid_606597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_GetListQueueTags_606584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_GetListQueueTags_606584; AccountNumber: int;
          QueueName: string; Action: string = "ListQueueTags";
          Version: string = "2012-11-05"): Recallable =
  ## getListQueueTags
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606600 = newJObject()
  var query_606601 = newJObject()
  add(path_606600, "AccountNumber", newJInt(AccountNumber))
  add(path_606600, "QueueName", newJString(QueueName))
  add(query_606601, "Action", newJString(Action))
  add(query_606601, "Version", newJString(Version))
  result = call_606599.call(path_606600, query_606601, nil, nil, nil)

var getListQueueTags* = Call_GetListQueueTags_606584(name: "getListQueueTags",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_GetListQueueTags_606585, base: "/",
    url: url_GetListQueueTags_606586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueues_606636 = ref object of OpenApiRestCall_605573
proc url_PostListQueues_606638(protocol: Scheme; host: string; base: string;
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

proc validate_PostListQueues_606637(path: JsonNode; query: JsonNode;
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
  var valid_606639 = query.getOrDefault("Action")
  valid_606639 = validateParameter(valid_606639, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_606639 != nil:
    section.add "Action", valid_606639
  var valid_606640 = query.getOrDefault("Version")
  valid_606640 = validateParameter(valid_606640, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606640 != nil:
    section.add "Version", valid_606640
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
  var valid_606641 = header.getOrDefault("X-Amz-Signature")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Signature", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Content-Sha256", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Date")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Date", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Credential")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Credential", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Security-Token")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Security-Token", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Algorithm")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Algorithm", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-SignedHeaders", valid_606647
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_606648 = formData.getOrDefault("QueueNamePrefix")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "QueueNamePrefix", valid_606648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606649: Call_PostListQueues_606636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606649.validator(path, query, header, formData, body)
  let scheme = call_606649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606649.url(scheme.get, call_606649.host, call_606649.base,
                         call_606649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606649, url, valid)

proc call*(call_606650: Call_PostListQueues_606636; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## postListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_606651 = newJObject()
  var formData_606652 = newJObject()
  add(query_606651, "Action", newJString(Action))
  add(formData_606652, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_606651, "Version", newJString(Version))
  result = call_606650.call(nil, query_606651, nil, formData_606652, nil)

var postListQueues* = Call_PostListQueues_606636(name: "postListQueues",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_PostListQueues_606637,
    base: "/", url: url_PostListQueues_606638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueues_606620 = ref object of OpenApiRestCall_605573
proc url_GetListQueues_606622(protocol: Scheme; host: string; base: string;
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

proc validate_GetListQueues_606621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606623 = query.getOrDefault("Action")
  valid_606623 = validateParameter(valid_606623, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_606623 != nil:
    section.add "Action", valid_606623
  var valid_606624 = query.getOrDefault("QueueNamePrefix")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "QueueNamePrefix", valid_606624
  var valid_606625 = query.getOrDefault("Version")
  valid_606625 = validateParameter(valid_606625, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606625 != nil:
    section.add "Version", valid_606625
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
  var valid_606626 = header.getOrDefault("X-Amz-Signature")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Signature", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Content-Sha256", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Date")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Date", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Credential")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Credential", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Security-Token")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Security-Token", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Algorithm")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Algorithm", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-SignedHeaders", valid_606632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606633: Call_GetListQueues_606620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606633.validator(path, query, header, formData, body)
  let scheme = call_606633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606633.url(scheme.get, call_606633.host, call_606633.base,
                         call_606633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606633, url, valid)

proc call*(call_606634: Call_GetListQueues_606620; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_606635 = newJObject()
  add(query_606635, "Action", newJString(Action))
  add(query_606635, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_606635, "Version", newJString(Version))
  result = call_606634.call(nil, query_606635, nil, nil, nil)

var getListQueues* = Call_GetListQueues_606620(name: "getListQueues",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_GetListQueues_606621,
    base: "/", url: url_GetListQueues_606622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurgeQueue_606671 = ref object of OpenApiRestCall_605573
proc url_PostPurgeQueue_606673(protocol: Scheme; host: string; base: string;
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

proc validate_PostPurgeQueue_606672(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606674 = path.getOrDefault("AccountNumber")
  valid_606674 = validateParameter(valid_606674, JInt, required = true, default = nil)
  if valid_606674 != nil:
    section.add "AccountNumber", valid_606674
  var valid_606675 = path.getOrDefault("QueueName")
  valid_606675 = validateParameter(valid_606675, JString, required = true,
                                 default = nil)
  if valid_606675 != nil:
    section.add "QueueName", valid_606675
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606676 = query.getOrDefault("Action")
  valid_606676 = validateParameter(valid_606676, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_606676 != nil:
    section.add "Action", valid_606676
  var valid_606677 = query.getOrDefault("Version")
  valid_606677 = validateParameter(valid_606677, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606677 != nil:
    section.add "Version", valid_606677
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
  var valid_606678 = header.getOrDefault("X-Amz-Signature")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Signature", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Content-Sha256", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Date")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Date", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Credential")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Credential", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Security-Token")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Security-Token", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Algorithm")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Algorithm", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-SignedHeaders", valid_606684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606685: Call_PostPurgeQueue_606671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_606685.validator(path, query, header, formData, body)
  let scheme = call_606685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606685.url(scheme.get, call_606685.host, call_606685.base,
                         call_606685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606685, url, valid)

proc call*(call_606686: Call_PostPurgeQueue_606671; AccountNumber: int;
          QueueName: string; Action: string = "PurgeQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postPurgeQueue
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606687 = newJObject()
  var query_606688 = newJObject()
  add(path_606687, "AccountNumber", newJInt(AccountNumber))
  add(path_606687, "QueueName", newJString(QueueName))
  add(query_606688, "Action", newJString(Action))
  add(query_606688, "Version", newJString(Version))
  result = call_606686.call(path_606687, query_606688, nil, nil, nil)

var postPurgeQueue* = Call_PostPurgeQueue_606671(name: "postPurgeQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_PostPurgeQueue_606672, base: "/", url: url_PostPurgeQueue_606673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurgeQueue_606653 = ref object of OpenApiRestCall_605573
proc url_GetPurgeQueue_606655(protocol: Scheme; host: string; base: string;
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

proc validate_GetPurgeQueue_606654(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606656 = path.getOrDefault("AccountNumber")
  valid_606656 = validateParameter(valid_606656, JInt, required = true, default = nil)
  if valid_606656 != nil:
    section.add "AccountNumber", valid_606656
  var valid_606657 = path.getOrDefault("QueueName")
  valid_606657 = validateParameter(valid_606657, JString, required = true,
                                 default = nil)
  if valid_606657 != nil:
    section.add "QueueName", valid_606657
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606658 = query.getOrDefault("Action")
  valid_606658 = validateParameter(valid_606658, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_606658 != nil:
    section.add "Action", valid_606658
  var valid_606659 = query.getOrDefault("Version")
  valid_606659 = validateParameter(valid_606659, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606659 != nil:
    section.add "Version", valid_606659
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
  var valid_606660 = header.getOrDefault("X-Amz-Signature")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Signature", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Content-Sha256", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Date")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Date", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Credential")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Credential", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Security-Token")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Security-Token", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Algorithm")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Algorithm", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-SignedHeaders", valid_606666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606667: Call_GetPurgeQueue_606653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_606667.validator(path, query, header, formData, body)
  let scheme = call_606667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606667.url(scheme.get, call_606667.host, call_606667.base,
                         call_606667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606667, url, valid)

proc call*(call_606668: Call_GetPurgeQueue_606653; AccountNumber: int;
          QueueName: string; Action: string = "PurgeQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getPurgeQueue
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606669 = newJObject()
  var query_606670 = newJObject()
  add(path_606669, "AccountNumber", newJInt(AccountNumber))
  add(path_606669, "QueueName", newJString(QueueName))
  add(query_606670, "Action", newJString(Action))
  add(query_606670, "Version", newJString(Version))
  result = call_606668.call(path_606669, query_606670, nil, nil, nil)

var getPurgeQueue* = Call_GetPurgeQueue_606653(name: "getPurgeQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_GetPurgeQueue_606654, base: "/", url: url_GetPurgeQueue_606655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostReceiveMessage_606713 = ref object of OpenApiRestCall_605573
proc url_PostReceiveMessage_606715(protocol: Scheme; host: string; base: string;
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

proc validate_PostReceiveMessage_606714(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606716 = path.getOrDefault("AccountNumber")
  valid_606716 = validateParameter(valid_606716, JInt, required = true, default = nil)
  if valid_606716 != nil:
    section.add "AccountNumber", valid_606716
  var valid_606717 = path.getOrDefault("QueueName")
  valid_606717 = validateParameter(valid_606717, JString, required = true,
                                 default = nil)
  if valid_606717 != nil:
    section.add "QueueName", valid_606717
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606718 = query.getOrDefault("Action")
  valid_606718 = validateParameter(valid_606718, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_606718 != nil:
    section.add "Action", valid_606718
  var valid_606719 = query.getOrDefault("Version")
  valid_606719 = validateParameter(valid_606719, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606719 != nil:
    section.add "Version", valid_606719
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
  var valid_606720 = header.getOrDefault("X-Amz-Signature")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Signature", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Content-Sha256", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Date")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Date", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Credential")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Credential", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Security-Token")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Security-Token", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Algorithm")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Algorithm", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-SignedHeaders", valid_606726
  result.add "header", section
  ## parameters in `formData` object:
  ##   WaitTimeSeconds: JInt
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   VisibilityTimeout: JInt
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  ##   ReceiveRequestAttemptId: JString
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   MaxNumberOfMessages: JInt
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  section = newJObject()
  var valid_606727 = formData.getOrDefault("WaitTimeSeconds")
  valid_606727 = validateParameter(valid_606727, JInt, required = false, default = nil)
  if valid_606727 != nil:
    section.add "WaitTimeSeconds", valid_606727
  var valid_606728 = formData.getOrDefault("MessageAttributeNames")
  valid_606728 = validateParameter(valid_606728, JArray, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "MessageAttributeNames", valid_606728
  var valid_606729 = formData.getOrDefault("VisibilityTimeout")
  valid_606729 = validateParameter(valid_606729, JInt, required = false, default = nil)
  if valid_606729 != nil:
    section.add "VisibilityTimeout", valid_606729
  var valid_606730 = formData.getOrDefault("ReceiveRequestAttemptId")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "ReceiveRequestAttemptId", valid_606730
  var valid_606731 = formData.getOrDefault("AttributeNames")
  valid_606731 = validateParameter(valid_606731, JArray, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "AttributeNames", valid_606731
  var valid_606732 = formData.getOrDefault("MaxNumberOfMessages")
  valid_606732 = validateParameter(valid_606732, JInt, required = false, default = nil)
  if valid_606732 != nil:
    section.add "MaxNumberOfMessages", valid_606732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_PostReceiveMessage_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_PostReceiveMessage_606713; AccountNumber: int;
          QueueName: string; WaitTimeSeconds: int = 0;
          MessageAttributeNames: JsonNode = nil; VisibilityTimeout: int = 0;
          ReceiveRequestAttemptId: string = ""; AttributeNames: JsonNode = nil;
          Action: string = "ReceiveMessage"; Version: string = "2012-11-05";
          MaxNumberOfMessages: int = 0): Recallable =
  ## postReceiveMessage
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ##   WaitTimeSeconds: int
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   VisibilityTimeout: int
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  ##   ReceiveRequestAttemptId: string
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxNumberOfMessages: int
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  var path_606735 = newJObject()
  var query_606736 = newJObject()
  var formData_606737 = newJObject()
  add(formData_606737, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  add(path_606735, "AccountNumber", newJInt(AccountNumber))
  add(path_606735, "QueueName", newJString(QueueName))
  if MessageAttributeNames != nil:
    formData_606737.add "MessageAttributeNames", MessageAttributeNames
  add(formData_606737, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(formData_606737, "ReceiveRequestAttemptId",
      newJString(ReceiveRequestAttemptId))
  if AttributeNames != nil:
    formData_606737.add "AttributeNames", AttributeNames
  add(query_606736, "Action", newJString(Action))
  add(query_606736, "Version", newJString(Version))
  add(formData_606737, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  result = call_606734.call(path_606735, query_606736, nil, formData_606737, nil)

var postReceiveMessage* = Call_PostReceiveMessage_606713(
    name: "postReceiveMessage", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_PostReceiveMessage_606714, base: "/",
    url: url_PostReceiveMessage_606715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReceiveMessage_606689 = ref object of OpenApiRestCall_605573
proc url_GetReceiveMessage_606691(protocol: Scheme; host: string; base: string;
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

proc validate_GetReceiveMessage_606690(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606692 = path.getOrDefault("AccountNumber")
  valid_606692 = validateParameter(valid_606692, JInt, required = true, default = nil)
  if valid_606692 != nil:
    section.add "AccountNumber", valid_606692
  var valid_606693 = path.getOrDefault("QueueName")
  valid_606693 = validateParameter(valid_606693, JString, required = true,
                                 default = nil)
  if valid_606693 != nil:
    section.add "QueueName", valid_606693
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxNumberOfMessages: JInt
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   ReceiveRequestAttemptId: JString
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   WaitTimeSeconds: JInt
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   VisibilityTimeout: JInt
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  section = newJObject()
  var valid_606694 = query.getOrDefault("MaxNumberOfMessages")
  valid_606694 = validateParameter(valid_606694, JInt, required = false, default = nil)
  if valid_606694 != nil:
    section.add "MaxNumberOfMessages", valid_606694
  var valid_606695 = query.getOrDefault("AttributeNames")
  valid_606695 = validateParameter(valid_606695, JArray, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "AttributeNames", valid_606695
  var valid_606696 = query.getOrDefault("MessageAttributeNames")
  valid_606696 = validateParameter(valid_606696, JArray, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "MessageAttributeNames", valid_606696
  var valid_606697 = query.getOrDefault("ReceiveRequestAttemptId")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "ReceiveRequestAttemptId", valid_606697
  var valid_606698 = query.getOrDefault("Action")
  valid_606698 = validateParameter(valid_606698, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_606698 != nil:
    section.add "Action", valid_606698
  var valid_606699 = query.getOrDefault("Version")
  valid_606699 = validateParameter(valid_606699, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606699 != nil:
    section.add "Version", valid_606699
  var valid_606700 = query.getOrDefault("WaitTimeSeconds")
  valid_606700 = validateParameter(valid_606700, JInt, required = false, default = nil)
  if valid_606700 != nil:
    section.add "WaitTimeSeconds", valid_606700
  var valid_606701 = query.getOrDefault("VisibilityTimeout")
  valid_606701 = validateParameter(valid_606701, JInt, required = false, default = nil)
  if valid_606701 != nil:
    section.add "VisibilityTimeout", valid_606701
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
  var valid_606702 = header.getOrDefault("X-Amz-Signature")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Signature", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Content-Sha256", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Date")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Date", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Credential")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Credential", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Security-Token")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Security-Token", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Algorithm")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Algorithm", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-SignedHeaders", valid_606708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606709: Call_GetReceiveMessage_606689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_606709.validator(path, query, header, formData, body)
  let scheme = call_606709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606709.url(scheme.get, call_606709.host, call_606709.base,
                         call_606709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606709, url, valid)

proc call*(call_606710: Call_GetReceiveMessage_606689; AccountNumber: int;
          QueueName: string; MaxNumberOfMessages: int = 0;
          AttributeNames: JsonNode = nil; MessageAttributeNames: JsonNode = nil;
          ReceiveRequestAttemptId: string = ""; Action: string = "ReceiveMessage";
          Version: string = "2012-11-05"; WaitTimeSeconds: int = 0;
          VisibilityTimeout: int = 0): Recallable =
  ## getReceiveMessage
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ##   MaxNumberOfMessages: int
  ##                      : The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   AttributeNames: JArray
  ##                 : <p>A list of attributes that need to be returned along with each message. These attributes include:</p> <ul> <li> <p> <code>All</code> - Returns all values.</p> </li> <li> <p> <code>ApproximateFirstReceiveTimestamp</code> - Returns the time the message was first received from the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>ApproximateReceiveCount</code> - Returns the number of times a message has been received from the queue but not deleted.</p> </li> <li> <p> <code>AWSTraceHeader</code> - Returns the AWS X-Ray trace header string. </p> </li> <li> <p> <code>SenderId</code> </p> <ul> <li> <p>For an IAM user, returns the IAM user ID, for example <code>ABCDEFGHI1JKLMNOPQ23R</code>.</p> </li> <li> <p>For an IAM role, returns the IAM role ID, for example <code>ABCDE1F2GH3I4JK5LMNOP:i-a123b456</code>.</p> </li> </ul> </li> <li> <p> <code>SentTimestamp</code> - Returns the time the message was sent to the queue (<a href="http://en.wikipedia.org/wiki/Unix_time">epoch time</a> in milliseconds).</p> </li> <li> <p> <code>MessageDeduplicationId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action.</p> </li> <li> <p> <code>MessageGroupId</code> - Returns the value provided by the producer that calls the <code> <a>SendMessage</a> </code> action. Messages with the same <code>MessageGroupId</code> are returned in sequence.</p> </li> <li> <p> <code>SequenceNumber</code> - Returns the value provided by Amazon SQS.</p> </li> </ul>
  ##   MessageAttributeNames: JArray
  ##                        : <p>The name of the message attribute, where <i>N</i> is the index.</p> <ul> <li> <p>The name can contain alphanumeric characters and the underscore (<code>_</code>), hyphen (<code>-</code>), and period (<code>.</code>).</p> </li> <li> <p>The name is case-sensitive and must be unique among all attribute names for the message.</p> </li> <li> <p>The name must not start with AWS-reserved prefixes such as <code>AWS.</code> or <code>Amazon.</code> (or any casing variants).</p> </li> <li> <p>The name must not start or end with a period (<code>.</code>), and it should not have periods in succession (<code>..</code>).</p> </li> <li> <p>The name can be up to 256 characters long.</p> </li> </ul> <p>When using <code>ReceiveMessage</code>, you can send a list of attribute names to receive, or you can return all of the attributes by specifying <code>All</code> or <code>.*</code> in your request. You can also use all message attributes starting with a prefix, for example <code>bar.*</code>.</p>
  ##   ReceiveRequestAttemptId: string
  ##                          : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of <code>ReceiveMessage</code> calls. If a networking issue occurs after a <code>ReceiveMessage</code> action, and instead of a response you receive a generic error, you can retry the same action with an identical <code>ReceiveRequestAttemptId</code> to retrieve the same set of messages, even if their visibility timeout has not yet expired.</p> <ul> <li> <p>You can use <code>ReceiveRequestAttemptId</code> only for 5 minutes after a <code>ReceiveMessage</code> action.</p> </li> <li> <p>When you set <code>FifoQueue</code>, a caller of the <code>ReceiveMessage</code> action can provide a <code>ReceiveRequestAttemptId</code> explicitly.</p> </li> <li> <p>If a caller of the <code>ReceiveMessage</code> action doesn't provide a <code>ReceiveRequestAttemptId</code>, Amazon SQS generates a <code>ReceiveRequestAttemptId</code>.</p> </li> <li> <p>You can retry the <code>ReceiveMessage</code> action with the same <code>ReceiveRequestAttemptId</code> if none of the messages have been modified (deleted or had their visibility changes).</p> </li> <li> <p>During a visibility timeout, subsequent calls with the same <code>ReceiveRequestAttemptId</code> return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p>If a caller of the <code>ReceiveMessage</code> action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error.</p> <p>To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary.</p> </important> </li> <li> <p>While messages with a particular <code>MessageGroupId</code> are invisible, no more messages belonging to the same <code>MessageGroupId</code> are returned until the visibility timeout expires. You can still receive messages with another <code>MessageGroupId</code> as long as it is also visible.</p> </li> <li> <p>If a caller of <code>ReceiveMessage</code> can't track the <code>ReceiveRequestAttemptId</code>, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order.</p> </li> </ul> <p>The length of <code>ReceiveRequestAttemptId</code> is 128 characters. <code>ReceiveRequestAttemptId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>ReceiveRequestAttemptId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html">Using the ReceiveRequestAttemptId Request Parameter</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   WaitTimeSeconds: int
  ##                  : The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than <code>WaitTimeSeconds</code>. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages.
  ##   VisibilityTimeout: int
  ##                    : The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a <code>ReceiveMessage</code> request.
  var path_606711 = newJObject()
  var query_606712 = newJObject()
  add(query_606712, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(path_606711, "AccountNumber", newJInt(AccountNumber))
  add(path_606711, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    query_606712.add "AttributeNames", AttributeNames
  if MessageAttributeNames != nil:
    query_606712.add "MessageAttributeNames", MessageAttributeNames
  add(query_606712, "ReceiveRequestAttemptId", newJString(ReceiveRequestAttemptId))
  add(query_606712, "Action", newJString(Action))
  add(query_606712, "Version", newJString(Version))
  add(query_606712, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  add(query_606712, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_606710.call(path_606711, query_606712, nil, nil, nil)

var getReceiveMessage* = Call_GetReceiveMessage_606689(name: "getReceiveMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_GetReceiveMessage_606690, base: "/",
    url: url_GetReceiveMessage_606691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_606757 = ref object of OpenApiRestCall_605573
proc url_PostRemovePermission_606759(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_606758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606760 = path.getOrDefault("AccountNumber")
  valid_606760 = validateParameter(valid_606760, JInt, required = true, default = nil)
  if valid_606760 != nil:
    section.add "AccountNumber", valid_606760
  var valid_606761 = path.getOrDefault("QueueName")
  valid_606761 = validateParameter(valid_606761, JString, required = true,
                                 default = nil)
  if valid_606761 != nil:
    section.add "QueueName", valid_606761
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606762 = query.getOrDefault("Action")
  valid_606762 = validateParameter(valid_606762, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_606762 != nil:
    section.add "Action", valid_606762
  var valid_606763 = query.getOrDefault("Version")
  valid_606763 = validateParameter(valid_606763, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606763 != nil:
    section.add "Version", valid_606763
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
  var valid_606764 = header.getOrDefault("X-Amz-Signature")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Signature", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Content-Sha256", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Date")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Date", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Credential")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Credential", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Security-Token")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Security-Token", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Algorithm")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Algorithm", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-SignedHeaders", valid_606770
  result.add "header", section
  ## parameters in `formData` object:
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Label` field"
  var valid_606771 = formData.getOrDefault("Label")
  valid_606771 = validateParameter(valid_606771, JString, required = true,
                                 default = nil)
  if valid_606771 != nil:
    section.add "Label", valid_606771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606772: Call_PostRemovePermission_606757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_606772.validator(path, query, header, formData, body)
  let scheme = call_606772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606772.url(scheme.get, call_606772.host, call_606772.base,
                         call_606772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606772, url, valid)

proc call*(call_606773: Call_PostRemovePermission_606757; AccountNumber: int;
          QueueName: string; Label: string; Action: string = "RemovePermission";
          Version: string = "2012-11-05"): Recallable =
  ## postRemovePermission
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Label: string (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  ##   Version: string (required)
  var path_606774 = newJObject()
  var query_606775 = newJObject()
  var formData_606776 = newJObject()
  add(path_606774, "AccountNumber", newJInt(AccountNumber))
  add(path_606774, "QueueName", newJString(QueueName))
  add(query_606775, "Action", newJString(Action))
  add(formData_606776, "Label", newJString(Label))
  add(query_606775, "Version", newJString(Version))
  result = call_606773.call(path_606774, query_606775, nil, formData_606776, nil)

var postRemovePermission* = Call_PostRemovePermission_606757(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_PostRemovePermission_606758, base: "/",
    url: url_PostRemovePermission_606759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_606738 = ref object of OpenApiRestCall_605573
proc url_GetRemovePermission_606740(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_606739(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606741 = path.getOrDefault("AccountNumber")
  valid_606741 = validateParameter(valid_606741, JInt, required = true, default = nil)
  if valid_606741 != nil:
    section.add "AccountNumber", valid_606741
  var valid_606742 = path.getOrDefault("QueueName")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = nil)
  if valid_606742 != nil:
    section.add "QueueName", valid_606742
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  var valid_606743 = query.getOrDefault("Action")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_606743 != nil:
    section.add "Action", valid_606743
  var valid_606744 = query.getOrDefault("Version")
  valid_606744 = validateParameter(valid_606744, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606744 != nil:
    section.add "Version", valid_606744
  var valid_606745 = query.getOrDefault("Label")
  valid_606745 = validateParameter(valid_606745, JString, required = true,
                                 default = nil)
  if valid_606745 != nil:
    section.add "Label", valid_606745
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
  var valid_606746 = header.getOrDefault("X-Amz-Signature")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Signature", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Content-Sha256", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Date")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Date", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Credential")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Credential", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Security-Token")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Security-Token", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Algorithm")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Algorithm", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-SignedHeaders", valid_606752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606753: Call_GetRemovePermission_606738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_606753.validator(path, query, header, formData, body)
  let scheme = call_606753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606753.url(scheme.get, call_606753.host, call_606753.base,
                         call_606753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606753, url, valid)

proc call*(call_606754: Call_GetRemovePermission_606738; AccountNumber: int;
          QueueName: string; Label: string; Action: string = "RemovePermission";
          Version: string = "2012-11-05"): Recallable =
  ## getRemovePermission
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  var path_606755 = newJObject()
  var query_606756 = newJObject()
  add(path_606755, "AccountNumber", newJInt(AccountNumber))
  add(path_606755, "QueueName", newJString(QueueName))
  add(query_606756, "Action", newJString(Action))
  add(query_606756, "Version", newJString(Version))
  add(query_606756, "Label", newJString(Label))
  result = call_606754.call(path_606755, query_606756, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_606738(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_GetRemovePermission_606739, base: "/",
    url: url_GetRemovePermission_606740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessage_606811 = ref object of OpenApiRestCall_605573
proc url_PostSendMessage_606813(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessage_606812(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606814 = path.getOrDefault("AccountNumber")
  valid_606814 = validateParameter(valid_606814, JInt, required = true, default = nil)
  if valid_606814 != nil:
    section.add "AccountNumber", valid_606814
  var valid_606815 = path.getOrDefault("QueueName")
  valid_606815 = validateParameter(valid_606815, JString, required = true,
                                 default = nil)
  if valid_606815 != nil:
    section.add "QueueName", valid_606815
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606816 = query.getOrDefault("Action")
  valid_606816 = validateParameter(valid_606816, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_606816 != nil:
    section.add "Action", valid_606816
  var valid_606817 = query.getOrDefault("Version")
  valid_606817 = validateParameter(valid_606817, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606817 != nil:
    section.add "Version", valid_606817
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
  var valid_606818 = header.getOrDefault("X-Amz-Signature")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Signature", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Content-Sha256", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Date")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Date", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-Credential")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-Credential", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Security-Token")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Security-Token", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Algorithm")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Algorithm", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-SignedHeaders", valid_606824
  result.add "header", section
  ## parameters in `formData` object:
  ##   MessageDeduplicationId: JString
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   DelaySeconds: JInt
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageAttribute.1.key: JString
  ##   MessageAttribute.0.value: JString
  ##   MessageSystemAttribute.0.key: JString
  ##   MessageAttribute.2.value: JString
  ##   MessageSystemAttribute.0.value: JString
  ##   MessageAttribute.1.value: JString
  ##   MessageGroupId: JString
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageBody: JString (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageSystemAttribute.1.value: JString
  ##   MessageSystemAttribute.1.key: JString
  ##   MessageSystemAttribute.2.key: JString
  ##   MessageAttribute.0.key: JString
  ##   MessageAttribute.2.key: JString
  ##   MessageSystemAttribute.2.value: JString
  section = newJObject()
  var valid_606825 = formData.getOrDefault("MessageDeduplicationId")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "MessageDeduplicationId", valid_606825
  var valid_606826 = formData.getOrDefault("DelaySeconds")
  valid_606826 = validateParameter(valid_606826, JInt, required = false, default = nil)
  if valid_606826 != nil:
    section.add "DelaySeconds", valid_606826
  var valid_606827 = formData.getOrDefault("MessageAttribute.1.key")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "MessageAttribute.1.key", valid_606827
  var valid_606828 = formData.getOrDefault("MessageAttribute.0.value")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "MessageAttribute.0.value", valid_606828
  var valid_606829 = formData.getOrDefault("MessageSystemAttribute.0.key")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "MessageSystemAttribute.0.key", valid_606829
  var valid_606830 = formData.getOrDefault("MessageAttribute.2.value")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "MessageAttribute.2.value", valid_606830
  var valid_606831 = formData.getOrDefault("MessageSystemAttribute.0.value")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "MessageSystemAttribute.0.value", valid_606831
  var valid_606832 = formData.getOrDefault("MessageAttribute.1.value")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "MessageAttribute.1.value", valid_606832
  var valid_606833 = formData.getOrDefault("MessageGroupId")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "MessageGroupId", valid_606833
  assert formData != nil,
        "formData argument is necessary due to required `MessageBody` field"
  var valid_606834 = formData.getOrDefault("MessageBody")
  valid_606834 = validateParameter(valid_606834, JString, required = true,
                                 default = nil)
  if valid_606834 != nil:
    section.add "MessageBody", valid_606834
  var valid_606835 = formData.getOrDefault("MessageSystemAttribute.1.value")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "MessageSystemAttribute.1.value", valid_606835
  var valid_606836 = formData.getOrDefault("MessageSystemAttribute.1.key")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "MessageSystemAttribute.1.key", valid_606836
  var valid_606837 = formData.getOrDefault("MessageSystemAttribute.2.key")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "MessageSystemAttribute.2.key", valid_606837
  var valid_606838 = formData.getOrDefault("MessageAttribute.0.key")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "MessageAttribute.0.key", valid_606838
  var valid_606839 = formData.getOrDefault("MessageAttribute.2.key")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "MessageAttribute.2.key", valid_606839
  var valid_606840 = formData.getOrDefault("MessageSystemAttribute.2.value")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "MessageSystemAttribute.2.value", valid_606840
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606841: Call_PostSendMessage_606811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_606841.validator(path, query, header, formData, body)
  let scheme = call_606841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606841.url(scheme.get, call_606841.host, call_606841.base,
                         call_606841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606841, url, valid)

proc call*(call_606842: Call_PostSendMessage_606811; AccountNumber: int;
          QueueName: string; MessageBody: string;
          MessageDeduplicationId: string = ""; DelaySeconds: int = 0;
          MessageAttribute1Key: string = ""; MessageAttribute0Value: string = "";
          MessageSystemAttribute0Key: string = "";
          MessageAttribute2Value: string = "";
          MessageSystemAttribute0Value: string = "";
          MessageAttribute1Value: string = ""; MessageGroupId: string = "";
          MessageSystemAttribute1Value: string = "";
          MessageSystemAttribute1Key: string = ""; Action: string = "SendMessage";
          MessageSystemAttribute2Key: string = "";
          MessageAttribute0Key: string = ""; MessageAttribute2Key: string = "";
          Version: string = "2012-11-05"; MessageSystemAttribute2Value: string = ""): Recallable =
  ## postSendMessage
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageDeduplicationId: string
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   DelaySeconds: int
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageAttribute1Key: string
  ##   MessageAttribute0Value: string
  ##   MessageSystemAttribute0Key: string
  ##   MessageAttribute2Value: string
  ##   MessageSystemAttribute0Value: string
  ##   MessageAttribute1Value: string
  ##   MessageGroupId: string
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageBody: string (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageSystemAttribute1Value: string
  ##   MessageSystemAttribute1Key: string
  ##   Action: string (required)
  ##   MessageSystemAttribute2Key: string
  ##   MessageAttribute0Key: string
  ##   MessageAttribute2Key: string
  ##   Version: string (required)
  ##   MessageSystemAttribute2Value: string
  var path_606843 = newJObject()
  var query_606844 = newJObject()
  var formData_606845 = newJObject()
  add(formData_606845, "MessageDeduplicationId",
      newJString(MessageDeduplicationId))
  add(path_606843, "AccountNumber", newJInt(AccountNumber))
  add(path_606843, "QueueName", newJString(QueueName))
  add(formData_606845, "DelaySeconds", newJInt(DelaySeconds))
  add(formData_606845, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(formData_606845, "MessageAttribute.0.value",
      newJString(MessageAttribute0Value))
  add(formData_606845, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(formData_606845, "MessageAttribute.2.value",
      newJString(MessageAttribute2Value))
  add(formData_606845, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(formData_606845, "MessageAttribute.1.value",
      newJString(MessageAttribute1Value))
  add(formData_606845, "MessageGroupId", newJString(MessageGroupId))
  add(formData_606845, "MessageBody", newJString(MessageBody))
  add(formData_606845, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(formData_606845, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_606844, "Action", newJString(Action))
  add(formData_606845, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(formData_606845, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(formData_606845, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(query_606844, "Version", newJString(Version))
  add(formData_606845, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  result = call_606842.call(path_606843, query_606844, nil, formData_606845, nil)

var postSendMessage* = Call_PostSendMessage_606811(name: "postSendMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_PostSendMessage_606812, base: "/", url: url_PostSendMessage_606813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessage_606777 = ref object of OpenApiRestCall_605573
proc url_GetSendMessage_606779(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessage_606778(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606780 = path.getOrDefault("AccountNumber")
  valid_606780 = validateParameter(valid_606780, JInt, required = true, default = nil)
  if valid_606780 != nil:
    section.add "AccountNumber", valid_606780
  var valid_606781 = path.getOrDefault("QueueName")
  valid_606781 = validateParameter(valid_606781, JString, required = true,
                                 default = nil)
  if valid_606781 != nil:
    section.add "QueueName", valid_606781
  result.add "path", section
  ## parameters in `query` object:
  ##   MessageAttribute.2.key: JString
  ##   MessageDeduplicationId: JString
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   MessageSystemAttribute.0.value: JString
  ##   MessageAttribute.1.key: JString
  ##   MessageSystemAttribute.1.value: JString
  ##   DelaySeconds: JInt
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageSystemAttribute.2.value: JString
  ##   MessageAttribute.0.value: JString
  ##   MessageBody: JString (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageAttribute.2.value: JString
  ##   MessageGroupId: JString
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageSystemAttribute.2.key: JString
  ##   Action: JString (required)
  ##   MessageSystemAttribute.0.key: JString
  ##   MessageAttribute.0.key: JString
  ##   Version: JString (required)
  ##   MessageSystemAttribute.1.key: JString
  ##   MessageAttribute.1.value: JString
  section = newJObject()
  var valid_606782 = query.getOrDefault("MessageAttribute.2.key")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "MessageAttribute.2.key", valid_606782
  var valid_606783 = query.getOrDefault("MessageDeduplicationId")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "MessageDeduplicationId", valid_606783
  var valid_606784 = query.getOrDefault("MessageSystemAttribute.0.value")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "MessageSystemAttribute.0.value", valid_606784
  var valid_606785 = query.getOrDefault("MessageAttribute.1.key")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "MessageAttribute.1.key", valid_606785
  var valid_606786 = query.getOrDefault("MessageSystemAttribute.1.value")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "MessageSystemAttribute.1.value", valid_606786
  var valid_606787 = query.getOrDefault("DelaySeconds")
  valid_606787 = validateParameter(valid_606787, JInt, required = false, default = nil)
  if valid_606787 != nil:
    section.add "DelaySeconds", valid_606787
  var valid_606788 = query.getOrDefault("MessageSystemAttribute.2.value")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "MessageSystemAttribute.2.value", valid_606788
  var valid_606789 = query.getOrDefault("MessageAttribute.0.value")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "MessageAttribute.0.value", valid_606789
  assert query != nil,
        "query argument is necessary due to required `MessageBody` field"
  var valid_606790 = query.getOrDefault("MessageBody")
  valid_606790 = validateParameter(valid_606790, JString, required = true,
                                 default = nil)
  if valid_606790 != nil:
    section.add "MessageBody", valid_606790
  var valid_606791 = query.getOrDefault("MessageAttribute.2.value")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "MessageAttribute.2.value", valid_606791
  var valid_606792 = query.getOrDefault("MessageGroupId")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "MessageGroupId", valid_606792
  var valid_606793 = query.getOrDefault("MessageSystemAttribute.2.key")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "MessageSystemAttribute.2.key", valid_606793
  var valid_606794 = query.getOrDefault("Action")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_606794 != nil:
    section.add "Action", valid_606794
  var valid_606795 = query.getOrDefault("MessageSystemAttribute.0.key")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "MessageSystemAttribute.0.key", valid_606795
  var valid_606796 = query.getOrDefault("MessageAttribute.0.key")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "MessageAttribute.0.key", valid_606796
  var valid_606797 = query.getOrDefault("Version")
  valid_606797 = validateParameter(valid_606797, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606797 != nil:
    section.add "Version", valid_606797
  var valid_606798 = query.getOrDefault("MessageSystemAttribute.1.key")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "MessageSystemAttribute.1.key", valid_606798
  var valid_606799 = query.getOrDefault("MessageAttribute.1.value")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "MessageAttribute.1.value", valid_606799
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
  var valid_606800 = header.getOrDefault("X-Amz-Signature")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Signature", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Content-Sha256", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Date")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Date", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Credential")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Credential", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Security-Token")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Security-Token", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Algorithm")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Algorithm", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-SignedHeaders", valid_606806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606807: Call_GetSendMessage_606777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_606807.validator(path, query, header, formData, body)
  let scheme = call_606807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606807.url(scheme.get, call_606807.host, call_606807.base,
                         call_606807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606807, url, valid)

proc call*(call_606808: Call_GetSendMessage_606777; AccountNumber: int;
          QueueName: string; MessageBody: string; MessageAttribute2Key: string = "";
          MessageDeduplicationId: string = "";
          MessageSystemAttribute0Value: string = "";
          MessageAttribute1Key: string = "";
          MessageSystemAttribute1Value: string = ""; DelaySeconds: int = 0;
          MessageSystemAttribute2Value: string = "";
          MessageAttribute0Value: string = ""; MessageAttribute2Value: string = "";
          MessageGroupId: string = ""; MessageSystemAttribute2Key: string = "";
          Action: string = "SendMessage"; MessageSystemAttribute0Key: string = "";
          MessageAttribute0Key: string = ""; Version: string = "2012-11-05";
          MessageSystemAttribute1Key: string = "";
          MessageAttribute1Value: string = ""): Recallable =
  ## getSendMessage
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageAttribute2Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   MessageDeduplicationId: string
  ##                         : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The token used for deduplication of sent messages. If a message with a particular <code>MessageDeduplicationId</code> is sent successfully, any messages sent with the same <code>MessageDeduplicationId</code> are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-exactly-once-processing"> Exactly-Once Processing</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <ul> <li> <p>Every message must have a unique <code>MessageDeduplicationId</code>,</p> <ul> <li> <p>You may provide a <code>MessageDeduplicationId</code> explicitly.</p> </li> <li> <p>If you aren't able to provide a <code>MessageDeduplicationId</code> and you enable <code>ContentBasedDeduplication</code> for your queue, Amazon SQS uses a SHA-256 hash to generate the <code>MessageDeduplicationId</code> using the body of the message (but not the attributes of the message). </p> </li> <li> <p>If you don't provide a <code>MessageDeduplicationId</code> and the queue doesn't have <code>ContentBasedDeduplication</code> set, the action fails with an error.</p> </li> <li> <p>If the queue has <code>ContentBasedDeduplication</code> set, your <code>MessageDeduplicationId</code> overrides the generated one.</p> </li> </ul> </li> <li> <p>When <code>ContentBasedDeduplication</code> is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered.</p> </li> <li> <p>If you send one message with <code>ContentBasedDeduplication</code> enabled and then another message with a <code>MessageDeduplicationId</code> that is the same as the one generated for the first <code>MessageDeduplicationId</code>, the two messages are treated as duplicates and only one copy of the message is delivered. </p> </li> </ul> <note> <p>The <code>MessageDeduplicationId</code> is available to the consumer of the message (this can be useful for troubleshooting delivery issues).</p> <p>If a message is sent successfully but the acknowledgement is lost and the message is resent with the same <code>MessageDeduplicationId</code> after the deduplication interval, Amazon SQS can't detect duplicate messages.</p> <p>Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted.</p> </note> <p>The length of <code>MessageDeduplicationId</code> is 128 characters. <code>MessageDeduplicationId</code> can contain alphanumeric characters (<code>a-z</code>, <code>A-Z</code>, <code>0-9</code>) and punctuation (<code>!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~</code>).</p> <p>For best practices of using <code>MessageDeduplicationId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html">Using the MessageDeduplicationId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ##   MessageSystemAttribute0Value: string
  ##   MessageAttribute1Key: string
  ##   MessageSystemAttribute1Value: string
  ##   DelaySeconds: int
  ##               : <p> The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive <code>DelaySeconds</code> value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. </p> <note> <p>When you set <code>FifoQueue</code>, you can't set <code>DelaySeconds</code> per message. You can set this parameter only on a queue level.</p> </note>
  ##   MessageSystemAttribute2Value: string
  ##   MessageAttribute0Value: string
  ##   MessageBody: string (required)
  ##              : <p>The message to send. The maximum string size is 256 KB.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ##   MessageAttribute2Value: string
  ##   MessageGroupId: string
  ##                 : <p>This parameter applies only to FIFO (first-in-first-out) queues.</p> <p>The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use <code>MessageGroupId</code> values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion.</p> <ul> <li> <p>You must associate a non-empty <code>MessageGroupId</code> with a message. If you don't provide a <code>MessageGroupId</code>, the action fails.</p> </li> <li> <p> <code>ReceiveMessage</code> might return messages with multiple <code>MessageGroupId</code> values. For each <code>MessageGroupId</code>, the messages are sorted by time sent. The caller can't specify a <code>MessageGroupId</code>.</p> </li> </ul> <p>The length of <code>MessageGroupId</code> is 128 characters. Valid values: alphanumeric characters and punctuation <code>(!"#$%&amp;'()*+,-./:;&lt;=&gt;?@[\]^_`{|}~)</code>.</p> <p>For best practices of using <code>MessageGroupId</code>, see <a 
  ## href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html">Using the MessageGroupId Property</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <important> <p> <code>MessageGroupId</code> is required for FIFO queues. You can't use it for Standard queues.</p> </important>
  ##   MessageSystemAttribute2Key: string
  ##   Action: string (required)
  ##   MessageSystemAttribute0Key: string
  ##   MessageAttribute0Key: string
  ##   Version: string (required)
  ##   MessageSystemAttribute1Key: string
  ##   MessageAttribute1Value: string
  var path_606809 = newJObject()
  var query_606810 = newJObject()
  add(query_606810, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(path_606809, "AccountNumber", newJInt(AccountNumber))
  add(path_606809, "QueueName", newJString(QueueName))
  add(query_606810, "MessageDeduplicationId", newJString(MessageDeduplicationId))
  add(query_606810, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(query_606810, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(query_606810, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(query_606810, "DelaySeconds", newJInt(DelaySeconds))
  add(query_606810, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(query_606810, "MessageAttribute.0.value", newJString(MessageAttribute0Value))
  add(query_606810, "MessageBody", newJString(MessageBody))
  add(query_606810, "MessageAttribute.2.value", newJString(MessageAttribute2Value))
  add(query_606810, "MessageGroupId", newJString(MessageGroupId))
  add(query_606810, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(query_606810, "Action", newJString(Action))
  add(query_606810, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(query_606810, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(query_606810, "Version", newJString(Version))
  add(query_606810, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_606810, "MessageAttribute.1.value", newJString(MessageAttribute1Value))
  result = call_606808.call(path_606809, query_606810, nil, nil, nil)

var getSendMessage* = Call_GetSendMessage_606777(name: "getSendMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_GetSendMessage_606778, base: "/", url: url_GetSendMessage_606779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessageBatch_606865 = ref object of OpenApiRestCall_605573
proc url_PostSendMessageBatch_606867(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessageBatch_606866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606868 = path.getOrDefault("AccountNumber")
  valid_606868 = validateParameter(valid_606868, JInt, required = true, default = nil)
  if valid_606868 != nil:
    section.add "AccountNumber", valid_606868
  var valid_606869 = path.getOrDefault("QueueName")
  valid_606869 = validateParameter(valid_606869, JString, required = true,
                                 default = nil)
  if valid_606869 != nil:
    section.add "QueueName", valid_606869
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606870 = query.getOrDefault("Action")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_606870 != nil:
    section.add "Action", valid_606870
  var valid_606871 = query.getOrDefault("Version")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606871 != nil:
    section.add "Version", valid_606871
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
  var valid_606872 = header.getOrDefault("X-Amz-Signature")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Signature", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Content-Sha256", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Date")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Date", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Credential")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Credential", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Security-Token")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Security-Token", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Algorithm")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Algorithm", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-SignedHeaders", valid_606878
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_606879 = formData.getOrDefault("Entries")
  valid_606879 = validateParameter(valid_606879, JArray, required = true, default = nil)
  if valid_606879 != nil:
    section.add "Entries", valid_606879
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606880: Call_PostSendMessageBatch_606865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606880.validator(path, query, header, formData, body)
  let scheme = call_606880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606880.url(scheme.get, call_606880.host, call_606880.base,
                         call_606880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606880, url, valid)

proc call*(call_606881: Call_PostSendMessageBatch_606865; AccountNumber: int;
          QueueName: string; Entries: JsonNode; Action: string = "SendMessageBatch";
          Version: string = "2012-11-05"): Recallable =
  ## postSendMessageBatch
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606882 = newJObject()
  var query_606883 = newJObject()
  var formData_606884 = newJObject()
  add(path_606882, "AccountNumber", newJInt(AccountNumber))
  add(path_606882, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_606884.add "Entries", Entries
  add(query_606883, "Action", newJString(Action))
  add(query_606883, "Version", newJString(Version))
  result = call_606881.call(path_606882, query_606883, nil, formData_606884, nil)

var postSendMessageBatch* = Call_PostSendMessageBatch_606865(
    name: "postSendMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_PostSendMessageBatch_606866, base: "/",
    url: url_PostSendMessageBatch_606867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessageBatch_606846 = ref object of OpenApiRestCall_605573
proc url_GetSendMessageBatch_606848(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessageBatch_606847(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606849 = path.getOrDefault("AccountNumber")
  valid_606849 = validateParameter(valid_606849, JInt, required = true, default = nil)
  if valid_606849 != nil:
    section.add "AccountNumber", valid_606849
  var valid_606850 = path.getOrDefault("QueueName")
  valid_606850 = validateParameter(valid_606850, JString, required = true,
                                 default = nil)
  if valid_606850 != nil:
    section.add "QueueName", valid_606850
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_606851 = query.getOrDefault("Entries")
  valid_606851 = validateParameter(valid_606851, JArray, required = true, default = nil)
  if valid_606851 != nil:
    section.add "Entries", valid_606851
  var valid_606852 = query.getOrDefault("Action")
  valid_606852 = validateParameter(valid_606852, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_606852 != nil:
    section.add "Action", valid_606852
  var valid_606853 = query.getOrDefault("Version")
  valid_606853 = validateParameter(valid_606853, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606853 != nil:
    section.add "Version", valid_606853
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
  var valid_606854 = header.getOrDefault("X-Amz-Signature")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Signature", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Content-Sha256", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Date")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Date", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Credential")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Credential", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Security-Token")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Security-Token", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Algorithm")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Algorithm", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-SignedHeaders", valid_606860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606861: Call_GetSendMessageBatch_606846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_606861.validator(path, query, header, formData, body)
  let scheme = call_606861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606861.url(scheme.get, call_606861.host, call_606861.base,
                         call_606861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606861, url, valid)

proc call*(call_606862: Call_GetSendMessageBatch_606846; Entries: JsonNode;
          AccountNumber: int; QueueName: string;
          Action: string = "SendMessageBatch"; Version: string = "2012-11-05"): Recallable =
  ## getSendMessageBatch
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_606863 = newJObject()
  var query_606864 = newJObject()
  if Entries != nil:
    query_606864.add "Entries", Entries
  add(path_606863, "AccountNumber", newJInt(AccountNumber))
  add(path_606863, "QueueName", newJString(QueueName))
  add(query_606864, "Action", newJString(Action))
  add(query_606864, "Version", newJString(Version))
  result = call_606862.call(path_606863, query_606864, nil, nil, nil)

var getSendMessageBatch* = Call_GetSendMessageBatch_606846(
    name: "getSendMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_GetSendMessageBatch_606847, base: "/",
    url: url_GetSendMessageBatch_606848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetQueueAttributes_606909 = ref object of OpenApiRestCall_605573
proc url_PostSetQueueAttributes_606911(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetQueueAttributes_606910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606912 = path.getOrDefault("AccountNumber")
  valid_606912 = validateParameter(valid_606912, JInt, required = true, default = nil)
  if valid_606912 != nil:
    section.add "AccountNumber", valid_606912
  var valid_606913 = path.getOrDefault("QueueName")
  valid_606913 = validateParameter(valid_606913, JString, required = true,
                                 default = nil)
  if valid_606913 != nil:
    section.add "QueueName", valid_606913
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606914 = query.getOrDefault("Action")
  valid_606914 = validateParameter(valid_606914, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_606914 != nil:
    section.add "Action", valid_606914
  var valid_606915 = query.getOrDefault("Version")
  valid_606915 = validateParameter(valid_606915, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606915 != nil:
    section.add "Version", valid_606915
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
  var valid_606916 = header.getOrDefault("X-Amz-Signature")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Signature", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Content-Sha256", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Date")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Date", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Credential")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Credential", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Security-Token")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Security-Token", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Algorithm")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Algorithm", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-SignedHeaders", valid_606922
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.key: JString
  ##   Attribute.1.value: JString
  ##   Attribute.0.key: JString
  section = newJObject()
  var valid_606923 = formData.getOrDefault("Attribute.2.value")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "Attribute.2.value", valid_606923
  var valid_606924 = formData.getOrDefault("Attribute.2.key")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "Attribute.2.key", valid_606924
  var valid_606925 = formData.getOrDefault("Attribute.0.value")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "Attribute.0.value", valid_606925
  var valid_606926 = formData.getOrDefault("Attribute.1.key")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "Attribute.1.key", valid_606926
  var valid_606927 = formData.getOrDefault("Attribute.1.value")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "Attribute.1.value", valid_606927
  var valid_606928 = formData.getOrDefault("Attribute.0.key")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "Attribute.0.key", valid_606928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606929: Call_PostSetQueueAttributes_606909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_606929.validator(path, query, header, formData, body)
  let scheme = call_606929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606929.url(scheme.get, call_606929.host, call_606929.base,
                         call_606929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606929, url, valid)

proc call*(call_606930: Call_PostSetQueueAttributes_606909; AccountNumber: int;
          QueueName: string; Attribute2Value: string = ""; Attribute2Key: string = "";
          Attribute0Value: string = ""; Attribute1Key: string = "";
          Attribute1Value: string = ""; Action: string = "SetQueueAttributes";
          Version: string = "2012-11-05"; Attribute0Key: string = ""): Recallable =
  ## postSetQueueAttributes
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   Attribute2Value: string
  ##   Attribute2Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Attribute0Value: string
  ##   Attribute1Key: string
  ##   Attribute1Value: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attribute0Key: string
  var path_606931 = newJObject()
  var query_606932 = newJObject()
  var formData_606933 = newJObject()
  add(formData_606933, "Attribute.2.value", newJString(Attribute2Value))
  add(formData_606933, "Attribute.2.key", newJString(Attribute2Key))
  add(path_606931, "AccountNumber", newJInt(AccountNumber))
  add(path_606931, "QueueName", newJString(QueueName))
  add(formData_606933, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_606933, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_606933, "Attribute.1.value", newJString(Attribute1Value))
  add(query_606932, "Action", newJString(Action))
  add(query_606932, "Version", newJString(Version))
  add(formData_606933, "Attribute.0.key", newJString(Attribute0Key))
  result = call_606930.call(path_606931, query_606932, nil, formData_606933, nil)

var postSetQueueAttributes* = Call_PostSetQueueAttributes_606909(
    name: "postSetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_PostSetQueueAttributes_606910, base: "/",
    url: url_PostSetQueueAttributes_606911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetQueueAttributes_606885 = ref object of OpenApiRestCall_605573
proc url_GetSetQueueAttributes_606887(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetQueueAttributes_606886(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606888 = path.getOrDefault("AccountNumber")
  valid_606888 = validateParameter(valid_606888, JInt, required = true, default = nil)
  if valid_606888 != nil:
    section.add "AccountNumber", valid_606888
  var valid_606889 = path.getOrDefault("QueueName")
  valid_606889 = validateParameter(valid_606889, JString, required = true,
                                 default = nil)
  if valid_606889 != nil:
    section.add "QueueName", valid_606889
  result.add "path", section
  ## parameters in `query` object:
  ##   Attribute.2.key: JString
  ##   Attribute.1.key: JString
  ##   Attribute.2.value: JString
  ##   Attribute.1.value: JString
  ##   Action: JString (required)
  ##   Attribute.0.key: JString
  ##   Version: JString (required)
  ##   Attribute.0.value: JString
  section = newJObject()
  var valid_606890 = query.getOrDefault("Attribute.2.key")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "Attribute.2.key", valid_606890
  var valid_606891 = query.getOrDefault("Attribute.1.key")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "Attribute.1.key", valid_606891
  var valid_606892 = query.getOrDefault("Attribute.2.value")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "Attribute.2.value", valid_606892
  var valid_606893 = query.getOrDefault("Attribute.1.value")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "Attribute.1.value", valid_606893
  var valid_606894 = query.getOrDefault("Action")
  valid_606894 = validateParameter(valid_606894, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_606894 != nil:
    section.add "Action", valid_606894
  var valid_606895 = query.getOrDefault("Attribute.0.key")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "Attribute.0.key", valid_606895
  var valid_606896 = query.getOrDefault("Version")
  valid_606896 = validateParameter(valid_606896, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606896 != nil:
    section.add "Version", valid_606896
  var valid_606897 = query.getOrDefault("Attribute.0.value")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "Attribute.0.value", valid_606897
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
  var valid_606898 = header.getOrDefault("X-Amz-Signature")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Signature", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Content-Sha256", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Date")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Date", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Credential")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Credential", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Security-Token")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Security-Token", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Algorithm")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Algorithm", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-SignedHeaders", valid_606904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606905: Call_GetSetQueueAttributes_606885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_606905.validator(path, query, header, formData, body)
  let scheme = call_606905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606905.url(scheme.get, call_606905.host, call_606905.base,
                         call_606905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606905, url, valid)

proc call*(call_606906: Call_GetSetQueueAttributes_606885; AccountNumber: int;
          QueueName: string; Attribute2Key: string = ""; Attribute1Key: string = "";
          Attribute2Value: string = ""; Attribute1Value: string = "";
          Action: string = "SetQueueAttributes"; Attribute0Key: string = "";
          Version: string = "2012-11-05"; Attribute0Value: string = ""): Recallable =
  ## getSetQueueAttributes
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ##   Attribute2Key: string
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Attribute1Key: string
  ##   Attribute2Value: string
  ##   Attribute1Value: string
  ##   Action: string (required)
  ##   Attribute0Key: string
  ##   Version: string (required)
  ##   Attribute0Value: string
  var path_606907 = newJObject()
  var query_606908 = newJObject()
  add(query_606908, "Attribute.2.key", newJString(Attribute2Key))
  add(path_606907, "AccountNumber", newJInt(AccountNumber))
  add(path_606907, "QueueName", newJString(QueueName))
  add(query_606908, "Attribute.1.key", newJString(Attribute1Key))
  add(query_606908, "Attribute.2.value", newJString(Attribute2Value))
  add(query_606908, "Attribute.1.value", newJString(Attribute1Value))
  add(query_606908, "Action", newJString(Action))
  add(query_606908, "Attribute.0.key", newJString(Attribute0Key))
  add(query_606908, "Version", newJString(Version))
  add(query_606908, "Attribute.0.value", newJString(Attribute0Value))
  result = call_606906.call(path_606907, query_606908, nil, nil, nil)

var getSetQueueAttributes* = Call_GetSetQueueAttributes_606885(
    name: "getSetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_GetSetQueueAttributes_606886, base: "/",
    url: url_GetSetQueueAttributes_606887, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagQueue_606958 = ref object of OpenApiRestCall_605573
proc url_PostTagQueue_606960(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagQueue_606959(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606961 = path.getOrDefault("AccountNumber")
  valid_606961 = validateParameter(valid_606961, JInt, required = true, default = nil)
  if valid_606961 != nil:
    section.add "AccountNumber", valid_606961
  var valid_606962 = path.getOrDefault("QueueName")
  valid_606962 = validateParameter(valid_606962, JString, required = true,
                                 default = nil)
  if valid_606962 != nil:
    section.add "QueueName", valid_606962
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606963 = query.getOrDefault("Action")
  valid_606963 = validateParameter(valid_606963, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_606963 != nil:
    section.add "Action", valid_606963
  var valid_606964 = query.getOrDefault("Version")
  valid_606964 = validateParameter(valid_606964, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606964 != nil:
    section.add "Version", valid_606964
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
  var valid_606965 = header.getOrDefault("X-Amz-Signature")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Signature", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Content-Sha256", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-Date")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-Date", valid_606967
  var valid_606968 = header.getOrDefault("X-Amz-Credential")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Credential", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-Security-Token")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Security-Token", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Algorithm")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Algorithm", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-SignedHeaders", valid_606971
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags.0.value: JString
  ##   Tags.2.key: JString
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.1.value: JString
  ##   Tags.2.value: JString
  section = newJObject()
  var valid_606972 = formData.getOrDefault("Tags.0.value")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "Tags.0.value", valid_606972
  var valid_606973 = formData.getOrDefault("Tags.2.key")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "Tags.2.key", valid_606973
  var valid_606974 = formData.getOrDefault("Tags.0.key")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "Tags.0.key", valid_606974
  var valid_606975 = formData.getOrDefault("Tags.1.key")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "Tags.1.key", valid_606975
  var valid_606976 = formData.getOrDefault("Tags.1.value")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "Tags.1.value", valid_606976
  var valid_606977 = formData.getOrDefault("Tags.2.value")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "Tags.2.value", valid_606977
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606978: Call_PostTagQueue_606958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606978.validator(path, query, header, formData, body)
  let scheme = call_606978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606978.url(scheme.get, call_606978.host, call_606978.base,
                         call_606978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606978, url, valid)

proc call*(call_606979: Call_PostTagQueue_606958; AccountNumber: int;
          QueueName: string; Tags0Value: string = ""; Tags2Key: string = "";
          Tags0Key: string = ""; Action: string = "TagQueue"; Tags1Key: string = "";
          Version: string = "2012-11-05"; Tags1Value: string = "";
          Tags2Value: string = ""): Recallable =
  ## postTagQueue
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Tags0Value: string
  ##   Tags2Key: string
  ##   Tags0Key: string
  ##   Action: string (required)
  ##   Tags1Key: string
  ##   Version: string (required)
  ##   Tags1Value: string
  ##   Tags2Value: string
  var path_606980 = newJObject()
  var query_606981 = newJObject()
  var formData_606982 = newJObject()
  add(path_606980, "AccountNumber", newJInt(AccountNumber))
  add(path_606980, "QueueName", newJString(QueueName))
  add(formData_606982, "Tags.0.value", newJString(Tags0Value))
  add(formData_606982, "Tags.2.key", newJString(Tags2Key))
  add(formData_606982, "Tags.0.key", newJString(Tags0Key))
  add(query_606981, "Action", newJString(Action))
  add(formData_606982, "Tags.1.key", newJString(Tags1Key))
  add(query_606981, "Version", newJString(Version))
  add(formData_606982, "Tags.1.value", newJString(Tags1Value))
  add(formData_606982, "Tags.2.value", newJString(Tags2Value))
  result = call_606979.call(path_606980, query_606981, nil, formData_606982, nil)

var postTagQueue* = Call_PostTagQueue_606958(name: "postTagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
    validator: validate_PostTagQueue_606959, base: "/", url: url_PostTagQueue_606960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagQueue_606934 = ref object of OpenApiRestCall_605573
proc url_GetTagQueue_606936(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagQueue_606935(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606937 = path.getOrDefault("AccountNumber")
  valid_606937 = validateParameter(valid_606937, JInt, required = true, default = nil)
  if valid_606937 != nil:
    section.add "AccountNumber", valid_606937
  var valid_606938 = path.getOrDefault("QueueName")
  valid_606938 = validateParameter(valid_606938, JString, required = true,
                                 default = nil)
  if valid_606938 != nil:
    section.add "QueueName", valid_606938
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags.0.value: JString
  ##   Tags.2.value: JString
  ##   Tags.2.key: JString
  ##   Tags.1.key: JString
  ##   Action: JString (required)
  ##   Tags.0.key: JString
  ##   Tags.1.value: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_606939 = query.getOrDefault("Tags.0.value")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "Tags.0.value", valid_606939
  var valid_606940 = query.getOrDefault("Tags.2.value")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "Tags.2.value", valid_606940
  var valid_606941 = query.getOrDefault("Tags.2.key")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "Tags.2.key", valid_606941
  var valid_606942 = query.getOrDefault("Tags.1.key")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "Tags.1.key", valid_606942
  var valid_606943 = query.getOrDefault("Action")
  valid_606943 = validateParameter(valid_606943, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_606943 != nil:
    section.add "Action", valid_606943
  var valid_606944 = query.getOrDefault("Tags.0.key")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "Tags.0.key", valid_606944
  var valid_606945 = query.getOrDefault("Tags.1.value")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "Tags.1.value", valid_606945
  var valid_606946 = query.getOrDefault("Version")
  valid_606946 = validateParameter(valid_606946, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606946 != nil:
    section.add "Version", valid_606946
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
  var valid_606947 = header.getOrDefault("X-Amz-Signature")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Signature", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Content-Sha256", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Date")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Date", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Credential")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Credential", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Security-Token")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Security-Token", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Algorithm")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Algorithm", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-SignedHeaders", valid_606953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606954: Call_GetTagQueue_606934; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606954.validator(path, query, header, formData, body)
  let scheme = call_606954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606954.url(scheme.get, call_606954.host, call_606954.base,
                         call_606954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606954, url, valid)

proc call*(call_606955: Call_GetTagQueue_606934; AccountNumber: int;
          QueueName: string; Tags0Value: string = ""; Tags2Value: string = "";
          Tags2Key: string = ""; Tags1Key: string = ""; Action: string = "TagQueue";
          Tags0Key: string = ""; Tags1Value: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getTagQueue
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   Tags0Value: string
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Tags2Value: string
  ##   Tags2Key: string
  ##   Tags1Key: string
  ##   Action: string (required)
  ##   Tags0Key: string
  ##   Tags1Value: string
  ##   Version: string (required)
  var path_606956 = newJObject()
  var query_606957 = newJObject()
  add(path_606956, "AccountNumber", newJInt(AccountNumber))
  add(query_606957, "Tags.0.value", newJString(Tags0Value))
  add(path_606956, "QueueName", newJString(QueueName))
  add(query_606957, "Tags.2.value", newJString(Tags2Value))
  add(query_606957, "Tags.2.key", newJString(Tags2Key))
  add(query_606957, "Tags.1.key", newJString(Tags1Key))
  add(query_606957, "Action", newJString(Action))
  add(query_606957, "Tags.0.key", newJString(Tags0Key))
  add(query_606957, "Tags.1.value", newJString(Tags1Value))
  add(query_606957, "Version", newJString(Version))
  result = call_606955.call(path_606956, query_606957, nil, nil, nil)

var getTagQueue* = Call_GetTagQueue_606934(name: "getTagQueue",
                                        meth: HttpMethod.HttpGet,
                                        host: "sqs.amazonaws.com", route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
                                        validator: validate_GetTagQueue_606935,
                                        base: "/", url: url_GetTagQueue_606936,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagQueue_607002 = ref object of OpenApiRestCall_605573
proc url_PostUntagQueue_607004(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagQueue_607003(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_607005 = path.getOrDefault("AccountNumber")
  valid_607005 = validateParameter(valid_607005, JInt, required = true, default = nil)
  if valid_607005 != nil:
    section.add "AccountNumber", valid_607005
  var valid_607006 = path.getOrDefault("QueueName")
  valid_607006 = validateParameter(valid_607006, JString, required = true,
                                 default = nil)
  if valid_607006 != nil:
    section.add "QueueName", valid_607006
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607007 = query.getOrDefault("Action")
  valid_607007 = validateParameter(valid_607007, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_607007 != nil:
    section.add "Action", valid_607007
  var valid_607008 = query.getOrDefault("Version")
  valid_607008 = validateParameter(valid_607008, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_607008 != nil:
    section.add "Version", valid_607008
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
  var valid_607009 = header.getOrDefault("X-Amz-Signature")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Signature", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Content-Sha256", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Date")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Date", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Credential")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Credential", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-Security-Token")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-Security-Token", valid_607013
  var valid_607014 = header.getOrDefault("X-Amz-Algorithm")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Algorithm", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-SignedHeaders", valid_607015
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607016 = formData.getOrDefault("TagKeys")
  valid_607016 = validateParameter(valid_607016, JArray, required = true, default = nil)
  if valid_607016 != nil:
    section.add "TagKeys", valid_607016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607017: Call_PostUntagQueue_607002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_607017.validator(path, query, header, formData, body)
  let scheme = call_607017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607017.url(scheme.get, call_607017.host, call_607017.base,
                         call_607017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607017, url, valid)

proc call*(call_607018: Call_PostUntagQueue_607002; TagKeys: JsonNode;
          AccountNumber: int; QueueName: string; Action: string = "UntagQueue";
          Version: string = "2012-11-05"): Recallable =
  ## postUntagQueue
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   Action: string (required)
  ##   Version: string (required)
  var path_607019 = newJObject()
  var query_607020 = newJObject()
  var formData_607021 = newJObject()
  if TagKeys != nil:
    formData_607021.add "TagKeys", TagKeys
  add(path_607019, "AccountNumber", newJInt(AccountNumber))
  add(path_607019, "QueueName", newJString(QueueName))
  add(query_607020, "Action", newJString(Action))
  add(query_607020, "Version", newJString(Version))
  result = call_607018.call(path_607019, query_607020, nil, formData_607021, nil)

var postUntagQueue* = Call_PostUntagQueue_607002(name: "postUntagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_PostUntagQueue_607003, base: "/", url: url_PostUntagQueue_607004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagQueue_606983 = ref object of OpenApiRestCall_605573
proc url_GetUntagQueue_606985(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagQueue_606984(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AccountNumber: JInt (required)
  ##                : The AWS account number
  ##   QueueName: JString (required)
  ##            : The name of the queue
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AccountNumber` field"
  var valid_606986 = path.getOrDefault("AccountNumber")
  valid_606986 = validateParameter(valid_606986, JInt, required = true, default = nil)
  if valid_606986 != nil:
    section.add "AccountNumber", valid_606986
  var valid_606987 = path.getOrDefault("QueueName")
  valid_606987 = validateParameter(valid_606987, JString, required = true,
                                 default = nil)
  if valid_606987 != nil:
    section.add "QueueName", valid_606987
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_606988 = query.getOrDefault("TagKeys")
  valid_606988 = validateParameter(valid_606988, JArray, required = true, default = nil)
  if valid_606988 != nil:
    section.add "TagKeys", valid_606988
  var valid_606989 = query.getOrDefault("Action")
  valid_606989 = validateParameter(valid_606989, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_606989 != nil:
    section.add "Action", valid_606989
  var valid_606990 = query.getOrDefault("Version")
  valid_606990 = validateParameter(valid_606990, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_606990 != nil:
    section.add "Version", valid_606990
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
  var valid_606991 = header.getOrDefault("X-Amz-Signature")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Signature", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Content-Sha256", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Date")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Date", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Credential")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Credential", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Security-Token")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Security-Token", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Algorithm")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Algorithm", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-SignedHeaders", valid_606997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606998: Call_GetUntagQueue_606983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606998.validator(path, query, header, formData, body)
  let scheme = call_606998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606998.url(scheme.get, call_606998.host, call_606998.base,
                         call_606998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606998, url, valid)

proc call*(call_606999: Call_GetUntagQueue_606983; AccountNumber: int;
          QueueName: string; TagKeys: JsonNode; Action: string = "UntagQueue";
          Version: string = "2012-11-05"): Recallable =
  ## getUntagQueue
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   AccountNumber: int (required)
  ##                : The AWS account number
  ##   QueueName: string (required)
  ##            : The name of the queue
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Action: string (required)
  ##   Version: string (required)
  var path_607000 = newJObject()
  var query_607001 = newJObject()
  add(path_607000, "AccountNumber", newJInt(AccountNumber))
  add(path_607000, "QueueName", newJString(QueueName))
  if TagKeys != nil:
    query_607001.add "TagKeys", TagKeys
  add(query_607001, "Action", newJString(Action))
  add(query_607001, "Version", newJString(Version))
  result = call_606999.call(path_607000, query_607001, nil, nil, nil)

var getUntagQueue* = Call_GetUntagQueue_606983(name: "getUntagQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_GetUntagQueue_606984, base: "/", url: url_GetUntagQueue_606985,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
