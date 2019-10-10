
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_603077 = ref object of OpenApiRestCall_602450
proc url_PostAddPermission_603079(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostAddPermission_603078(path: JsonNode; query: JsonNode;
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
  var valid_603080 = path.getOrDefault("QueueName")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = nil)
  if valid_603080 != nil:
    section.add "QueueName", valid_603080
  var valid_603081 = path.getOrDefault("AccountNumber")
  valid_603081 = validateParameter(valid_603081, JInt, required = true, default = nil)
  if valid_603081 != nil:
    section.add "AccountNumber", valid_603081
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603082 = query.getOrDefault("Action")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_603082 != nil:
    section.add "Action", valid_603082
  var valid_603083 = query.getOrDefault("Version")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603083 != nil:
    section.add "Version", valid_603083
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
  var valid_603084 = header.getOrDefault("X-Amz-Date")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Date", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Security-Token")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Security-Token", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Content-Sha256", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Algorithm")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Algorithm", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Signature")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Signature", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-SignedHeaders", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Credential")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Credential", valid_603090
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
  var valid_603091 = formData.getOrDefault("Actions")
  valid_603091 = validateParameter(valid_603091, JArray, required = true, default = nil)
  if valid_603091 != nil:
    section.add "Actions", valid_603091
  var valid_603092 = formData.getOrDefault("Label")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Label", valid_603092
  var valid_603093 = formData.getOrDefault("AWSAccountIds")
  valid_603093 = validateParameter(valid_603093, JArray, required = true, default = nil)
  if valid_603093 != nil:
    section.add "AWSAccountIds", valid_603093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_PostAddPermission_603077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_PostAddPermission_603077; Actions: JsonNode;
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
  var path_603096 = newJObject()
  var query_603097 = newJObject()
  var formData_603098 = newJObject()
  if Actions != nil:
    formData_603098.add "Actions", Actions
  add(formData_603098, "Label", newJString(Label))
  if AWSAccountIds != nil:
    formData_603098.add "AWSAccountIds", AWSAccountIds
  add(path_603096, "QueueName", newJString(QueueName))
  add(query_603097, "Action", newJString(Action))
  add(path_603096, "AccountNumber", newJInt(AccountNumber))
  add(query_603097, "Version", newJString(Version))
  result = call_603095.call(path_603096, query_603097, nil, formData_603098, nil)

var postAddPermission* = Call_PostAddPermission_603077(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_PostAddPermission_603078, base: "/",
    url: url_PostAddPermission_603079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_602787 = ref object of OpenApiRestCall_602450
proc url_GetAddPermission_602789(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetAddPermission_602788(path: JsonNode; query: JsonNode;
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
  var valid_602915 = path.getOrDefault("QueueName")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "QueueName", valid_602915
  var valid_602916 = path.getOrDefault("AccountNumber")
  valid_602916 = validateParameter(valid_602916, JInt, required = true, default = nil)
  if valid_602916 != nil:
    section.add "AccountNumber", valid_602916
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
  var valid_602917 = query.getOrDefault("AWSAccountIds")
  valid_602917 = validateParameter(valid_602917, JArray, required = true, default = nil)
  if valid_602917 != nil:
    section.add "AWSAccountIds", valid_602917
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("Actions")
  valid_602932 = validateParameter(valid_602932, JArray, required = true, default = nil)
  if valid_602932 != nil:
    section.add "Actions", valid_602932
  var valid_602933 = query.getOrDefault("Version")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_602933 != nil:
    section.add "Version", valid_602933
  var valid_602934 = query.getOrDefault("Label")
  valid_602934 = validateParameter(valid_602934, JString, required = true,
                                 default = nil)
  if valid_602934 != nil:
    section.add "Label", valid_602934
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
  var valid_602935 = header.getOrDefault("X-Amz-Date")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Date", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Security-Token")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Security-Token", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Content-Sha256", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Algorithm")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Algorithm", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Signature")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Signature", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-SignedHeaders", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Credential")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Credential", valid_602941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602964: Call_GetAddPermission_602787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_602964.validator(path, query, header, formData, body)
  let scheme = call_602964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602964.url(scheme.get, call_602964.host, call_602964.base,
                         call_602964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602964, url, valid)

proc call*(call_603035: Call_GetAddPermission_602787; AWSAccountIds: JsonNode;
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
  var path_603036 = newJObject()
  var query_603038 = newJObject()
  if AWSAccountIds != nil:
    query_603038.add "AWSAccountIds", AWSAccountIds
  add(path_603036, "QueueName", newJString(QueueName))
  add(query_603038, "Action", newJString(Action))
  if Actions != nil:
    query_603038.add "Actions", Actions
  add(path_603036, "AccountNumber", newJInt(AccountNumber))
  add(query_603038, "Version", newJString(Version))
  add(query_603038, "Label", newJString(Label))
  result = call_603035.call(path_603036, query_603038, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_602787(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_GetAddPermission_602788, base: "/",
    url: url_GetAddPermission_602789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibility_603119 = ref object of OpenApiRestCall_602450
proc url_PostChangeMessageVisibility_603121(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PostChangeMessageVisibility_603120(path: JsonNode; query: JsonNode;
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
  var valid_603122 = path.getOrDefault("QueueName")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = nil)
  if valid_603122 != nil:
    section.add "QueueName", valid_603122
  var valid_603123 = path.getOrDefault("AccountNumber")
  valid_603123 = validateParameter(valid_603123, JInt, required = true, default = nil)
  if valid_603123 != nil:
    section.add "AccountNumber", valid_603123
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603124 = query.getOrDefault("Action")
  valid_603124 = validateParameter(valid_603124, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_603124 != nil:
    section.add "Action", valid_603124
  var valid_603125 = query.getOrDefault("Version")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603125 != nil:
    section.add "Version", valid_603125
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
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Security-Token")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Security-Token", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Content-Sha256", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Credential")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Credential", valid_603132
  result.add "header", section
  ## parameters in `formData` object:
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `VisibilityTimeout` field"
  var valid_603133 = formData.getOrDefault("VisibilityTimeout")
  valid_603133 = validateParameter(valid_603133, JInt, required = true, default = nil)
  if valid_603133 != nil:
    section.add "VisibilityTimeout", valid_603133
  var valid_603134 = formData.getOrDefault("ReceiptHandle")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = nil)
  if valid_603134 != nil:
    section.add "ReceiptHandle", valid_603134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603135: Call_PostChangeMessageVisibility_603119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_603135.validator(path, query, header, formData, body)
  let scheme = call_603135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603135.url(scheme.get, call_603135.host, call_603135.base,
                         call_603135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603135, url, valid)

proc call*(call_603136: Call_PostChangeMessageVisibility_603119;
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
  var path_603137 = newJObject()
  var query_603138 = newJObject()
  var formData_603139 = newJObject()
  add(formData_603139, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(path_603137, "QueueName", newJString(QueueName))
  add(query_603138, "Action", newJString(Action))
  add(path_603137, "AccountNumber", newJInt(AccountNumber))
  add(formData_603139, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_603138, "Version", newJString(Version))
  result = call_603136.call(path_603137, query_603138, nil, formData_603139, nil)

var postChangeMessageVisibility* = Call_PostChangeMessageVisibility_603119(
    name: "postChangeMessageVisibility", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_PostChangeMessageVisibility_603120, base: "/",
    url: url_PostChangeMessageVisibility_603121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibility_603099 = ref object of OpenApiRestCall_602450
proc url_GetChangeMessageVisibility_603101(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetChangeMessageVisibility_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = path.getOrDefault("QueueName")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = nil)
  if valid_603102 != nil:
    section.add "QueueName", valid_603102
  var valid_603103 = path.getOrDefault("AccountNumber")
  valid_603103 = validateParameter(valid_603103, JInt, required = true, default = nil)
  if valid_603103 != nil:
    section.add "AccountNumber", valid_603103
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
  var valid_603104 = query.getOrDefault("ReceiptHandle")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = nil)
  if valid_603104 != nil:
    section.add "ReceiptHandle", valid_603104
  var valid_603105 = query.getOrDefault("Action")
  valid_603105 = validateParameter(valid_603105, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_603105 != nil:
    section.add "Action", valid_603105
  var valid_603106 = query.getOrDefault("Version")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603106 != nil:
    section.add "Version", valid_603106
  var valid_603107 = query.getOrDefault("VisibilityTimeout")
  valid_603107 = validateParameter(valid_603107, JInt, required = true, default = nil)
  if valid_603107 != nil:
    section.add "VisibilityTimeout", valid_603107
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
  var valid_603108 = header.getOrDefault("X-Amz-Date")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Date", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Security-Token")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Security-Token", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Content-Sha256", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Algorithm")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Algorithm", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Signature")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Signature", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-SignedHeaders", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Credential")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Credential", valid_603114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_GetChangeMessageVisibility_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_GetChangeMessageVisibility_603099;
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
  var path_603117 = newJObject()
  var query_603118 = newJObject()
  add(query_603118, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_603117, "QueueName", newJString(QueueName))
  add(query_603118, "Action", newJString(Action))
  add(path_603117, "AccountNumber", newJInt(AccountNumber))
  add(query_603118, "Version", newJString(Version))
  add(query_603118, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_603116.call(path_603117, query_603118, nil, nil, nil)

var getChangeMessageVisibility* = Call_GetChangeMessageVisibility_603099(
    name: "getChangeMessageVisibility", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_GetChangeMessageVisibility_603100, base: "/",
    url: url_GetChangeMessageVisibility_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibilityBatch_603159 = ref object of OpenApiRestCall_602450
proc url_PostChangeMessageVisibilityBatch_603161(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PostChangeMessageVisibilityBatch_603160(path: JsonNode;
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
  var valid_603162 = path.getOrDefault("QueueName")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "QueueName", valid_603162
  var valid_603163 = path.getOrDefault("AccountNumber")
  valid_603163 = validateParameter(valid_603163, JInt, required = true, default = nil)
  if valid_603163 != nil:
    section.add "AccountNumber", valid_603163
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603164 = query.getOrDefault("Action")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_603164 != nil:
    section.add "Action", valid_603164
  var valid_603165 = query.getOrDefault("Version")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603165 != nil:
    section.add "Version", valid_603165
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
  var valid_603166 = header.getOrDefault("X-Amz-Date")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Date", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
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
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_603173 = formData.getOrDefault("Entries")
  valid_603173 = validateParameter(valid_603173, JArray, required = true, default = nil)
  if valid_603173 != nil:
    section.add "Entries", valid_603173
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_PostChangeMessageVisibilityBatch_603159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_PostChangeMessageVisibilityBatch_603159;
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
  var path_603176 = newJObject()
  var query_603177 = newJObject()
  var formData_603178 = newJObject()
  if Entries != nil:
    formData_603178.add "Entries", Entries
  add(path_603176, "QueueName", newJString(QueueName))
  add(query_603177, "Action", newJString(Action))
  add(path_603176, "AccountNumber", newJInt(AccountNumber))
  add(query_603177, "Version", newJString(Version))
  result = call_603175.call(path_603176, query_603177, nil, formData_603178, nil)

var postChangeMessageVisibilityBatch* = Call_PostChangeMessageVisibilityBatch_603159(
    name: "postChangeMessageVisibilityBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_PostChangeMessageVisibilityBatch_603160, base: "/",
    url: url_PostChangeMessageVisibilityBatch_603161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibilityBatch_603140 = ref object of OpenApiRestCall_602450
proc url_GetChangeMessageVisibilityBatch_603142(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetChangeMessageVisibilityBatch_603141(path: JsonNode;
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
  var valid_603143 = path.getOrDefault("QueueName")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "QueueName", valid_603143
  var valid_603144 = path.getOrDefault("AccountNumber")
  valid_603144 = validateParameter(valid_603144, JInt, required = true, default = nil)
  if valid_603144 != nil:
    section.add "AccountNumber", valid_603144
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_603145 = query.getOrDefault("Entries")
  valid_603145 = validateParameter(valid_603145, JArray, required = true, default = nil)
  if valid_603145 != nil:
    section.add "Entries", valid_603145
  var valid_603146 = query.getOrDefault("Action")
  valid_603146 = validateParameter(valid_603146, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_603146 != nil:
    section.add "Action", valid_603146
  var valid_603147 = query.getOrDefault("Version")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603147 != nil:
    section.add "Version", valid_603147
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
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
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
  if body != nil:
    result.add "body", body

proc call*(call_603155: Call_GetChangeMessageVisibilityBatch_603140;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603155.validator(path, query, header, formData, body)
  let scheme = call_603155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603155.url(scheme.get, call_603155.host, call_603155.base,
                         call_603155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603155, url, valid)

proc call*(call_603156: Call_GetChangeMessageVisibilityBatch_603140;
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
  var path_603157 = newJObject()
  var query_603158 = newJObject()
  add(path_603157, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_603158.add "Entries", Entries
  add(query_603158, "Action", newJString(Action))
  add(path_603157, "AccountNumber", newJInt(AccountNumber))
  add(query_603158, "Version", newJString(Version))
  result = call_603156.call(path_603157, query_603158, nil, nil, nil)

var getChangeMessageVisibilityBatch* = Call_GetChangeMessageVisibilityBatch_603140(
    name: "getChangeMessageVisibilityBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_GetChangeMessageVisibilityBatch_603141, base: "/",
    url: url_GetChangeMessageVisibilityBatch_603142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateQueue_603207 = ref object of OpenApiRestCall_602450
proc url_PostCreateQueue_603209(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateQueue_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = query.getOrDefault("Action")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_603210 != nil:
    section.add "Action", valid_603210
  var valid_603211 = query.getOrDefault("Version")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603211 != nil:
    section.add "Version", valid_603211
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
  var valid_603212 = header.getOrDefault("X-Amz-Date")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Date", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Security-Token")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Security-Token", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Content-Sha256", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Algorithm")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Algorithm", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Signature")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Signature", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-SignedHeaders", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Credential")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Credential", valid_603218
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
  var valid_603219 = formData.getOrDefault("Tag.1.value")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Tag.1.value", valid_603219
  var valid_603220 = formData.getOrDefault("Attribute.0.key")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "Attribute.0.key", valid_603220
  var valid_603221 = formData.getOrDefault("Attribute.0.value")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "Attribute.0.value", valid_603221
  var valid_603222 = formData.getOrDefault("Attribute.1.value")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Attribute.1.value", valid_603222
  var valid_603223 = formData.getOrDefault("Tag.0.key")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Tag.0.key", valid_603223
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_603224 = formData.getOrDefault("QueueName")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = nil)
  if valid_603224 != nil:
    section.add "QueueName", valid_603224
  var valid_603225 = formData.getOrDefault("Attribute.1.key")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "Attribute.1.key", valid_603225
  var valid_603226 = formData.getOrDefault("Tag.1.key")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "Tag.1.key", valid_603226
  var valid_603227 = formData.getOrDefault("Tag.0.value")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "Tag.0.value", valid_603227
  var valid_603228 = formData.getOrDefault("Tag.2.key")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "Tag.2.key", valid_603228
  var valid_603229 = formData.getOrDefault("Tag.2.value")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "Tag.2.value", valid_603229
  var valid_603230 = formData.getOrDefault("Attribute.2.value")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "Attribute.2.value", valid_603230
  var valid_603231 = formData.getOrDefault("Attribute.2.key")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "Attribute.2.key", valid_603231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603232: Call_PostCreateQueue_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603232.validator(path, query, header, formData, body)
  let scheme = call_603232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603232.url(scheme.get, call_603232.host, call_603232.base,
                         call_603232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603232, url, valid)

proc call*(call_603233: Call_PostCreateQueue_603207; QueueName: string;
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
  var query_603234 = newJObject()
  var formData_603235 = newJObject()
  add(formData_603235, "Tag.1.value", newJString(Tag1Value))
  add(formData_603235, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_603235, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_603235, "Attribute.1.value", newJString(Attribute1Value))
  add(formData_603235, "Tag.0.key", newJString(Tag0Key))
  add(query_603234, "Action", newJString(Action))
  add(formData_603235, "QueueName", newJString(QueueName))
  add(formData_603235, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_603235, "Tag.1.key", newJString(Tag1Key))
  add(formData_603235, "Tag.0.value", newJString(Tag0Value))
  add(formData_603235, "Tag.2.key", newJString(Tag2Key))
  add(formData_603235, "Tag.2.value", newJString(Tag2Value))
  add(formData_603235, "Attribute.2.value", newJString(Attribute2Value))
  add(query_603234, "Version", newJString(Version))
  add(formData_603235, "Attribute.2.key", newJString(Attribute2Key))
  result = call_603233.call(nil, query_603234, nil, formData_603235, nil)

var postCreateQueue* = Call_PostCreateQueue_603207(name: "postCreateQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_PostCreateQueue_603208,
    base: "/", url: url_PostCreateQueue_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateQueue_603179 = ref object of OpenApiRestCall_602450
proc url_GetCreateQueue_603181(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateQueue_603180(path: JsonNode; query: JsonNode;
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
  var valid_603182 = query.getOrDefault("Attribute.2.value")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "Attribute.2.value", valid_603182
  var valid_603183 = query.getOrDefault("Tag.0.value")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "Tag.0.value", valid_603183
  var valid_603184 = query.getOrDefault("Tag.2.value")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "Tag.2.value", valid_603184
  var valid_603185 = query.getOrDefault("Attribute.0.key")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "Attribute.0.key", valid_603185
  var valid_603186 = query.getOrDefault("Tag.1.value")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "Tag.1.value", valid_603186
  var valid_603187 = query.getOrDefault("Tag.2.key")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "Tag.2.key", valid_603187
  var valid_603188 = query.getOrDefault("Attribute.1.value")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "Attribute.1.value", valid_603188
  var valid_603189 = query.getOrDefault("Attribute.1.key")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "Attribute.1.key", valid_603189
  var valid_603190 = query.getOrDefault("Tag.0.key")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Tag.0.key", valid_603190
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603191 = query.getOrDefault("Action")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_603191 != nil:
    section.add "Action", valid_603191
  var valid_603192 = query.getOrDefault("Attribute.2.key")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "Attribute.2.key", valid_603192
  var valid_603193 = query.getOrDefault("Tag.1.key")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "Tag.1.key", valid_603193
  var valid_603194 = query.getOrDefault("QueueName")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = nil)
  if valid_603194 != nil:
    section.add "QueueName", valid_603194
  var valid_603195 = query.getOrDefault("Attribute.0.value")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "Attribute.0.value", valid_603195
  var valid_603196 = query.getOrDefault("Version")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603196 != nil:
    section.add "Version", valid_603196
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
  var valid_603197 = header.getOrDefault("X-Amz-Date")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Date", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Security-Token")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Security-Token", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_GetCreateQueue_603179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_GetCreateQueue_603179; QueueName: string;
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
  var query_603206 = newJObject()
  add(query_603206, "Attribute.2.value", newJString(Attribute2Value))
  add(query_603206, "Tag.0.value", newJString(Tag0Value))
  add(query_603206, "Tag.2.value", newJString(Tag2Value))
  add(query_603206, "Attribute.0.key", newJString(Attribute0Key))
  add(query_603206, "Tag.1.value", newJString(Tag1Value))
  add(query_603206, "Tag.2.key", newJString(Tag2Key))
  add(query_603206, "Attribute.1.value", newJString(Attribute1Value))
  add(query_603206, "Attribute.1.key", newJString(Attribute1Key))
  add(query_603206, "Tag.0.key", newJString(Tag0Key))
  add(query_603206, "Action", newJString(Action))
  add(query_603206, "Attribute.2.key", newJString(Attribute2Key))
  add(query_603206, "Tag.1.key", newJString(Tag1Key))
  add(query_603206, "QueueName", newJString(QueueName))
  add(query_603206, "Attribute.0.value", newJString(Attribute0Value))
  add(query_603206, "Version", newJString(Version))
  result = call_603205.call(nil, query_603206, nil, nil, nil)

var getCreateQueue* = Call_GetCreateQueue_603179(name: "getCreateQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_GetCreateQueue_603180,
    base: "/", url: url_GetCreateQueue_603181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessage_603255 = ref object of OpenApiRestCall_602450
proc url_PostDeleteMessage_603257(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostDeleteMessage_603256(path: JsonNode; query: JsonNode;
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
  var valid_603258 = path.getOrDefault("QueueName")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = nil)
  if valid_603258 != nil:
    section.add "QueueName", valid_603258
  var valid_603259 = path.getOrDefault("AccountNumber")
  valid_603259 = validateParameter(valid_603259, JInt, required = true, default = nil)
  if valid_603259 != nil:
    section.add "AccountNumber", valid_603259
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603260 = query.getOrDefault("Action")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_603260 != nil:
    section.add "Action", valid_603260
  var valid_603261 = query.getOrDefault("Version")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603261 != nil:
    section.add "Version", valid_603261
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
  var valid_603262 = header.getOrDefault("X-Amz-Date")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Date", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Security-Token")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Security-Token", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Content-Sha256", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Algorithm")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Algorithm", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Signature")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Signature", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-SignedHeaders", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Credential")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Credential", valid_603268
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_603269 = formData.getOrDefault("ReceiptHandle")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "ReceiptHandle", valid_603269
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_PostDeleteMessage_603255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_PostDeleteMessage_603255; QueueName: string;
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
  var path_603272 = newJObject()
  var query_603273 = newJObject()
  var formData_603274 = newJObject()
  add(path_603272, "QueueName", newJString(QueueName))
  add(query_603273, "Action", newJString(Action))
  add(path_603272, "AccountNumber", newJInt(AccountNumber))
  add(formData_603274, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_603273, "Version", newJString(Version))
  result = call_603271.call(path_603272, query_603273, nil, formData_603274, nil)

var postDeleteMessage* = Call_PostDeleteMessage_603255(name: "postDeleteMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_PostDeleteMessage_603256, base: "/",
    url: url_PostDeleteMessage_603257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessage_603236 = ref object of OpenApiRestCall_602450
proc url_GetDeleteMessage_603238(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeleteMessage_603237(path: JsonNode; query: JsonNode;
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
  var valid_603239 = path.getOrDefault("QueueName")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = nil)
  if valid_603239 != nil:
    section.add "QueueName", valid_603239
  var valid_603240 = path.getOrDefault("AccountNumber")
  valid_603240 = validateParameter(valid_603240, JInt, required = true, default = nil)
  if valid_603240 != nil:
    section.add "AccountNumber", valid_603240
  result.add "path", section
  ## parameters in `query` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ReceiptHandle` field"
  var valid_603241 = query.getOrDefault("ReceiptHandle")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "ReceiptHandle", valid_603241
  var valid_603242 = query.getOrDefault("Action")
  valid_603242 = validateParameter(valid_603242, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_603242 != nil:
    section.add "Action", valid_603242
  var valid_603243 = query.getOrDefault("Version")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603243 != nil:
    section.add "Version", valid_603243
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
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Content-Sha256", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Algorithm")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Algorithm", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Signature")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Signature", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-SignedHeaders", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Credential")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Credential", valid_603250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_GetDeleteMessage_603236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_GetDeleteMessage_603236; ReceiptHandle: string;
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
  var path_603253 = newJObject()
  var query_603254 = newJObject()
  add(query_603254, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_603253, "QueueName", newJString(QueueName))
  add(query_603254, "Action", newJString(Action))
  add(path_603253, "AccountNumber", newJInt(AccountNumber))
  add(query_603254, "Version", newJString(Version))
  result = call_603252.call(path_603253, query_603254, nil, nil, nil)

var getDeleteMessage* = Call_GetDeleteMessage_603236(name: "getDeleteMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_GetDeleteMessage_603237, base: "/",
    url: url_GetDeleteMessage_603238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessageBatch_603294 = ref object of OpenApiRestCall_602450
proc url_PostDeleteMessageBatch_603296(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostDeleteMessageBatch_603295(path: JsonNode; query: JsonNode;
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
  var valid_603297 = path.getOrDefault("QueueName")
  valid_603297 = validateParameter(valid_603297, JString, required = true,
                                 default = nil)
  if valid_603297 != nil:
    section.add "QueueName", valid_603297
  var valid_603298 = path.getOrDefault("AccountNumber")
  valid_603298 = validateParameter(valid_603298, JInt, required = true, default = nil)
  if valid_603298 != nil:
    section.add "AccountNumber", valid_603298
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603299 = query.getOrDefault("Action")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_603299 != nil:
    section.add "Action", valid_603299
  var valid_603300 = query.getOrDefault("Version")
  valid_603300 = validateParameter(valid_603300, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603300 != nil:
    section.add "Version", valid_603300
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
  var valid_603301 = header.getOrDefault("X-Amz-Date")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Date", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Security-Token")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Security-Token", valid_603302
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
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_603308 = formData.getOrDefault("Entries")
  valid_603308 = validateParameter(valid_603308, JArray, required = true, default = nil)
  if valid_603308 != nil:
    section.add "Entries", valid_603308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_PostDeleteMessageBatch_603294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_PostDeleteMessageBatch_603294; Entries: JsonNode;
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
  var path_603311 = newJObject()
  var query_603312 = newJObject()
  var formData_603313 = newJObject()
  if Entries != nil:
    formData_603313.add "Entries", Entries
  add(path_603311, "QueueName", newJString(QueueName))
  add(query_603312, "Action", newJString(Action))
  add(path_603311, "AccountNumber", newJInt(AccountNumber))
  add(query_603312, "Version", newJString(Version))
  result = call_603310.call(path_603311, query_603312, nil, formData_603313, nil)

var postDeleteMessageBatch* = Call_PostDeleteMessageBatch_603294(
    name: "postDeleteMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_PostDeleteMessageBatch_603295, base: "/",
    url: url_PostDeleteMessageBatch_603296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessageBatch_603275 = ref object of OpenApiRestCall_602450
proc url_GetDeleteMessageBatch_603277(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeleteMessageBatch_603276(path: JsonNode; query: JsonNode;
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
  var valid_603278 = path.getOrDefault("QueueName")
  valid_603278 = validateParameter(valid_603278, JString, required = true,
                                 default = nil)
  if valid_603278 != nil:
    section.add "QueueName", valid_603278
  var valid_603279 = path.getOrDefault("AccountNumber")
  valid_603279 = validateParameter(valid_603279, JInt, required = true, default = nil)
  if valid_603279 != nil:
    section.add "AccountNumber", valid_603279
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_603280 = query.getOrDefault("Entries")
  valid_603280 = validateParameter(valid_603280, JArray, required = true, default = nil)
  if valid_603280 != nil:
    section.add "Entries", valid_603280
  var valid_603281 = query.getOrDefault("Action")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_603281 != nil:
    section.add "Action", valid_603281
  var valid_603282 = query.getOrDefault("Version")
  valid_603282 = validateParameter(valid_603282, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603282 != nil:
    section.add "Version", valid_603282
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
  var valid_603283 = header.getOrDefault("X-Amz-Date")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Date", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Security-Token")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Security-Token", valid_603284
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
  if body != nil:
    result.add "body", body

proc call*(call_603290: Call_GetDeleteMessageBatch_603275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603290.validator(path, query, header, formData, body)
  let scheme = call_603290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603290.url(scheme.get, call_603290.host, call_603290.base,
                         call_603290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603290, url, valid)

proc call*(call_603291: Call_GetDeleteMessageBatch_603275; QueueName: string;
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
  var path_603292 = newJObject()
  var query_603293 = newJObject()
  add(path_603292, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_603293.add "Entries", Entries
  add(query_603293, "Action", newJString(Action))
  add(path_603292, "AccountNumber", newJInt(AccountNumber))
  add(query_603293, "Version", newJString(Version))
  result = call_603291.call(path_603292, query_603293, nil, nil, nil)

var getDeleteMessageBatch* = Call_GetDeleteMessageBatch_603275(
    name: "getDeleteMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_GetDeleteMessageBatch_603276, base: "/",
    url: url_GetDeleteMessageBatch_603277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteQueue_603332 = ref object of OpenApiRestCall_602450
proc url_PostDeleteQueue_603334(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostDeleteQueue_603333(path: JsonNode; query: JsonNode;
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
  var valid_603335 = path.getOrDefault("QueueName")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = nil)
  if valid_603335 != nil:
    section.add "QueueName", valid_603335
  var valid_603336 = path.getOrDefault("AccountNumber")
  valid_603336 = validateParameter(valid_603336, JInt, required = true, default = nil)
  if valid_603336 != nil:
    section.add "AccountNumber", valid_603336
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603337 = query.getOrDefault("Action")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_603337 != nil:
    section.add "Action", valid_603337
  var valid_603338 = query.getOrDefault("Version")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603338 != nil:
    section.add "Version", valid_603338
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
  var valid_603339 = header.getOrDefault("X-Amz-Date")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Date", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Security-Token")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Security-Token", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Content-Sha256", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Algorithm")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Algorithm", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Signature")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Signature", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-SignedHeaders", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Credential")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Credential", valid_603345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603346: Call_PostDeleteQueue_603332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603346.validator(path, query, header, formData, body)
  let scheme = call_603346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603346.url(scheme.get, call_603346.host, call_603346.base,
                         call_603346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603346, url, valid)

proc call*(call_603347: Call_PostDeleteQueue_603332; QueueName: string;
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
  var path_603348 = newJObject()
  var query_603349 = newJObject()
  add(path_603348, "QueueName", newJString(QueueName))
  add(query_603349, "Action", newJString(Action))
  add(path_603348, "AccountNumber", newJInt(AccountNumber))
  add(query_603349, "Version", newJString(Version))
  result = call_603347.call(path_603348, query_603349, nil, nil, nil)

var postDeleteQueue* = Call_PostDeleteQueue_603332(name: "postDeleteQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_PostDeleteQueue_603333, base: "/", url: url_PostDeleteQueue_603334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteQueue_603314 = ref object of OpenApiRestCall_602450
proc url_GetDeleteQueue_603316(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDeleteQueue_603315(path: JsonNode; query: JsonNode;
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
  var valid_603317 = path.getOrDefault("QueueName")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = nil)
  if valid_603317 != nil:
    section.add "QueueName", valid_603317
  var valid_603318 = path.getOrDefault("AccountNumber")
  valid_603318 = validateParameter(valid_603318, JInt, required = true, default = nil)
  if valid_603318 != nil:
    section.add "AccountNumber", valid_603318
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603319 = query.getOrDefault("Action")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_603319 != nil:
    section.add "Action", valid_603319
  var valid_603320 = query.getOrDefault("Version")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603320 != nil:
    section.add "Version", valid_603320
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
  var valid_603321 = header.getOrDefault("X-Amz-Date")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Date", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Security-Token")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Security-Token", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Content-Sha256", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Algorithm")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Algorithm", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Signature")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Signature", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-SignedHeaders", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Credential")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Credential", valid_603327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_GetDeleteQueue_603314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603328, url, valid)

proc call*(call_603329: Call_GetDeleteQueue_603314; QueueName: string;
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
  var path_603330 = newJObject()
  var query_603331 = newJObject()
  add(path_603330, "QueueName", newJString(QueueName))
  add(query_603331, "Action", newJString(Action))
  add(path_603330, "AccountNumber", newJInt(AccountNumber))
  add(query_603331, "Version", newJString(Version))
  result = call_603329.call(path_603330, query_603331, nil, nil, nil)

var getDeleteQueue* = Call_GetDeleteQueue_603314(name: "getDeleteQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_GetDeleteQueue_603315, base: "/", url: url_GetDeleteQueue_603316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueAttributes_603369 = ref object of OpenApiRestCall_602450
proc url_PostGetQueueAttributes_603371(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostGetQueueAttributes_603370(path: JsonNode; query: JsonNode;
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
  var valid_603372 = path.getOrDefault("QueueName")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = nil)
  if valid_603372 != nil:
    section.add "QueueName", valid_603372
  var valid_603373 = path.getOrDefault("AccountNumber")
  valid_603373 = validateParameter(valid_603373, JInt, required = true, default = nil)
  if valid_603373 != nil:
    section.add "AccountNumber", valid_603373
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603374 = query.getOrDefault("Action")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_603374 != nil:
    section.add "Action", valid_603374
  var valid_603375 = query.getOrDefault("Version")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603375 != nil:
    section.add "Version", valid_603375
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
  var valid_603376 = header.getOrDefault("X-Amz-Date")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Date", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
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
  var valid_603383 = formData.getOrDefault("AttributeNames")
  valid_603383 = validateParameter(valid_603383, JArray, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "AttributeNames", valid_603383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_PostGetQueueAttributes_603369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_PostGetQueueAttributes_603369; QueueName: string;
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
  var path_603386 = newJObject()
  var query_603387 = newJObject()
  var formData_603388 = newJObject()
  add(path_603386, "QueueName", newJString(QueueName))
  add(query_603387, "Action", newJString(Action))
  add(path_603386, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_603388.add "AttributeNames", AttributeNames
  add(query_603387, "Version", newJString(Version))
  result = call_603385.call(path_603386, query_603387, nil, formData_603388, nil)

var postGetQueueAttributes* = Call_PostGetQueueAttributes_603369(
    name: "postGetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_PostGetQueueAttributes_603370, base: "/",
    url: url_PostGetQueueAttributes_603371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueAttributes_603350 = ref object of OpenApiRestCall_602450
proc url_GetGetQueueAttributes_603352(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetGetQueueAttributes_603351(path: JsonNode; query: JsonNode;
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
  var valid_603353 = path.getOrDefault("QueueName")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "QueueName", valid_603353
  var valid_603354 = path.getOrDefault("AccountNumber")
  valid_603354 = validateParameter(valid_603354, JInt, required = true, default = nil)
  if valid_603354 != nil:
    section.add "AccountNumber", valid_603354
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
  var valid_603355 = query.getOrDefault("AttributeNames")
  valid_603355 = validateParameter(valid_603355, JArray, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "AttributeNames", valid_603355
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603356 = query.getOrDefault("Action")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_603356 != nil:
    section.add "Action", valid_603356
  var valid_603357 = query.getOrDefault("Version")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603357 != nil:
    section.add "Version", valid_603357
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Content-Sha256", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Algorithm")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Algorithm", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Signature")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Signature", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-SignedHeaders", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Credential")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Credential", valid_603364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603365: Call_GetGetQueueAttributes_603350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603365.validator(path, query, header, formData, body)
  let scheme = call_603365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603365.url(scheme.get, call_603365.host, call_603365.base,
                         call_603365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603365, url, valid)

proc call*(call_603366: Call_GetGetQueueAttributes_603350; QueueName: string;
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
  var path_603367 = newJObject()
  var query_603368 = newJObject()
  if AttributeNames != nil:
    query_603368.add "AttributeNames", AttributeNames
  add(path_603367, "QueueName", newJString(QueueName))
  add(query_603368, "Action", newJString(Action))
  add(path_603367, "AccountNumber", newJInt(AccountNumber))
  add(query_603368, "Version", newJString(Version))
  result = call_603366.call(path_603367, query_603368, nil, nil, nil)

var getGetQueueAttributes* = Call_GetGetQueueAttributes_603350(
    name: "getGetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_GetGetQueueAttributes_603351, base: "/",
    url: url_GetGetQueueAttributes_603352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueUrl_603406 = ref object of OpenApiRestCall_602450
proc url_PostGetQueueUrl_603408(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetQueueUrl_603407(path: JsonNode; query: JsonNode;
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
  var valid_603409 = query.getOrDefault("Action")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_603409 != nil:
    section.add "Action", valid_603409
  var valid_603410 = query.getOrDefault("Version")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603410 != nil:
    section.add "Version", valid_603410
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
  var valid_603411 = header.getOrDefault("X-Amz-Date")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Date", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Security-Token")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Security-Token", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Content-Sha256", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Algorithm")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Algorithm", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Signature")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Signature", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-SignedHeaders", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Credential")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Credential", valid_603417
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_603418 = formData.getOrDefault("QueueOwnerAWSAccountId")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "QueueOwnerAWSAccountId", valid_603418
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_603419 = formData.getOrDefault("QueueName")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "QueueName", valid_603419
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603420: Call_PostGetQueueUrl_603406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_603420.validator(path, query, header, formData, body)
  let scheme = call_603420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603420.url(scheme.get, call_603420.host, call_603420.base,
                         call_603420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603420, url, valid)

proc call*(call_603421: Call_PostGetQueueUrl_603406; QueueName: string;
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
  var query_603422 = newJObject()
  var formData_603423 = newJObject()
  add(formData_603423, "QueueOwnerAWSAccountId",
      newJString(QueueOwnerAWSAccountId))
  add(query_603422, "Action", newJString(Action))
  add(formData_603423, "QueueName", newJString(QueueName))
  add(query_603422, "Version", newJString(Version))
  result = call_603421.call(nil, query_603422, nil, formData_603423, nil)

var postGetQueueUrl* = Call_PostGetQueueUrl_603406(name: "postGetQueueUrl",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_PostGetQueueUrl_603407,
    base: "/", url: url_PostGetQueueUrl_603408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueUrl_603389 = ref object of OpenApiRestCall_602450
proc url_GetGetQueueUrl_603391(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetQueueUrl_603390(path: JsonNode; query: JsonNode;
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
  var valid_603392 = query.getOrDefault("Action")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_603392 != nil:
    section.add "Action", valid_603392
  var valid_603393 = query.getOrDefault("QueueOwnerAWSAccountId")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "QueueOwnerAWSAccountId", valid_603393
  var valid_603394 = query.getOrDefault("QueueName")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "QueueName", valid_603394
  var valid_603395 = query.getOrDefault("Version")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603395 != nil:
    section.add "Version", valid_603395
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
  var valid_603396 = header.getOrDefault("X-Amz-Date")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Date", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Security-Token")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Security-Token", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Content-Sha256", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Algorithm")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Algorithm", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Signature")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Signature", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-SignedHeaders", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Credential")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Credential", valid_603402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603403: Call_GetGetQueueUrl_603389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_603403.validator(path, query, header, formData, body)
  let scheme = call_603403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603403.url(scheme.get, call_603403.host, call_603403.base,
                         call_603403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603403, url, valid)

proc call*(call_603404: Call_GetGetQueueUrl_603389; QueueName: string;
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
  var query_603405 = newJObject()
  add(query_603405, "Action", newJString(Action))
  add(query_603405, "QueueOwnerAWSAccountId", newJString(QueueOwnerAWSAccountId))
  add(query_603405, "QueueName", newJString(QueueName))
  add(query_603405, "Version", newJString(Version))
  result = call_603404.call(nil, query_603405, nil, nil, nil)

var getGetQueueUrl* = Call_GetGetQueueUrl_603389(name: "getGetQueueUrl",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_GetGetQueueUrl_603390,
    base: "/", url: url_GetGetQueueUrl_603391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDeadLetterSourceQueues_603442 = ref object of OpenApiRestCall_602450
proc url_PostListDeadLetterSourceQueues_603444(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_PostListDeadLetterSourceQueues_603443(path: JsonNode;
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
  var valid_603445 = path.getOrDefault("QueueName")
  valid_603445 = validateParameter(valid_603445, JString, required = true,
                                 default = nil)
  if valid_603445 != nil:
    section.add "QueueName", valid_603445
  var valid_603446 = path.getOrDefault("AccountNumber")
  valid_603446 = validateParameter(valid_603446, JInt, required = true, default = nil)
  if valid_603446 != nil:
    section.add "AccountNumber", valid_603446
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603447 = query.getOrDefault("Action")
  valid_603447 = validateParameter(valid_603447, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_603447 != nil:
    section.add "Action", valid_603447
  var valid_603448 = query.getOrDefault("Version")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603448 != nil:
    section.add "Version", valid_603448
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
  var valid_603449 = header.getOrDefault("X-Amz-Date")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Date", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Security-Token")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Security-Token", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Content-Sha256", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Signature")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Signature", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-SignedHeaders", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Credential")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Credential", valid_603455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_PostListDeadLetterSourceQueues_603442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_PostListDeadLetterSourceQueues_603442;
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
  var path_603458 = newJObject()
  var query_603459 = newJObject()
  add(path_603458, "QueueName", newJString(QueueName))
  add(query_603459, "Action", newJString(Action))
  add(path_603458, "AccountNumber", newJInt(AccountNumber))
  add(query_603459, "Version", newJString(Version))
  result = call_603457.call(path_603458, query_603459, nil, nil, nil)

var postListDeadLetterSourceQueues* = Call_PostListDeadLetterSourceQueues_603442(
    name: "postListDeadLetterSourceQueues", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_PostListDeadLetterSourceQueues_603443, base: "/",
    url: url_PostListDeadLetterSourceQueues_603444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDeadLetterSourceQueues_603424 = ref object of OpenApiRestCall_602450
proc url_GetListDeadLetterSourceQueues_603426(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetListDeadLetterSourceQueues_603425(path: JsonNode; query: JsonNode;
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
  var valid_603427 = path.getOrDefault("QueueName")
  valid_603427 = validateParameter(valid_603427, JString, required = true,
                                 default = nil)
  if valid_603427 != nil:
    section.add "QueueName", valid_603427
  var valid_603428 = path.getOrDefault("AccountNumber")
  valid_603428 = validateParameter(valid_603428, JInt, required = true, default = nil)
  if valid_603428 != nil:
    section.add "AccountNumber", valid_603428
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603429 = query.getOrDefault("Action")
  valid_603429 = validateParameter(valid_603429, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_603429 != nil:
    section.add "Action", valid_603429
  var valid_603430 = query.getOrDefault("Version")
  valid_603430 = validateParameter(valid_603430, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603430 != nil:
    section.add "Version", valid_603430
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
  var valid_603431 = header.getOrDefault("X-Amz-Date")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Date", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Security-Token")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Security-Token", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Content-Sha256", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Algorithm")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Algorithm", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Signature")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Signature", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-SignedHeaders", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Credential")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Credential", valid_603437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_GetListDeadLetterSourceQueues_603424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_GetListDeadLetterSourceQueues_603424;
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
  var path_603440 = newJObject()
  var query_603441 = newJObject()
  add(path_603440, "QueueName", newJString(QueueName))
  add(query_603441, "Action", newJString(Action))
  add(path_603440, "AccountNumber", newJInt(AccountNumber))
  add(query_603441, "Version", newJString(Version))
  result = call_603439.call(path_603440, query_603441, nil, nil, nil)

var getListDeadLetterSourceQueues* = Call_GetListDeadLetterSourceQueues_603424(
    name: "getListDeadLetterSourceQueues", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_GetListDeadLetterSourceQueues_603425, base: "/",
    url: url_GetListDeadLetterSourceQueues_603426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueueTags_603478 = ref object of OpenApiRestCall_602450
proc url_PostListQueueTags_603480(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostListQueueTags_603479(path: JsonNode; query: JsonNode;
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
  var valid_603481 = path.getOrDefault("QueueName")
  valid_603481 = validateParameter(valid_603481, JString, required = true,
                                 default = nil)
  if valid_603481 != nil:
    section.add "QueueName", valid_603481
  var valid_603482 = path.getOrDefault("AccountNumber")
  valid_603482 = validateParameter(valid_603482, JInt, required = true, default = nil)
  if valid_603482 != nil:
    section.add "AccountNumber", valid_603482
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603483 = query.getOrDefault("Action")
  valid_603483 = validateParameter(valid_603483, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_603483 != nil:
    section.add "Action", valid_603483
  var valid_603484 = query.getOrDefault("Version")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603484 != nil:
    section.add "Version", valid_603484
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
  var valid_603485 = header.getOrDefault("X-Amz-Date")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Date", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Security-Token")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Security-Token", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603492: Call_PostListQueueTags_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603492.validator(path, query, header, formData, body)
  let scheme = call_603492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603492.url(scheme.get, call_603492.host, call_603492.base,
                         call_603492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603492, url, valid)

proc call*(call_603493: Call_PostListQueueTags_603478; QueueName: string;
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
  var path_603494 = newJObject()
  var query_603495 = newJObject()
  add(path_603494, "QueueName", newJString(QueueName))
  add(query_603495, "Action", newJString(Action))
  add(path_603494, "AccountNumber", newJInt(AccountNumber))
  add(query_603495, "Version", newJString(Version))
  result = call_603493.call(path_603494, query_603495, nil, nil, nil)

var postListQueueTags* = Call_PostListQueueTags_603478(name: "postListQueueTags",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_PostListQueueTags_603479, base: "/",
    url: url_PostListQueueTags_603480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueueTags_603460 = ref object of OpenApiRestCall_602450
proc url_GetListQueueTags_603462(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetListQueueTags_603461(path: JsonNode; query: JsonNode;
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
  var valid_603463 = path.getOrDefault("QueueName")
  valid_603463 = validateParameter(valid_603463, JString, required = true,
                                 default = nil)
  if valid_603463 != nil:
    section.add "QueueName", valid_603463
  var valid_603464 = path.getOrDefault("AccountNumber")
  valid_603464 = validateParameter(valid_603464, JInt, required = true, default = nil)
  if valid_603464 != nil:
    section.add "AccountNumber", valid_603464
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603465 = query.getOrDefault("Action")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_603465 != nil:
    section.add "Action", valid_603465
  var valid_603466 = query.getOrDefault("Version")
  valid_603466 = validateParameter(valid_603466, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603466 != nil:
    section.add "Version", valid_603466
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
  var valid_603467 = header.getOrDefault("X-Amz-Date")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Date", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Security-Token")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Security-Token", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-SignedHeaders", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_GetListQueueTags_603460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_GetListQueueTags_603460; QueueName: string;
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
  var path_603476 = newJObject()
  var query_603477 = newJObject()
  add(path_603476, "QueueName", newJString(QueueName))
  add(query_603477, "Action", newJString(Action))
  add(path_603476, "AccountNumber", newJInt(AccountNumber))
  add(query_603477, "Version", newJString(Version))
  result = call_603475.call(path_603476, query_603477, nil, nil, nil)

var getListQueueTags* = Call_GetListQueueTags_603460(name: "getListQueueTags",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_GetListQueueTags_603461, base: "/",
    url: url_GetListQueueTags_603462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueues_603512 = ref object of OpenApiRestCall_602450
proc url_PostListQueues_603514(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListQueues_603513(path: JsonNode; query: JsonNode;
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
  var valid_603515 = query.getOrDefault("Action")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_603515 != nil:
    section.add "Action", valid_603515
  var valid_603516 = query.getOrDefault("Version")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603516 != nil:
    section.add "Version", valid_603516
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Content-Sha256", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Algorithm")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Algorithm", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Signature")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Signature", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-SignedHeaders", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Credential")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Credential", valid_603523
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_603524 = formData.getOrDefault("QueueNamePrefix")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "QueueNamePrefix", valid_603524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603525: Call_PostListQueues_603512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603525.validator(path, query, header, formData, body)
  let scheme = call_603525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603525.url(scheme.get, call_603525.host, call_603525.base,
                         call_603525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603525, url, valid)

proc call*(call_603526: Call_PostListQueues_603512; QueueNamePrefix: string = "";
          Action: string = "ListQueues"; Version: string = "2012-11-05"): Recallable =
  ## postListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603527 = newJObject()
  var formData_603528 = newJObject()
  add(formData_603528, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_603527, "Action", newJString(Action))
  add(query_603527, "Version", newJString(Version))
  result = call_603526.call(nil, query_603527, nil, formData_603528, nil)

var postListQueues* = Call_PostListQueues_603512(name: "postListQueues",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_PostListQueues_603513,
    base: "/", url: url_PostListQueues_603514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueues_603496 = ref object of OpenApiRestCall_602450
proc url_GetListQueues_603498(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListQueues_603497(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603499 = query.getOrDefault("Action")
  valid_603499 = validateParameter(valid_603499, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_603499 != nil:
    section.add "Action", valid_603499
  var valid_603500 = query.getOrDefault("QueueNamePrefix")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "QueueNamePrefix", valid_603500
  var valid_603501 = query.getOrDefault("Version")
  valid_603501 = validateParameter(valid_603501, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603501 != nil:
    section.add "Version", valid_603501
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
  var valid_603502 = header.getOrDefault("X-Amz-Date")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Date", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Security-Token")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Security-Token", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Content-Sha256", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Algorithm")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Algorithm", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Signature")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Signature", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-SignedHeaders", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Credential")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Credential", valid_603508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603509: Call_GetListQueues_603496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603509.validator(path, query, header, formData, body)
  let scheme = call_603509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603509.url(scheme.get, call_603509.host, call_603509.base,
                         call_603509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603509, url, valid)

proc call*(call_603510: Call_GetListQueues_603496; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_603511 = newJObject()
  add(query_603511, "Action", newJString(Action))
  add(query_603511, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_603511, "Version", newJString(Version))
  result = call_603510.call(nil, query_603511, nil, nil, nil)

var getListQueues* = Call_GetListQueues_603496(name: "getListQueues",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_GetListQueues_603497,
    base: "/", url: url_GetListQueues_603498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurgeQueue_603547 = ref object of OpenApiRestCall_602450
proc url_PostPurgeQueue_603549(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostPurgeQueue_603548(path: JsonNode; query: JsonNode;
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
  var valid_603550 = path.getOrDefault("QueueName")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = nil)
  if valid_603550 != nil:
    section.add "QueueName", valid_603550
  var valid_603551 = path.getOrDefault("AccountNumber")
  valid_603551 = validateParameter(valid_603551, JInt, required = true, default = nil)
  if valid_603551 != nil:
    section.add "AccountNumber", valid_603551
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603552 = query.getOrDefault("Action")
  valid_603552 = validateParameter(valid_603552, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_603552 != nil:
    section.add "Action", valid_603552
  var valid_603553 = query.getOrDefault("Version")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603553 != nil:
    section.add "Version", valid_603553
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
  var valid_603554 = header.getOrDefault("X-Amz-Date")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Date", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Security-Token")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Security-Token", valid_603555
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
  if body != nil:
    result.add "body", body

proc call*(call_603561: Call_PostPurgeQueue_603547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_603561.validator(path, query, header, formData, body)
  let scheme = call_603561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603561.url(scheme.get, call_603561.host, call_603561.base,
                         call_603561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603561, url, valid)

proc call*(call_603562: Call_PostPurgeQueue_603547; QueueName: string;
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
  var path_603563 = newJObject()
  var query_603564 = newJObject()
  add(path_603563, "QueueName", newJString(QueueName))
  add(query_603564, "Action", newJString(Action))
  add(path_603563, "AccountNumber", newJInt(AccountNumber))
  add(query_603564, "Version", newJString(Version))
  result = call_603562.call(path_603563, query_603564, nil, nil, nil)

var postPurgeQueue* = Call_PostPurgeQueue_603547(name: "postPurgeQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_PostPurgeQueue_603548, base: "/", url: url_PostPurgeQueue_603549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurgeQueue_603529 = ref object of OpenApiRestCall_602450
proc url_GetPurgeQueue_603531(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetPurgeQueue_603530(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603532 = path.getOrDefault("QueueName")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = nil)
  if valid_603532 != nil:
    section.add "QueueName", valid_603532
  var valid_603533 = path.getOrDefault("AccountNumber")
  valid_603533 = validateParameter(valid_603533, JInt, required = true, default = nil)
  if valid_603533 != nil:
    section.add "AccountNumber", valid_603533
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603534 = query.getOrDefault("Action")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_603534 != nil:
    section.add "Action", valid_603534
  var valid_603535 = query.getOrDefault("Version")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603535 != nil:
    section.add "Version", valid_603535
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
  var valid_603536 = header.getOrDefault("X-Amz-Date")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Date", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Security-Token")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Security-Token", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Content-Sha256", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Algorithm")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Algorithm", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Signature")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Signature", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-SignedHeaders", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Credential")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Credential", valid_603542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603543: Call_GetPurgeQueue_603529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_603543.validator(path, query, header, formData, body)
  let scheme = call_603543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603543.url(scheme.get, call_603543.host, call_603543.base,
                         call_603543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603543, url, valid)

proc call*(call_603544: Call_GetPurgeQueue_603529; QueueName: string;
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
  var path_603545 = newJObject()
  var query_603546 = newJObject()
  add(path_603545, "QueueName", newJString(QueueName))
  add(query_603546, "Action", newJString(Action))
  add(path_603545, "AccountNumber", newJInt(AccountNumber))
  add(query_603546, "Version", newJString(Version))
  result = call_603544.call(path_603545, query_603546, nil, nil, nil)

var getPurgeQueue* = Call_GetPurgeQueue_603529(name: "getPurgeQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_GetPurgeQueue_603530, base: "/", url: url_GetPurgeQueue_603531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostReceiveMessage_603589 = ref object of OpenApiRestCall_602450
proc url_PostReceiveMessage_603591(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostReceiveMessage_603590(path: JsonNode; query: JsonNode;
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
  var valid_603592 = path.getOrDefault("QueueName")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = nil)
  if valid_603592 != nil:
    section.add "QueueName", valid_603592
  var valid_603593 = path.getOrDefault("AccountNumber")
  valid_603593 = validateParameter(valid_603593, JInt, required = true, default = nil)
  if valid_603593 != nil:
    section.add "AccountNumber", valid_603593
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603594 = query.getOrDefault("Action")
  valid_603594 = validateParameter(valid_603594, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_603594 != nil:
    section.add "Action", valid_603594
  var valid_603595 = query.getOrDefault("Version")
  valid_603595 = validateParameter(valid_603595, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603595 != nil:
    section.add "Version", valid_603595
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
  var valid_603596 = header.getOrDefault("X-Amz-Date")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Date", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Security-Token")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Security-Token", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Content-Sha256", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Algorithm")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Algorithm", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-SignedHeaders", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Credential")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Credential", valid_603602
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
  var valid_603603 = formData.getOrDefault("VisibilityTimeout")
  valid_603603 = validateParameter(valid_603603, JInt, required = false, default = nil)
  if valid_603603 != nil:
    section.add "VisibilityTimeout", valid_603603
  var valid_603604 = formData.getOrDefault("MaxNumberOfMessages")
  valid_603604 = validateParameter(valid_603604, JInt, required = false, default = nil)
  if valid_603604 != nil:
    section.add "MaxNumberOfMessages", valid_603604
  var valid_603605 = formData.getOrDefault("ReceiveRequestAttemptId")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "ReceiveRequestAttemptId", valid_603605
  var valid_603606 = formData.getOrDefault("MessageAttributeNames")
  valid_603606 = validateParameter(valid_603606, JArray, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "MessageAttributeNames", valid_603606
  var valid_603607 = formData.getOrDefault("AttributeNames")
  valid_603607 = validateParameter(valid_603607, JArray, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "AttributeNames", valid_603607
  var valid_603608 = formData.getOrDefault("WaitTimeSeconds")
  valid_603608 = validateParameter(valid_603608, JInt, required = false, default = nil)
  if valid_603608 != nil:
    section.add "WaitTimeSeconds", valid_603608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_PostReceiveMessage_603589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603609, url, valid)

proc call*(call_603610: Call_PostReceiveMessage_603589; QueueName: string;
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
  var path_603611 = newJObject()
  var query_603612 = newJObject()
  var formData_603613 = newJObject()
  add(formData_603613, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(formData_603613, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(formData_603613, "ReceiveRequestAttemptId",
      newJString(ReceiveRequestAttemptId))
  add(path_603611, "QueueName", newJString(QueueName))
  add(query_603612, "Action", newJString(Action))
  if MessageAttributeNames != nil:
    formData_603613.add "MessageAttributeNames", MessageAttributeNames
  add(path_603611, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_603613.add "AttributeNames", AttributeNames
  add(query_603612, "Version", newJString(Version))
  add(formData_603613, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  result = call_603610.call(path_603611, query_603612, nil, formData_603613, nil)

var postReceiveMessage* = Call_PostReceiveMessage_603589(
    name: "postReceiveMessage", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_PostReceiveMessage_603590, base: "/",
    url: url_PostReceiveMessage_603591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReceiveMessage_603565 = ref object of OpenApiRestCall_602450
proc url_GetReceiveMessage_603567(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetReceiveMessage_603566(path: JsonNode; query: JsonNode;
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
  var valid_603568 = path.getOrDefault("QueueName")
  valid_603568 = validateParameter(valid_603568, JString, required = true,
                                 default = nil)
  if valid_603568 != nil:
    section.add "QueueName", valid_603568
  var valid_603569 = path.getOrDefault("AccountNumber")
  valid_603569 = validateParameter(valid_603569, JInt, required = true, default = nil)
  if valid_603569 != nil:
    section.add "AccountNumber", valid_603569
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
  var valid_603570 = query.getOrDefault("ReceiveRequestAttemptId")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "ReceiveRequestAttemptId", valid_603570
  var valid_603571 = query.getOrDefault("AttributeNames")
  valid_603571 = validateParameter(valid_603571, JArray, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "AttributeNames", valid_603571
  var valid_603572 = query.getOrDefault("WaitTimeSeconds")
  valid_603572 = validateParameter(valid_603572, JInt, required = false, default = nil)
  if valid_603572 != nil:
    section.add "WaitTimeSeconds", valid_603572
  var valid_603573 = query.getOrDefault("MessageAttributeNames")
  valid_603573 = validateParameter(valid_603573, JArray, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "MessageAttributeNames", valid_603573
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603574 = query.getOrDefault("Action")
  valid_603574 = validateParameter(valid_603574, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_603574 != nil:
    section.add "Action", valid_603574
  var valid_603575 = query.getOrDefault("MaxNumberOfMessages")
  valid_603575 = validateParameter(valid_603575, JInt, required = false, default = nil)
  if valid_603575 != nil:
    section.add "MaxNumberOfMessages", valid_603575
  var valid_603576 = query.getOrDefault("Version")
  valid_603576 = validateParameter(valid_603576, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603576 != nil:
    section.add "Version", valid_603576
  var valid_603577 = query.getOrDefault("VisibilityTimeout")
  valid_603577 = validateParameter(valid_603577, JInt, required = false, default = nil)
  if valid_603577 != nil:
    section.add "VisibilityTimeout", valid_603577
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
  var valid_603578 = header.getOrDefault("X-Amz-Date")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Date", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Security-Token")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Security-Token", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Content-Sha256", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Algorithm")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Algorithm", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Signature")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Signature", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-SignedHeaders", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Credential")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Credential", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603585: Call_GetReceiveMessage_603565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_603585.validator(path, query, header, formData, body)
  let scheme = call_603585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603585.url(scheme.get, call_603585.host, call_603585.base,
                         call_603585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603585, url, valid)

proc call*(call_603586: Call_GetReceiveMessage_603565; QueueName: string;
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
  var path_603587 = newJObject()
  var query_603588 = newJObject()
  add(query_603588, "ReceiveRequestAttemptId", newJString(ReceiveRequestAttemptId))
  if AttributeNames != nil:
    query_603588.add "AttributeNames", AttributeNames
  add(path_603587, "QueueName", newJString(QueueName))
  add(query_603588, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  if MessageAttributeNames != nil:
    query_603588.add "MessageAttributeNames", MessageAttributeNames
  add(query_603588, "Action", newJString(Action))
  add(path_603587, "AccountNumber", newJInt(AccountNumber))
  add(query_603588, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(query_603588, "Version", newJString(Version))
  add(query_603588, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_603586.call(path_603587, query_603588, nil, nil, nil)

var getReceiveMessage* = Call_GetReceiveMessage_603565(name: "getReceiveMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_GetReceiveMessage_603566, base: "/",
    url: url_GetReceiveMessage_603567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_603633 = ref object of OpenApiRestCall_602450
proc url_PostRemovePermission_603635(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostRemovePermission_603634(path: JsonNode; query: JsonNode;
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
  var valid_603636 = path.getOrDefault("QueueName")
  valid_603636 = validateParameter(valid_603636, JString, required = true,
                                 default = nil)
  if valid_603636 != nil:
    section.add "QueueName", valid_603636
  var valid_603637 = path.getOrDefault("AccountNumber")
  valid_603637 = validateParameter(valid_603637, JInt, required = true, default = nil)
  if valid_603637 != nil:
    section.add "AccountNumber", valid_603637
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603638 = query.getOrDefault("Action")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603638 != nil:
    section.add "Action", valid_603638
  var valid_603639 = query.getOrDefault("Version")
  valid_603639 = validateParameter(valid_603639, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603639 != nil:
    section.add "Version", valid_603639
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
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Content-Sha256", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Algorithm")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Algorithm", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Signature")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Signature", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-SignedHeaders", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Credential")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Credential", valid_603646
  result.add "header", section
  ## parameters in `formData` object:
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Label` field"
  var valid_603647 = formData.getOrDefault("Label")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = nil)
  if valid_603647 != nil:
    section.add "Label", valid_603647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_PostRemovePermission_603633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_PostRemovePermission_603633; Label: string;
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
  var path_603650 = newJObject()
  var query_603651 = newJObject()
  var formData_603652 = newJObject()
  add(formData_603652, "Label", newJString(Label))
  add(path_603650, "QueueName", newJString(QueueName))
  add(query_603651, "Action", newJString(Action))
  add(path_603650, "AccountNumber", newJInt(AccountNumber))
  add(query_603651, "Version", newJString(Version))
  result = call_603649.call(path_603650, query_603651, nil, formData_603652, nil)

var postRemovePermission* = Call_PostRemovePermission_603633(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_PostRemovePermission_603634, base: "/",
    url: url_PostRemovePermission_603635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_603614 = ref object of OpenApiRestCall_602450
proc url_GetRemovePermission_603616(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetRemovePermission_603615(path: JsonNode; query: JsonNode;
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
  var valid_603617 = path.getOrDefault("QueueName")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "QueueName", valid_603617
  var valid_603618 = path.getOrDefault("AccountNumber")
  valid_603618 = validateParameter(valid_603618, JInt, required = true, default = nil)
  if valid_603618 != nil:
    section.add "AccountNumber", valid_603618
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603619 = query.getOrDefault("Action")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_603619 != nil:
    section.add "Action", valid_603619
  var valid_603620 = query.getOrDefault("Version")
  valid_603620 = validateParameter(valid_603620, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603620 != nil:
    section.add "Version", valid_603620
  var valid_603621 = query.getOrDefault("Label")
  valid_603621 = validateParameter(valid_603621, JString, required = true,
                                 default = nil)
  if valid_603621 != nil:
    section.add "Label", valid_603621
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
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Content-Sha256", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Algorithm")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Algorithm", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Signature")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Signature", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-SignedHeaders", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Credential")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Credential", valid_603628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603629: Call_GetRemovePermission_603614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_603629.validator(path, query, header, formData, body)
  let scheme = call_603629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603629.url(scheme.get, call_603629.host, call_603629.base,
                         call_603629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603629, url, valid)

proc call*(call_603630: Call_GetRemovePermission_603614; QueueName: string;
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
  var path_603631 = newJObject()
  var query_603632 = newJObject()
  add(path_603631, "QueueName", newJString(QueueName))
  add(query_603632, "Action", newJString(Action))
  add(path_603631, "AccountNumber", newJInt(AccountNumber))
  add(query_603632, "Version", newJString(Version))
  add(query_603632, "Label", newJString(Label))
  result = call_603630.call(path_603631, query_603632, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_603614(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_GetRemovePermission_603615, base: "/",
    url: url_GetRemovePermission_603616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessage_603687 = ref object of OpenApiRestCall_602450
proc url_PostSendMessage_603689(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostSendMessage_603688(path: JsonNode; query: JsonNode;
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
  var valid_603690 = path.getOrDefault("QueueName")
  valid_603690 = validateParameter(valid_603690, JString, required = true,
                                 default = nil)
  if valid_603690 != nil:
    section.add "QueueName", valid_603690
  var valid_603691 = path.getOrDefault("AccountNumber")
  valid_603691 = validateParameter(valid_603691, JInt, required = true, default = nil)
  if valid_603691 != nil:
    section.add "AccountNumber", valid_603691
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603692 = query.getOrDefault("Action")
  valid_603692 = validateParameter(valid_603692, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_603692 != nil:
    section.add "Action", valid_603692
  var valid_603693 = query.getOrDefault("Version")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603693 != nil:
    section.add "Version", valid_603693
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
  var valid_603694 = header.getOrDefault("X-Amz-Date")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Date", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Security-Token")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Security-Token", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Content-Sha256", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Algorithm")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Algorithm", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Signature")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Signature", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-SignedHeaders", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Credential")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Credential", valid_603700
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
  var valid_603701 = formData.getOrDefault("MessageSystemAttribute.1.value")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "MessageSystemAttribute.1.value", valid_603701
  var valid_603702 = formData.getOrDefault("MessageAttribute.1.key")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "MessageAttribute.1.key", valid_603702
  var valid_603703 = formData.getOrDefault("DelaySeconds")
  valid_603703 = validateParameter(valid_603703, JInt, required = false, default = nil)
  if valid_603703 != nil:
    section.add "DelaySeconds", valid_603703
  var valid_603704 = formData.getOrDefault("MessageGroupId")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "MessageGroupId", valid_603704
  var valid_603705 = formData.getOrDefault("MessageAttribute.0.value")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "MessageAttribute.0.value", valid_603705
  var valid_603706 = formData.getOrDefault("MessageSystemAttribute.2.key")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "MessageSystemAttribute.2.key", valid_603706
  var valid_603707 = formData.getOrDefault("MessageDeduplicationId")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "MessageDeduplicationId", valid_603707
  var valid_603708 = formData.getOrDefault("MessageAttribute.2.key")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "MessageAttribute.2.key", valid_603708
  var valid_603709 = formData.getOrDefault("MessageSystemAttribute.0.key")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "MessageSystemAttribute.0.key", valid_603709
  assert formData != nil,
        "formData argument is necessary due to required `MessageBody` field"
  var valid_603710 = formData.getOrDefault("MessageBody")
  valid_603710 = validateParameter(valid_603710, JString, required = true,
                                 default = nil)
  if valid_603710 != nil:
    section.add "MessageBody", valid_603710
  var valid_603711 = formData.getOrDefault("MessageAttribute.0.key")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "MessageAttribute.0.key", valid_603711
  var valid_603712 = formData.getOrDefault("MessageSystemAttribute.2.value")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "MessageSystemAttribute.2.value", valid_603712
  var valid_603713 = formData.getOrDefault("MessageAttribute.1.value")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "MessageAttribute.1.value", valid_603713
  var valid_603714 = formData.getOrDefault("MessageSystemAttribute.0.value")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "MessageSystemAttribute.0.value", valid_603714
  var valid_603715 = formData.getOrDefault("MessageAttribute.2.value")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "MessageAttribute.2.value", valid_603715
  var valid_603716 = formData.getOrDefault("MessageSystemAttribute.1.key")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "MessageSystemAttribute.1.key", valid_603716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_PostSendMessage_603687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603717, url, valid)

proc call*(call_603718: Call_PostSendMessage_603687; QueueName: string;
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
  var path_603719 = newJObject()
  var query_603720 = newJObject()
  var formData_603721 = newJObject()
  add(formData_603721, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(formData_603721, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(formData_603721, "DelaySeconds", newJInt(DelaySeconds))
  add(formData_603721, "MessageGroupId", newJString(MessageGroupId))
  add(formData_603721, "MessageAttribute.0.value",
      newJString(MessageAttribute0Value))
  add(formData_603721, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(formData_603721, "MessageDeduplicationId",
      newJString(MessageDeduplicationId))
  add(path_603719, "QueueName", newJString(QueueName))
  add(formData_603721, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(formData_603721, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(formData_603721, "MessageBody", newJString(MessageBody))
  add(query_603720, "Action", newJString(Action))
  add(formData_603721, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(formData_603721, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(formData_603721, "MessageAttribute.1.value",
      newJString(MessageAttribute1Value))
  add(formData_603721, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(formData_603721, "MessageAttribute.2.value",
      newJString(MessageAttribute2Value))
  add(path_603719, "AccountNumber", newJInt(AccountNumber))
  add(query_603720, "Version", newJString(Version))
  add(formData_603721, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  result = call_603718.call(path_603719, query_603720, nil, formData_603721, nil)

var postSendMessage* = Call_PostSendMessage_603687(name: "postSendMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_PostSendMessage_603688, base: "/", url: url_PostSendMessage_603689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessage_603653 = ref object of OpenApiRestCall_602450
proc url_GetSendMessage_603655(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSendMessage_603654(path: JsonNode; query: JsonNode;
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
  var valid_603656 = path.getOrDefault("QueueName")
  valid_603656 = validateParameter(valid_603656, JString, required = true,
                                 default = nil)
  if valid_603656 != nil:
    section.add "QueueName", valid_603656
  var valid_603657 = path.getOrDefault("AccountNumber")
  valid_603657 = validateParameter(valid_603657, JInt, required = true, default = nil)
  if valid_603657 != nil:
    section.add "AccountNumber", valid_603657
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
  var valid_603658 = query.getOrDefault("MessageAttribute.0.key")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "MessageAttribute.0.key", valid_603658
  var valid_603659 = query.getOrDefault("MessageSystemAttribute.1.key")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "MessageSystemAttribute.1.key", valid_603659
  var valid_603660 = query.getOrDefault("MessageSystemAttribute.0.value")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "MessageSystemAttribute.0.value", valid_603660
  var valid_603661 = query.getOrDefault("MessageGroupId")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "MessageGroupId", valid_603661
  var valid_603662 = query.getOrDefault("MessageSystemAttribute.2.value")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "MessageSystemAttribute.2.value", valid_603662
  var valid_603663 = query.getOrDefault("MessageAttribute.2.key")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "MessageAttribute.2.key", valid_603663
  var valid_603664 = query.getOrDefault("MessageSystemAttribute.2.key")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "MessageSystemAttribute.2.key", valid_603664
  var valid_603665 = query.getOrDefault("MessageDeduplicationId")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "MessageDeduplicationId", valid_603665
  var valid_603666 = query.getOrDefault("MessageAttribute.2.value")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "MessageAttribute.2.value", valid_603666
  var valid_603667 = query.getOrDefault("MessageSystemAttribute.1.value")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "MessageSystemAttribute.1.value", valid_603667
  var valid_603668 = query.getOrDefault("MessageSystemAttribute.0.key")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "MessageSystemAttribute.0.key", valid_603668
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603669 = query.getOrDefault("Action")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_603669 != nil:
    section.add "Action", valid_603669
  var valid_603670 = query.getOrDefault("MessageAttribute.1.value")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "MessageAttribute.1.value", valid_603670
  var valid_603671 = query.getOrDefault("DelaySeconds")
  valid_603671 = validateParameter(valid_603671, JInt, required = false, default = nil)
  if valid_603671 != nil:
    section.add "DelaySeconds", valid_603671
  var valid_603672 = query.getOrDefault("MessageAttribute.0.value")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "MessageAttribute.0.value", valid_603672
  var valid_603673 = query.getOrDefault("MessageBody")
  valid_603673 = validateParameter(valid_603673, JString, required = true,
                                 default = nil)
  if valid_603673 != nil:
    section.add "MessageBody", valid_603673
  var valid_603674 = query.getOrDefault("Version")
  valid_603674 = validateParameter(valid_603674, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603674 != nil:
    section.add "Version", valid_603674
  var valid_603675 = query.getOrDefault("MessageAttribute.1.key")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "MessageAttribute.1.key", valid_603675
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
  var valid_603676 = header.getOrDefault("X-Amz-Date")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Date", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Security-Token")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Security-Token", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Content-Sha256", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Algorithm")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Algorithm", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Signature")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Signature", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Credential")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Credential", valid_603682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603683: Call_GetSendMessage_603653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_603683.validator(path, query, header, formData, body)
  let scheme = call_603683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603683.url(scheme.get, call_603683.host, call_603683.base,
                         call_603683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603683, url, valid)

proc call*(call_603684: Call_GetSendMessage_603653; QueueName: string;
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
  var path_603685 = newJObject()
  var query_603686 = newJObject()
  add(query_603686, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(query_603686, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_603686, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(query_603686, "MessageGroupId", newJString(MessageGroupId))
  add(query_603686, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(query_603686, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(query_603686, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(query_603686, "MessageDeduplicationId", newJString(MessageDeduplicationId))
  add(path_603685, "QueueName", newJString(QueueName))
  add(query_603686, "MessageAttribute.2.value", newJString(MessageAttribute2Value))
  add(query_603686, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(query_603686, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(query_603686, "Action", newJString(Action))
  add(query_603686, "MessageAttribute.1.value", newJString(MessageAttribute1Value))
  add(query_603686, "DelaySeconds", newJInt(DelaySeconds))
  add(path_603685, "AccountNumber", newJInt(AccountNumber))
  add(query_603686, "MessageAttribute.0.value", newJString(MessageAttribute0Value))
  add(query_603686, "MessageBody", newJString(MessageBody))
  add(query_603686, "Version", newJString(Version))
  add(query_603686, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  result = call_603684.call(path_603685, query_603686, nil, nil, nil)

var getSendMessage* = Call_GetSendMessage_603653(name: "getSendMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_GetSendMessage_603654, base: "/", url: url_GetSendMessage_603655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessageBatch_603741 = ref object of OpenApiRestCall_602450
proc url_PostSendMessageBatch_603743(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostSendMessageBatch_603742(path: JsonNode; query: JsonNode;
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
  var valid_603744 = path.getOrDefault("QueueName")
  valid_603744 = validateParameter(valid_603744, JString, required = true,
                                 default = nil)
  if valid_603744 != nil:
    section.add "QueueName", valid_603744
  var valid_603745 = path.getOrDefault("AccountNumber")
  valid_603745 = validateParameter(valid_603745, JInt, required = true, default = nil)
  if valid_603745 != nil:
    section.add "AccountNumber", valid_603745
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603746 = query.getOrDefault("Action")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_603746 != nil:
    section.add "Action", valid_603746
  var valid_603747 = query.getOrDefault("Version")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603747 != nil:
    section.add "Version", valid_603747
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
  var valid_603748 = header.getOrDefault("X-Amz-Date")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Date", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Security-Token")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Security-Token", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Content-Sha256", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Algorithm")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Algorithm", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Signature")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Signature", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-SignedHeaders", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Credential")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Credential", valid_603754
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_603755 = formData.getOrDefault("Entries")
  valid_603755 = validateParameter(valid_603755, JArray, required = true, default = nil)
  if valid_603755 != nil:
    section.add "Entries", valid_603755
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_PostSendMessageBatch_603741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_PostSendMessageBatch_603741; Entries: JsonNode;
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
  var path_603758 = newJObject()
  var query_603759 = newJObject()
  var formData_603760 = newJObject()
  if Entries != nil:
    formData_603760.add "Entries", Entries
  add(path_603758, "QueueName", newJString(QueueName))
  add(query_603759, "Action", newJString(Action))
  add(path_603758, "AccountNumber", newJInt(AccountNumber))
  add(query_603759, "Version", newJString(Version))
  result = call_603757.call(path_603758, query_603759, nil, formData_603760, nil)

var postSendMessageBatch* = Call_PostSendMessageBatch_603741(
    name: "postSendMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_PostSendMessageBatch_603742, base: "/",
    url: url_PostSendMessageBatch_603743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessageBatch_603722 = ref object of OpenApiRestCall_602450
proc url_GetSendMessageBatch_603724(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSendMessageBatch_603723(path: JsonNode; query: JsonNode;
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
  var valid_603725 = path.getOrDefault("QueueName")
  valid_603725 = validateParameter(valid_603725, JString, required = true,
                                 default = nil)
  if valid_603725 != nil:
    section.add "QueueName", valid_603725
  var valid_603726 = path.getOrDefault("AccountNumber")
  valid_603726 = validateParameter(valid_603726, JInt, required = true, default = nil)
  if valid_603726 != nil:
    section.add "AccountNumber", valid_603726
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_603727 = query.getOrDefault("Entries")
  valid_603727 = validateParameter(valid_603727, JArray, required = true, default = nil)
  if valid_603727 != nil:
    section.add "Entries", valid_603727
  var valid_603728 = query.getOrDefault("Action")
  valid_603728 = validateParameter(valid_603728, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_603728 != nil:
    section.add "Action", valid_603728
  var valid_603729 = query.getOrDefault("Version")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603729 != nil:
    section.add "Version", valid_603729
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
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Security-Token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Security-Token", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Content-Sha256", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Algorithm")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Algorithm", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Signature")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Signature", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-SignedHeaders", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Credential")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Credential", valid_603736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603737: Call_GetSendMessageBatch_603722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_603737.validator(path, query, header, formData, body)
  let scheme = call_603737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603737.url(scheme.get, call_603737.host, call_603737.base,
                         call_603737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603737, url, valid)

proc call*(call_603738: Call_GetSendMessageBatch_603722; QueueName: string;
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
  var path_603739 = newJObject()
  var query_603740 = newJObject()
  add(path_603739, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_603740.add "Entries", Entries
  add(query_603740, "Action", newJString(Action))
  add(path_603739, "AccountNumber", newJInt(AccountNumber))
  add(query_603740, "Version", newJString(Version))
  result = call_603738.call(path_603739, query_603740, nil, nil, nil)

var getSendMessageBatch* = Call_GetSendMessageBatch_603722(
    name: "getSendMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_GetSendMessageBatch_603723, base: "/",
    url: url_GetSendMessageBatch_603724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetQueueAttributes_603785 = ref object of OpenApiRestCall_602450
proc url_PostSetQueueAttributes_603787(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostSetQueueAttributes_603786(path: JsonNode; query: JsonNode;
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
  var valid_603788 = path.getOrDefault("QueueName")
  valid_603788 = validateParameter(valid_603788, JString, required = true,
                                 default = nil)
  if valid_603788 != nil:
    section.add "QueueName", valid_603788
  var valid_603789 = path.getOrDefault("AccountNumber")
  valid_603789 = validateParameter(valid_603789, JInt, required = true, default = nil)
  if valid_603789 != nil:
    section.add "AccountNumber", valid_603789
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603790 = query.getOrDefault("Action")
  valid_603790 = validateParameter(valid_603790, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_603790 != nil:
    section.add "Action", valid_603790
  var valid_603791 = query.getOrDefault("Version")
  valid_603791 = validateParameter(valid_603791, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603791 != nil:
    section.add "Version", valid_603791
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
  var valid_603792 = header.getOrDefault("X-Amz-Date")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Date", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Security-Token")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Security-Token", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Content-Sha256", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Algorithm")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Algorithm", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Signature")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Signature", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-SignedHeaders", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Credential")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Credential", valid_603798
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attribute.0.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.value: JString
  ##   Attribute.1.key: JString
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  section = newJObject()
  var valid_603799 = formData.getOrDefault("Attribute.0.key")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "Attribute.0.key", valid_603799
  var valid_603800 = formData.getOrDefault("Attribute.0.value")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Attribute.0.value", valid_603800
  var valid_603801 = formData.getOrDefault("Attribute.1.value")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "Attribute.1.value", valid_603801
  var valid_603802 = formData.getOrDefault("Attribute.1.key")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "Attribute.1.key", valid_603802
  var valid_603803 = formData.getOrDefault("Attribute.2.value")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "Attribute.2.value", valid_603803
  var valid_603804 = formData.getOrDefault("Attribute.2.key")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "Attribute.2.key", valid_603804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_PostSetQueueAttributes_603785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_PostSetQueueAttributes_603785; QueueName: string;
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
  var path_603807 = newJObject()
  var query_603808 = newJObject()
  var formData_603809 = newJObject()
  add(formData_603809, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_603809, "Attribute.0.value", newJString(Attribute0Value))
  add(path_603807, "QueueName", newJString(QueueName))
  add(formData_603809, "Attribute.1.value", newJString(Attribute1Value))
  add(query_603808, "Action", newJString(Action))
  add(formData_603809, "Attribute.1.key", newJString(Attribute1Key))
  add(path_603807, "AccountNumber", newJInt(AccountNumber))
  add(formData_603809, "Attribute.2.value", newJString(Attribute2Value))
  add(query_603808, "Version", newJString(Version))
  add(formData_603809, "Attribute.2.key", newJString(Attribute2Key))
  result = call_603806.call(path_603807, query_603808, nil, formData_603809, nil)

var postSetQueueAttributes* = Call_PostSetQueueAttributes_603785(
    name: "postSetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_PostSetQueueAttributes_603786, base: "/",
    url: url_PostSetQueueAttributes_603787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetQueueAttributes_603761 = ref object of OpenApiRestCall_602450
proc url_GetSetQueueAttributes_603763(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetSetQueueAttributes_603762(path: JsonNode; query: JsonNode;
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
  var valid_603764 = path.getOrDefault("QueueName")
  valid_603764 = validateParameter(valid_603764, JString, required = true,
                                 default = nil)
  if valid_603764 != nil:
    section.add "QueueName", valid_603764
  var valid_603765 = path.getOrDefault("AccountNumber")
  valid_603765 = validateParameter(valid_603765, JInt, required = true, default = nil)
  if valid_603765 != nil:
    section.add "AccountNumber", valid_603765
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
  var valid_603766 = query.getOrDefault("Attribute.2.value")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "Attribute.2.value", valid_603766
  var valid_603767 = query.getOrDefault("Attribute.0.key")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "Attribute.0.key", valid_603767
  var valid_603768 = query.getOrDefault("Attribute.1.value")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "Attribute.1.value", valid_603768
  var valid_603769 = query.getOrDefault("Attribute.1.key")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "Attribute.1.key", valid_603769
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603770 = query.getOrDefault("Action")
  valid_603770 = validateParameter(valid_603770, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_603770 != nil:
    section.add "Action", valid_603770
  var valid_603771 = query.getOrDefault("Attribute.2.key")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "Attribute.2.key", valid_603771
  var valid_603772 = query.getOrDefault("Attribute.0.value")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "Attribute.0.value", valid_603772
  var valid_603773 = query.getOrDefault("Version")
  valid_603773 = validateParameter(valid_603773, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603773 != nil:
    section.add "Version", valid_603773
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
  var valid_603774 = header.getOrDefault("X-Amz-Date")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Date", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Security-Token")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Security-Token", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Content-Sha256", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Algorithm")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Algorithm", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Signature")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Signature", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-SignedHeaders", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Credential")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Credential", valid_603780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603781: Call_GetSetQueueAttributes_603761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_603781.validator(path, query, header, formData, body)
  let scheme = call_603781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603781.url(scheme.get, call_603781.host, call_603781.base,
                         call_603781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603781, url, valid)

proc call*(call_603782: Call_GetSetQueueAttributes_603761; QueueName: string;
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
  var path_603783 = newJObject()
  var query_603784 = newJObject()
  add(query_603784, "Attribute.2.value", newJString(Attribute2Value))
  add(query_603784, "Attribute.0.key", newJString(Attribute0Key))
  add(query_603784, "Attribute.1.value", newJString(Attribute1Value))
  add(path_603783, "QueueName", newJString(QueueName))
  add(query_603784, "Attribute.1.key", newJString(Attribute1Key))
  add(query_603784, "Action", newJString(Action))
  add(query_603784, "Attribute.2.key", newJString(Attribute2Key))
  add(path_603783, "AccountNumber", newJInt(AccountNumber))
  add(query_603784, "Attribute.0.value", newJString(Attribute0Value))
  add(query_603784, "Version", newJString(Version))
  result = call_603782.call(path_603783, query_603784, nil, nil, nil)

var getSetQueueAttributes* = Call_GetSetQueueAttributes_603761(
    name: "getSetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_GetSetQueueAttributes_603762, base: "/",
    url: url_GetSetQueueAttributes_603763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagQueue_603834 = ref object of OpenApiRestCall_602450
proc url_PostTagQueue_603836(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostTagQueue_603835(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603837 = path.getOrDefault("QueueName")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = nil)
  if valid_603837 != nil:
    section.add "QueueName", valid_603837
  var valid_603838 = path.getOrDefault("AccountNumber")
  valid_603838 = validateParameter(valid_603838, JInt, required = true, default = nil)
  if valid_603838 != nil:
    section.add "AccountNumber", valid_603838
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603839 = query.getOrDefault("Action")
  valid_603839 = validateParameter(valid_603839, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_603839 != nil:
    section.add "Action", valid_603839
  var valid_603840 = query.getOrDefault("Version")
  valid_603840 = validateParameter(valid_603840, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603840 != nil:
    section.add "Version", valid_603840
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
  var valid_603841 = header.getOrDefault("X-Amz-Date")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Date", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Security-Token")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Security-Token", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Content-Sha256", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Algorithm")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Algorithm", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Signature")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Signature", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-SignedHeaders", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Credential")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Credential", valid_603847
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.2.value: JString
  ##   Tags.1.value: JString
  ##   Tags.2.key: JString
  ##   Tags.0.value: JString
  section = newJObject()
  var valid_603848 = formData.getOrDefault("Tags.0.key")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "Tags.0.key", valid_603848
  var valid_603849 = formData.getOrDefault("Tags.1.key")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "Tags.1.key", valid_603849
  var valid_603850 = formData.getOrDefault("Tags.2.value")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "Tags.2.value", valid_603850
  var valid_603851 = formData.getOrDefault("Tags.1.value")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "Tags.1.value", valid_603851
  var valid_603852 = formData.getOrDefault("Tags.2.key")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "Tags.2.key", valid_603852
  var valid_603853 = formData.getOrDefault("Tags.0.value")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "Tags.0.value", valid_603853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603854: Call_PostTagQueue_603834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603854.validator(path, query, header, formData, body)
  let scheme = call_603854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603854.url(scheme.get, call_603854.host, call_603854.base,
                         call_603854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603854, url, valid)

proc call*(call_603855: Call_PostTagQueue_603834; QueueName: string;
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
  var path_603856 = newJObject()
  var query_603857 = newJObject()
  var formData_603858 = newJObject()
  add(formData_603858, "Tags.0.key", newJString(Tags0Key))
  add(formData_603858, "Tags.1.key", newJString(Tags1Key))
  add(path_603856, "QueueName", newJString(QueueName))
  add(formData_603858, "Tags.2.value", newJString(Tags2Value))
  add(query_603857, "Action", newJString(Action))
  add(formData_603858, "Tags.1.value", newJString(Tags1Value))
  add(path_603856, "AccountNumber", newJInt(AccountNumber))
  add(formData_603858, "Tags.2.key", newJString(Tags2Key))
  add(query_603857, "Version", newJString(Version))
  add(formData_603858, "Tags.0.value", newJString(Tags0Value))
  result = call_603855.call(path_603856, query_603857, nil, formData_603858, nil)

var postTagQueue* = Call_PostTagQueue_603834(name: "postTagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
    validator: validate_PostTagQueue_603835, base: "/", url: url_PostTagQueue_603836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagQueue_603810 = ref object of OpenApiRestCall_602450
proc url_GetTagQueue_603812(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetTagQueue_603811(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603813 = path.getOrDefault("QueueName")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = nil)
  if valid_603813 != nil:
    section.add "QueueName", valid_603813
  var valid_603814 = path.getOrDefault("AccountNumber")
  valid_603814 = validateParameter(valid_603814, JInt, required = true, default = nil)
  if valid_603814 != nil:
    section.add "AccountNumber", valid_603814
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
  var valid_603815 = query.getOrDefault("Tags.2.value")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "Tags.2.value", valid_603815
  var valid_603816 = query.getOrDefault("Tags.2.key")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "Tags.2.key", valid_603816
  var valid_603817 = query.getOrDefault("Tags.1.value")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "Tags.1.value", valid_603817
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603818 = query.getOrDefault("Action")
  valid_603818 = validateParameter(valid_603818, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_603818 != nil:
    section.add "Action", valid_603818
  var valid_603819 = query.getOrDefault("Tags.0.key")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "Tags.0.key", valid_603819
  var valid_603820 = query.getOrDefault("Tags.1.key")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "Tags.1.key", valid_603820
  var valid_603821 = query.getOrDefault("Tags.0.value")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "Tags.0.value", valid_603821
  var valid_603822 = query.getOrDefault("Version")
  valid_603822 = validateParameter(valid_603822, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603822 != nil:
    section.add "Version", valid_603822
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
  var valid_603823 = header.getOrDefault("X-Amz-Date")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Date", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Security-Token")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Security-Token", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Content-Sha256", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Algorithm")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Algorithm", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Signature")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Signature", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-SignedHeaders", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Credential")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Credential", valid_603829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_GetTagQueue_603810; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_GetTagQueue_603810; QueueName: string;
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
  var path_603832 = newJObject()
  var query_603833 = newJObject()
  add(query_603833, "Tags.2.value", newJString(Tags2Value))
  add(query_603833, "Tags.2.key", newJString(Tags2Key))
  add(query_603833, "Tags.1.value", newJString(Tags1Value))
  add(path_603832, "QueueName", newJString(QueueName))
  add(query_603833, "Action", newJString(Action))
  add(query_603833, "Tags.0.key", newJString(Tags0Key))
  add(path_603832, "AccountNumber", newJInt(AccountNumber))
  add(query_603833, "Tags.1.key", newJString(Tags1Key))
  add(query_603833, "Tags.0.value", newJString(Tags0Value))
  add(query_603833, "Version", newJString(Version))
  result = call_603831.call(path_603832, query_603833, nil, nil, nil)

var getTagQueue* = Call_GetTagQueue_603810(name: "getTagQueue",
                                        meth: HttpMethod.HttpGet,
                                        host: "sqs.amazonaws.com", route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
                                        validator: validate_GetTagQueue_603811,
                                        base: "/", url: url_GetTagQueue_603812,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagQueue_603878 = ref object of OpenApiRestCall_602450
proc url_PostUntagQueue_603880(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PostUntagQueue_603879(path: JsonNode; query: JsonNode;
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
  var valid_603881 = path.getOrDefault("QueueName")
  valid_603881 = validateParameter(valid_603881, JString, required = true,
                                 default = nil)
  if valid_603881 != nil:
    section.add "QueueName", valid_603881
  var valid_603882 = path.getOrDefault("AccountNumber")
  valid_603882 = validateParameter(valid_603882, JInt, required = true, default = nil)
  if valid_603882 != nil:
    section.add "AccountNumber", valid_603882
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603883 = query.getOrDefault("Action")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_603883 != nil:
    section.add "Action", valid_603883
  var valid_603884 = query.getOrDefault("Version")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603884 != nil:
    section.add "Version", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Content-Sha256", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Algorithm")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Algorithm", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Signature")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Signature", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-SignedHeaders", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603892 = formData.getOrDefault("TagKeys")
  valid_603892 = validateParameter(valid_603892, JArray, required = true, default = nil)
  if valid_603892 != nil:
    section.add "TagKeys", valid_603892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_PostUntagQueue_603878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_PostUntagQueue_603878; QueueName: string;
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
  var path_603895 = newJObject()
  var query_603896 = newJObject()
  var formData_603897 = newJObject()
  add(path_603895, "QueueName", newJString(QueueName))
  add(query_603896, "Action", newJString(Action))
  if TagKeys != nil:
    formData_603897.add "TagKeys", TagKeys
  add(path_603895, "AccountNumber", newJInt(AccountNumber))
  add(query_603896, "Version", newJString(Version))
  result = call_603894.call(path_603895, query_603896, nil, formData_603897, nil)

var postUntagQueue* = Call_PostUntagQueue_603878(name: "postUntagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_PostUntagQueue_603879, base: "/", url: url_PostUntagQueue_603880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagQueue_603859 = ref object of OpenApiRestCall_602450
proc url_GetUntagQueue_603861(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetUntagQueue_603860(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603862 = path.getOrDefault("QueueName")
  valid_603862 = validateParameter(valid_603862, JString, required = true,
                                 default = nil)
  if valid_603862 != nil:
    section.add "QueueName", valid_603862
  var valid_603863 = path.getOrDefault("AccountNumber")
  valid_603863 = validateParameter(valid_603863, JInt, required = true, default = nil)
  if valid_603863 != nil:
    section.add "AccountNumber", valid_603863
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603864 = query.getOrDefault("Action")
  valid_603864 = validateParameter(valid_603864, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_603864 != nil:
    section.add "Action", valid_603864
  var valid_603865 = query.getOrDefault("TagKeys")
  valid_603865 = validateParameter(valid_603865, JArray, required = true, default = nil)
  if valid_603865 != nil:
    section.add "TagKeys", valid_603865
  var valid_603866 = query.getOrDefault("Version")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_603866 != nil:
    section.add "Version", valid_603866
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
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Security-Token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Security-Token", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Content-Sha256", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Algorithm")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Algorithm", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Signature")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Signature", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-SignedHeaders", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603874: Call_GetUntagQueue_603859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_603874.validator(path, query, header, formData, body)
  let scheme = call_603874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603874.url(scheme.get, call_603874.host, call_603874.base,
                         call_603874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603874, url, valid)

proc call*(call_603875: Call_GetUntagQueue_603859; QueueName: string;
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
  var path_603876 = newJObject()
  var query_603877 = newJObject()
  add(path_603876, "QueueName", newJString(QueueName))
  add(query_603877, "Action", newJString(Action))
  add(path_603876, "AccountNumber", newJInt(AccountNumber))
  if TagKeys != nil:
    query_603877.add "TagKeys", TagKeys
  add(query_603877, "Version", newJString(Version))
  result = call_603875.call(path_603876, query_603877, nil, nil, nil)

var getUntagQueue* = Call_GetUntagQueue_603859(name: "getUntagQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_GetUntagQueue_603860, base: "/", url: url_GetUntagQueue_603861,
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
